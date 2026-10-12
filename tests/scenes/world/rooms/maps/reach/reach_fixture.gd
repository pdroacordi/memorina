class_name ReachFixture extends RefCounted

## Builds ReachGrids from `.room` grid rows for the reach suites, and Ivo's lattice once.

static var _ivo: ReachLattice

## Ivo's real lattice, built once: instancing ivo.tscn is the slow part.
static func ivo() -> ReachLattice:
	if _ivo == null:
		_ivo = ReachWorldLoader.ivo_lattice()
	return _ivo

## A RoomMap from `rows`, with optional `[water]` rows and `[entities]` lines.
static func map(rows: PackedStringArray, water: PackedStringArray = PackedStringArray(), entities: PackedStringArray = PackedStringArray()) -> RoomMap:
	var text := "[room]\norigin = 0, 0\ntileset = legacy\n\n[grid]\n%s\n" % "\n".join(rows)
	if not water.is_empty():
		text += "\n[water]\n%s\n" % "\n".join(water)
	if not entities.is_empty():
		text += "\n[entities]\n%s\n" % "\n".join(entities)
	var parsed := RoomMapParser.parse(text, RoomLegend.load_default(), "fixture.room")
	assert(parsed.ok(), "\n".join(parsed.errors))
	return parsed.map

## A one-room grid from `rows`, with Ivo starting with his feet in `start`.
static func grid(rows: PackedStringArray, start: Vector2i, water: PackedStringArray = PackedStringArray(), entities: PackedStringArray = PackedStringArray()) -> ReachGrid:
	var built := ReachGrid.new()
	built.add_room(&"fixture", map(rows, water, entities), Vector2i.ZERO)
	built.set_start(start)
	return built

## grid() with every root span Enraizar grows at RootGrower's wet reach (bridge 14, shaft 4 wide and 2 rows, pillar 8).
static func rooted_grid(rows: PackedStringArray, start: Vector2i, entities: PackedStringArray = PackedStringArray()) -> ReachGrid:
	var built := ReachGrid.new()
	var room_map := map(rows, PackedStringArray(), entities)
	built.add_room(&"fixture", room_map, Vector2i.ZERO)
	built.add_roots(RootSpanFinder.find(room_map, 14, 4, 2, 8), room_map, Vector2i.ZERO)
	built.set_start(start)
	return built

## Every cell reached from `from` over any number of jumps and falls in `tier`.
static func closure(grid: ReachGrid, from: Vector2i, tier: ReachLattice.Tier) -> Dictionary[Vector2i, bool]:
	var reached: Dictionary[Vector2i, bool] = {from: true}
	var queue: Array[Vector2i] = [from]
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_back()
		for landing: Vector2i in ivo().landings(grid, [cell] as Array[Vector2i], tier):
			if not reached.has(landing):
				reached[landing] = true
				queue.append(landing)
	return reached
