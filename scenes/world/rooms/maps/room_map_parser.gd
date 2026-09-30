class_name RoomMapParser extends RefCounted

## Turns a room's `.room` text into a RoomMap (docs/maps/README.md). Pure: the
## importer calls it once per file, the tests call it on strings.
##
## A `.room` file has up to four sections:
##
##   [room]
##   origin = -12, -6        ; tile coordinates of the grids' top-left character
##
##   [grid]
##   ....##########          ; ground, ledges and entities: one character per
##                           ; 32 px cell, from the legend
##
##   [water]                 ; optional, the same size as [grid]: water kinds.
##   ..~~~~~.......          ; A layer of its own because water can lie OVER
##                           ; ground (a lake in front of the land) as well as
##                           ; fill a pit.
##
##   [entities]
##   12,8 = {"save_id": "downtown_brute"}   ; grid column,row = JSON params
##
## `;` starts a comment in [room] and [entities] (never in a grid, where every
## character is a cell). Blank lines are ignored everywhere.

const SECTION_ROOM := "room"
const SECTION_GRID := "grid"
const SECTION_WATER := "water"
const SECTION_ENTITIES := "entities"
const COMMENT := ";"

static func parse(text: String, legend: RoomLegend, source: String = "<room>") -> Result:
	var result := Result.new()
	var map := RoomMap.new()
	map.legend = legend
	result.map = map
	for problem: String in legend.problems():
		result.errors.append("legend: %s" % problem)

	var section := ""
	var grid_lines: Array[int] = []
	var water_rows := PackedStringArray()
	var water_lines: Array[int] = []
	var entity_lines: Array[int] = []
	var lines := text.replace("\r", "").split("\n")
	for i: int in lines.size():
		var raw := lines[i]
		var line := raw.strip_edges()
		if line.begins_with("[") and line.ends_with("]"):
			section = line.substr(1, line.length() - 2).strip_edges().to_lower()
			if not section in [SECTION_ROOM, SECTION_GRID, SECTION_WATER, SECTION_ENTITIES]:
				result.errors.append("%s:%d: unknown section [%s]" % [source, i + 1, section])
			continue
		if section == SECTION_GRID or section == SECTION_WATER:
			if line.is_empty():
				continue
			# Every character of a grid row is a cell: leading whitespace would
			# shift the row, so it is an error rather than silently trimmed.
			if raw.length() > 0 and raw[0] in [" ", "\t"]:
				result.errors.append("%s:%d: a grid row may not start with whitespace - use '%s' for an empty cell" % [source, i + 1, RoomLegend.EMPTY])
			if section == SECTION_GRID:
				map.rows.append(line)
				grid_lines.append(i + 1)
			else:
				water_rows.append(line)
				water_lines.append(i + 1)
			continue
		if section == SECTION_ENTITIES:
			if not _entity_line(line).is_empty():
				entity_lines.append(i + 1)
			continue
		line = _uncomment(line)
		if line.is_empty():
			continue
		match section:
			SECTION_ROOM:
				_parse_setting(map, line, i + 1, source, result)
			_:
				result.errors.append("%s:%d: text outside any section" % [source, i + 1])

	if map.rows.is_empty():
		result.errors.append("%s: no [grid]" % source)
		return result
	_read_grid(map, grid_lines, source, result)
	_read_water(map, water_rows, water_lines, source, result)
	for line_number: int in entity_lines:
		_parse_entity(map, _entity_line(lines[line_number - 1].strip_edges()), line_number, source, result)
	_check_entities(map, source, result)
	_resolve_tiles(map)
	return result

## An [entities] line without its comment. A ';' inside the JSON (a string
## value) is not a comment: only one after the object's closing brace is.
static func _entity_line(line: String) -> String:
	if line.begins_with(COMMENT):
		return ""
	var close := line.rfind("}")
	if close < 0:
		return _uncomment(line)
	var tail := line.substr(close + 1)
	var at := tail.find(COMMENT)
	return (line.substr(0, close + 1) + (tail.substr(0, at) if at >= 0 else tail)).strip_edges()

static func _uncomment(line: String) -> String:
	var at := line.find(COMMENT)
	return (line.substr(0, at) if at >= 0 else line).strip_edges()

static func _parse_setting(map: RoomMap, line: String, line_number: int, source: String, result: Result) -> void:
	var parts := line.split("=", false, 1)
	if parts.size() != 2:
		result.errors.append("%s:%d: expected 'key = value'" % [source, line_number])
		return
	var key := parts[0].strip_edges()
	var value := parts[1].strip_edges()
	match key:
		"origin":
			var cell: Variant = _parse_cell(value)
			if cell == null:
				result.errors.append("%s:%d: origin must be 'x, y'" % [source, line_number])
			else:
				map.origin = cell
		_:
			result.errors.append("%s:%d: unknown room setting '%s'" % [source, line_number, key])

static func _read_grid(map: RoomMap, grid_lines: Array[int], source: String, result: Result) -> void:
	var width := 0
	for row: String in map.rows:
		width = maxi(width, row.length())
	map.size = Vector2i(width, map.rows.size())
	map.ground.resize(width * map.size.y)
	map.platform.resize(width * map.size.y)
	for y: int in map.size.y:
		var row := map.rows[y]
		if row.length() < width:
			result.warnings.append("%s:%d: row is %d wide, padded with '%s' to %d" % [source, grid_lines[y], row.length(), RoomLegend.EMPTY, width])
			row = row.rpad(width, RoomLegend.EMPTY)
			map.rows[y] = row
		for x: int in width:
			var symbol := row[x]
			if symbol == RoomLegend.EMPTY:
				continue
			var entry := map.legend.entry(symbol)
			if entry == null:
				result.errors.append("%s:%d:%d: unknown character '%s'" % [source, grid_lines[y], x + 1, symbol])
				continue
			var cell := map.origin + Vector2i(x, y)
			var index := y * width + x
			match entry.kind:
				RoomLegendEntry.Kind.GROUND:
					map.ground[index] = entry.ground
				RoomLegendEntry.Kind.PLATFORM:
					map.ground[index] = entry.ground
					map.platform[index] = 1
				RoomLegendEntry.Kind.WATER:
					result.errors.append("%s:%d:%d: water '%s' belongs in [water], not [grid]" % [source, grid_lines[y], x + 1, symbol])
				RoomLegendEntry.Kind.ENTITY:
					map.entities.append({"symbol": symbol, "cell": cell, "params": {}})

static func _read_water(map: RoomMap, rows: PackedStringArray, lines: Array[int], source: String, result: Result) -> void:
	if rows.is_empty():
		return
	if rows.size() != map.size.y:
		result.errors.append("%s:%d: [water] has %d rows, [grid] has %d" % [source, lines[0], rows.size(), map.size.y])
		return
	for y: int in rows.size():
		var row := rows[y]
		if row.length() > map.size.x:
			result.errors.append("%s:%d: [water] row is wider than [grid] (%d > %d)" % [source, lines[y], row.length(), map.size.x])
			continue
		for x: int in row.length():
			var symbol := row[x]
			if symbol == RoomLegend.EMPTY:
				continue
			var entry := map.legend.entry(symbol)
			if entry == null or entry.kind != RoomLegendEntry.Kind.WATER:
				result.errors.append("%s:%d:%d: '%s' is not a kind of water" % [source, lines[y], x + 1, symbol])
				continue
			if not map.water.has(symbol):
				map.water[symbol] = PackedVector2Array()
			var cells: PackedVector2Array = map.water[symbol]
			cells.append(Vector2(map.origin + Vector2i(x, y)))
			map.water[symbol] = cells

static func _parse_entity(map: RoomMap, line: String, line_number: int, source: String, result: Result) -> void:
	var parts := line.split("=", false, 1)
	var local: Variant = _parse_cell(parts[0].strip_edges()) if parts.size() == 2 else null
	if local == null:
		result.errors.append("%s:%d: expected 'column,row = {json}'" % [source, line_number])
		return
	var json := JSON.new()
	if json.parse(parts[1].strip_edges()) != OK or not (json.data is Dictionary):
		result.errors.append("%s:%d: params must be a JSON object (%s)" % [source, line_number, json.get_error_message()])
		return
	var cell: Vector2i = map.origin + local
	for placed: Dictionary in map.entities:
		if placed.cell == cell:
			placed.params = json.data
			return
	result.errors.append("%s:%d: no entity at column %d, row %d" % [source, line_number, local.x, local.y])

static func _check_entities(map: RoomMap, source: String, result: Result) -> void:
	var ids := {}
	for placed: Dictionary in map.entities:
		var id: String = str(placed.params.get("id", ""))
		if id.is_empty():
			continue
		if ids.has(id):
			result.errors.append("%s: id '%s' is used by two entities" % [source, id])
		ids[id] = true

static func _parse_cell(text: String) -> Variant:
	var parts := text.split(",")
	if parts.size() != 2 or not parts[0].strip_edges().is_valid_int() or not parts[1].strip_edges().is_valid_int():
		return null
	return Vector2i(parts[0].strip_edges().to_int(), parts[1].strip_edges().to_int())

## Every ground cell gets its tile now, so the room never autotiles at load.
## Cells past the map's left, right and bottom edges count as solid: the ground
## runs on beyond the room instead of showing a rounded rim at the edge of the
## screen. Past the TOP edge is open sky, so a ledge on the top row still has
## its grass.
static func _resolve_tiles(map: RoomMap) -> void:
	map.tiles.resize(map.size.x * map.size.y)
	map.tiles.fill(RoomMap.NO_TILE)
	for y: int in map.size.y:
		for x: int in map.size.x:
			var cell := map.origin + Vector2i(x, y)
			var ground := map.ground_at(cell)
			if ground == Enums.Ground.NONE:
				continue
			var index := y * map.size.x + x
			if map.is_platform(cell):
				var tile := GroundAutotile.platform_tile(map.is_platform(cell + Vector2i.LEFT), map.is_platform(cell + Vector2i.RIGHT))
				map.tiles[index] = RoomMap.pack_tile(GroundAutotile.in_material(tile, ground), GroundAutotile.ONE_WAY_ALTERNATIVE)
				continue
			var mask := 0
			var neighbours := {
				GroundAutotile.N: Vector2i.UP, GroundAutotile.E: Vector2i.RIGHT,
				GroundAutotile.S: Vector2i.DOWN, GroundAutotile.W: Vector2i.LEFT,
				GroundAutotile.NE: Vector2i(1, -1), GroundAutotile.SE: Vector2i(1, 1),
				GroundAutotile.SW: Vector2i(-1, 1), GroundAutotile.NW: Vector2i(-1, -1),
			}
			for bit: int in neighbours:
				var other: Vector2i = cell + neighbours[bit]
				var beyond := not map.contains(other) and other.y >= map.origin.y
				if beyond or map.is_solid(other):
					mask |= bit
			map.tiles[index] = RoomMap.pack_tile(GroundAutotile.in_material(GroundAutotile.tile_for(mask), ground), 0)

class Result:
	var map: RoomMap
	var errors := PackedStringArray()
	var warnings := PackedStringArray()

	func ok() -> bool:
		return errors.is_empty()
