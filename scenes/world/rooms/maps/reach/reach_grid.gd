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
## Each CONTENT, GATE and BENCH entity's cell, world cells.
var anchors: Array[Vector2i] = []
## Each BENCH entity's cell, world cells.
var benches: Array[Vector2i] = []
## The room each guardian the world places fights in, by Enums.Guardian (ReachWorldLoader reads the rooms' contents).
var guardians: Dictionary[int, StringName] = {}
## Each door: {"cell": Vector2i, "link": StringName, "region": StringName, "room": StringName, "need": PackedInt32Array}
## (ReachKit facts its `requires` packs); a kit's grid adds "open": whether the kit holds the need.
var doors: Array[Dictionary] = []
## Each stair's two feet cells, world cells, joined both ways.
var stairs: Array[Array] = []
## Each root span added, so a removed ledge also removes the roots it grows.
var roots: Array[Root] = []
## The sky over open tops, world cells (RoomEdges.band_cells): the only space outside the rooms Ivo enters.
var bands: Array[Rect2i] = []

# Every flag at once, the songs' union (what ReachAudit.run reads).
var _cells: Dictionary[Vector2i, int] = {}
# The flags no song, skill or fact gates.
var _base: Dictionary[Vector2i, int] = {}
# Keyed by need: flags a kit gets only while it holds the need (a song's floor), and flags it gets until it holds it (a
# barrier, water without Redoma). The union holds the first (but ice on resting water under a reach) and never the second.
var _opens: Dictionary[String, Layer] = {}
var _closes: Dictionary[String, Layer] = {}
# Cells flagged before any room covered them, so possibly in no room.
var _loose: Dictionary[Vector2i, bool] = {}
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
			# A mover of a room added earlier may already have flagged this cell.
			_cells[offset + cell] = _cells.get(offset + cell, 0) | flags
			_base[offset + cell] = _base.get(offset + cell, 0) | flags
	_add_water(map, offset)
	for placed: Dictionary in map.entities:
		var entry := map.legend.entry(placed.symbol)
		var world: Vector2i = offset + placed.cell
		match entry.reach_role:
			RoomLegendEntry.ReachRole.CONTENT, RoomLegendEntry.ReachRole.GATE:
				anchors.append(world)
			RoomLegendEntry.ReachRole.BENCH:
				anchors.append(world)
				benches.append(world)
			RoomLegendEntry.ReachRole.DOOR:
				var need := PackedInt32Array()
				var requires := str(placed.params.get("requires", ""))
				if not requires.is_empty():
					need.append(ReachKit.of(load(requires) as SaveFact))
				doors.append({"cell": world, "link": StringName(str(placed.params.get("link", ""))), "region": region, "room": id, "need": need})

## Root spans of a room added at `cell_origin` (map cells): a bridge is a floor across its gap, a shaft's gap and a
## pillar are climbed. Each needs Enraizar; a bridge wider than `dry_bridge_cells` also needs Chuva (RootGrower.reaches;
## -1: every bridge crosses dry).
func add_roots(spans: Array[RootSpanFinder.Span], map: RoomMap, cell_origin: Vector2i, dry_bridge_cells: int = -1) -> void:
	var offset := cell_origin - map.origin
	for span: RootSpanFinder.Span in spans:
		var root := Root.new()
		var need := PackedInt32Array([ReachKit.song(Enums.Song.ROOT)])
		match span.kind:
			RootSpanFinder.Kind.BRIDGE:
				root.ends.assign([offset + span.a, offset + span.b])
				for x: int in range(span.a.x + 1, span.b.x):
					root.cells.append(offset + Vector2i(x, span.a.y))
				if dry_bridge_cells >= 0 and span.gap() > dry_bridge_cells:
					need.append(ReachKit.song(Enums.Song.RAIN))
				_open_all(root.cells, SONG_FLOOR, need)
			RootSpanFinder.Kind.SHAFT:
				for y: int in range(span.rows.x, span.rows.y + 1):
					root.ends.append_array([offset + Vector2i(span.a.x, y), offset + Vector2i(span.b.x, y)])
					for x: int in range(span.a.x + 1, span.b.x):
						root.cells.append(offset + Vector2i(x, y))
				_open_all(root.cells, CLIMB, need)
			RootSpanFinder.Kind.PILLAR:
				root.ends.assign([offset + span.a, offset + span.b])
				for y: int in range(span.rows.x + 1, span.rows.y):
					root.cells.append(offset + Vector2i(span.a.x, y))
				_open_all(root.cells, CLIMB, need)
		roots.append(root)

## Marks world `cells` with `flag` (SONG_FLOOR from a mover, CURRENT or CURRENT_EXIT from a current), for a kit only
## while it holds `need` (ReachKit facts; empty: always).
func add_cells(cells: Array[Vector2i], flag: int, need: PackedInt32Array = PackedInt32Array()) -> void:
	_open_all(cells, flag, need)

## Marks world `cells` solid for a kit until it holds `need` (a barrier, a gate, a leaf curtain); never in the union.
func add_walls(cells: Array[Vector2i], need: PackedInt32Array) -> void:
	_close_all(cells, SOLID, need)

## The grid `kit` meets: ungated flags, each floor whose need it holds, each wall and hazard whose need it lacks, and
## each door marked "open" when the kit holds its need. Rooms, anchors, guardians, stairs, roots and bands are shared.
func for_kit(kit: ReachKit) -> ReachGrid:
	var view := ReachGrid.new()
	view.start = start
	view.anchors = anchors
	view.benches = benches
	view.guardians = guardians
	view.stairs = stairs
	view.roots = roots
	view.bands = bands
	view._room_ids = _room_ids
	view._room_rects = _room_rects
	view._bounds = _bounds
	view._loose = _loose
	for door: Dictionary in doors:
		var copy := door.duplicate()
		copy["open"] = kit.holds(door.need)
		view.doors.append(copy)
	view._cells = _base.duplicate()
	for layer: Layer in _opens.values():
		if kit.holds(layer.need):
			layer.apply(view._cells)
	for layer: Layer in _closes.values():
		if not kit.holds(layer.need):
			layer.apply(view._cells)
	return view

## The sky bands over the rooms' open tops, from RoomEdges.bands.
func add_bands(cells: Array[Rect2i]) -> void:
	bands.append_array(cells)

## A stair (role STAIR) from world feet cell `foot` to `head`, ridden both ways.
func add_stair(foot: Vector2i, head: Vector2i) -> void:
	stairs.append([foot, head])

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

## Whether `cell` lies in a sky band.
func in_band(cell: Vector2i) -> bool:
	for band: Rect2i in bands:
		if band.has_point(cell):
			return true
	return false

## Flagged cells in no room and no sky band: a mover, current or root span authored past its room.
func stray_cells() -> Array[Vector2i]:
	var stray: Array[Vector2i] = []
	for cell: Vector2i in _loose:
		if _cells.get(cell, 0) != 0 and room_at(cell) < 0 and not in_band(cell):
			stray.append(cell)
	return stray

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
		var rained: PackedVector2Array = map.reach.get(host, PackedVector2Array())
		var shelled: PackedVector2Array = map.shell_reach.get(host, PackedVector2Array())
		for cell: Vector2i in body:
			if role == RoomLegendEntry.ReachRole.HAZARD:
				_flag(offset + cell, HAZARD)
				continue
			if standing.has(Vector2(cell)):
				_flag(offset + cell, WATER)
				# Ivo does not swim: only a Redoma shell lets him in (systems/water).
				_close(offset + cell, HAZARD, PackedInt32Array([ReachKit.song(Enums.Song.BELL_JAR)]))
			if role != RoomLegendEntry.ReachRole.ICE:
				continue
			var frozen := PackedInt32Array([ReachKit.song(Enums.Song.FREEZE)])
			if not body.has(cell + Vector2i.UP):
				# The top of the highest water: Congelar, plus the song that raised it there.
				var need := frozen.duplicate()
				if rained.has(Vector2(cell)):
					need.append(ReachKit.song(Enums.Song.RAIN))
				if shelled.has(Vector2(cell)):
					need.append(ReachKit.song(Enums.Song.BELL_JAR))
				_open(offset + cell, SONG_FLOOR, need)
			elif standing.has(Vector2(cell)) and not standing.has(Vector2(cell + Vector2i.UP)):
				# Congelar alone freezes the water where it rests, under a reach. Kit only: the union keeps one ice top per
				# column, so a ledge level with the resting water is still judged (lake_high_wall's ladder, 15,17).
				_layer(_opens, frozen).add(offset + cell, SONG_FLOOR)

func _flag(cell: Vector2i, flag: int) -> void:
	if not _cells.has(cell):
		_loose[cell] = true
	_cells[cell] = _cells.get(cell, 0) | flag
	_base[cell] = _base.get(cell, 0) | flag

# A flag in the union that a kit gets only while it holds `need`.
func _open(cell: Vector2i, flag: int, need: PackedInt32Array) -> void:
	if need.is_empty():
		_flag(cell, flag)
		return
	if not _cells.has(cell):
		_loose[cell] = true
	_cells[cell] = _cells.get(cell, 0) | flag
	_layer(_opens, need).add(cell, flag)

# A flag never in the union that a kit gets until it holds `need`.
func _close(cell: Vector2i, flag: int, need: PackedInt32Array) -> void:
	_layer(_closes, need).add(cell, flag)

func _open_all(cells: Array[Vector2i], flag: int, need: PackedInt32Array) -> void:
	for cell: Vector2i in cells:
		_open(cell, flag, need)

func _close_all(cells: Array[Vector2i], flag: int, need: PackedInt32Array) -> void:
	for cell: Vector2i in cells:
		_close(cell, flag, need)

func _layer(layers: Dictionary[String, Layer], need: PackedInt32Array) -> Layer:
	var sorted := need.duplicate()
	sorted.sort()
	var key := str(sorted)
	if not layers.has(key):
		layers[key] = Layer.new(sorted)
	return layers[key]

## Flags that come and go together with one need.
class Layer:
	var need: PackedInt32Array
	var cells: Dictionary[Vector2i, int] = {}

	func _init(p_need: PackedInt32Array) -> void:
		need = p_need

	func add(cell: Vector2i, flag: int) -> void:
		cells[cell] = cells.get(cell, 0) | flag

	func apply(to: Dictionary[Vector2i, int]) -> void:
		for cell: Vector2i in cells:
			to[cell] = to.get(cell, 0) | cells[cell]

## One root span in world cells.
class Root:
	## The earth cells it grows from (a shaft: both walls on every row).
	var ends: Array[Vector2i] = []
	## The cells it bridges or climbs.
	var cells: Array[Vector2i] = []
