class_name ReachGrid extends RefCounted

## Every room stitched into one grid of 32 px cells, each flagged for Ivo's movement (architecture/room-reachability-audit).

const SOLID := 1
const ONE_WAY := 2
## A floor only a song makes: ice, a root bridge, a mover anywhere along its way.
const SONG_FLOOR := 4
const HAZARD := 8
## A root rung or pillar Ivo holds.
const CLIMB := 16
## Inside an air current that carries Ivo along its direction.
const CURRENT := 32
const SECRET := 64
## A one-way roof drawn by a facade: a building's top, classed as ground.
const ROOF := 128
## Standing water a Redoma shell holds back: passable, and only so with the song.
const WATER := 256
## A current's downwind edge, where it sets Ivo down.
const CURRENT_EXIT := 512

## Px per cell.
const CELL := RoomMap.CELL_PX

## Where a new game starts: Ivo's feet cell.
var start := Vector2i.ZERO
## Each CONTENT entity's cell, world cells.
var anchors: Array[Vector2i] = []
## Each door: {"cell": Vector2i, "link": StringName, "region": StringName, "room": StringName}.
var doors: Array[Dictionary] = []

var _cells: Dictionary[Vector2i, int] = {}
var _room_ids: Array[StringName] = []
var _room_rects: Array[Rect2i] = []
var _bounds := Rect2i()

## Adds `map` with its `map.origin` cell at world cell `cell_origin`; doors pair only within one `region`.
func add_room(id: StringName, map: RoomMap, cell_origin: Vector2i, region: StringName = &"") -> void:
	var rect := Rect2i(cell_origin, map.size)
	_room_ids.append(id)
	_room_rects.append(rect)
	_bounds = rect if _room_rects.size() == 1 else _bounds.merge(rect)
	var offset := cell_origin - map.origin
	for y: int in map.size.y:
		for x: int in map.size.x:
			var cell := map.origin + Vector2i(x, y)
			var flags := 0
			if map.is_solid(cell):
				flags |= SOLID
			elif map.is_platform(cell):
				var entry := map.legend.entry(map.rows[y][x])
				flags |= (ROOF | ONE_WAY) if entry != null and entry.kind == RoomLegendEntry.Kind.ROOF else ONE_WAY
			if map.secret_at(cell) > 0:
				flags |= SECRET
			_cells[offset + cell] = flags
	_add_water(map, offset)
	for placed: Dictionary in map.entities:
		var entry := map.legend.entry(placed.symbol)
		var world: Vector2i = offset + placed.cell
		match entry.reach_role:
			RoomLegendEntry.ReachRole.CONTENT:
				anchors.append(world)
			RoomLegendEntry.ReachRole.DOOR:
				doors.append({"cell": world, "link": StringName(str(placed.params.get("link", ""))), "region": region, "room": id})

## Root spans of a room added at `cell_origin` (map cells): a bridge is a floor across its gap, a shaft's gap and a
## pillar are climbed.
func add_roots(spans: Array[RootSpanFinder.Span], map: RoomMap, cell_origin: Vector2i) -> void:
	var offset := cell_origin - map.origin
	for span: RootSpanFinder.Span in spans:
		match span.kind:
			RootSpanFinder.Kind.BRIDGE:
				for x: int in range(span.a.x + 1, span.b.x):
					_flag(offset + Vector2i(x, span.a.y), SONG_FLOOR)
			RootSpanFinder.Kind.SHAFT:
				for y: int in range(span.rows.x, span.rows.y + 1):
					for x: int in range(span.a.x + 1, span.b.x):
						_flag(offset + Vector2i(x, y), CLIMB)
			RootSpanFinder.Kind.PILLAR:
				for y: int in range(span.rows.x + 1, span.rows.y):
					_flag(offset + Vector2i(span.a.x, y), CLIMB)

## Marks world `cells` with `flag` (SONG_FLOOR from a mover, CURRENT or CURRENT_EXIT from a current).
func add_cells(cells: Array[Vector2i], flag: int) -> void:
	for cell: Vector2i in cells:
		_flag(cell, flag)

func set_start(cell: Vector2i) -> void:
	start = cell

func flags(cell: Vector2i) -> int:
	return _cells.get(cell, 0)

## The rectangle, in world cells, holding every room.
func bounds() -> Rect2i:
	return _bounds

func room_count() -> int:
	return _room_ids.size()

func room_id(index: int) -> StringName:
	return _room_ids[index]

func room_rect(index: int) -> Rect2i:
	return _room_rects[index]

## The index of the room holding `cell`, -1 outside every room.
func room_at(cell: Vector2i) -> int:
	for i: int in _room_rects.size():
		if _room_rects[i].has_point(cell):
			return i
	return -1

func _add_water(map: RoomMap, offset: Vector2i) -> void:
	var hosts: Array[String] = []
	for kind: Dictionary in [map.water, map.reach, map.shell_reach]:
		for symbol: String in kind:
			if not symbol in hosts:
				hosts.append(symbol)
	for host: String in hosts:
		var role := map.legend.entry(host).reach_role
		var body: Dictionary[Vector2i, bool] = {}
		for kind: Dictionary in [map.water, map.reach, map.shell_reach]:
			for point: Vector2 in kind.get(host, PackedVector2Array()):
				body[Vector2i(point)] = true
		var standing: PackedVector2Array = map.water.get(host, PackedVector2Array())
		for cell: Vector2i in body:
			if role == RoomLegendEntry.ReachRole.HAZARD:
				_flag(offset + cell, HAZARD)
				continue
			if standing.has(Vector2(cell)):
				_flag(offset + cell, WATER)
			if role == RoomLegendEntry.ReachRole.ICE and not body.has(cell + Vector2i.UP):
				_flag(offset + cell, SONG_FLOOR)

func _flag(cell: Vector2i, flag: int) -> void:
	_cells[cell] = _cells.get(cell, 0) | flag
