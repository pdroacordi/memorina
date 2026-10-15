class_name RootSpanFinderTest extends GdUnitTestSuite

## Checks that root spans connect earth surfaces and exclude stone.

func _map(rows: Array[String]) -> RoomMap:
	var text := "[room]\norigin = 0, 0\ntileset = legacy\n\n[grid]\n" + "\n".join(rows) + "\n"
	var result := RoomMapParser.parse(text, RoomLegend.load_default())
	assert(result.ok(), str(result.errors))
	return result.map

func _of(spans: Array[RootSpanFinder.Span], kind: RootSpanFinder.Kind) -> Array[RootSpanFinder.Span]:
	var found: Array[RootSpanFinder.Span] = []
	for span: RootSpanFinder.Span in spans:
		if span.kind == kind:
			found.append(span)
	return found

func _find(map: RoomMap) -> Array[RootSpanFinder.Span]:
	return RootSpanFinder.find(map, 8, 4, 2, 8)

func test_two_earth_banks_make_a_bridge_at_their_tops() -> void:
	var map := _map([
		"..........",
		"###....###",
		"###....###",
	] as Array[String])
	var bridges := _of(_find(map), RootSpanFinder.Kind.BRIDGE)
	assert_int(bridges.size()).is_equal(1)
	assert_vector(bridges[0].a).is_equal(Vector2i(2, 1))
	assert_vector(bridges[0].b).is_equal(Vector2i(7, 1))
	assert_int(bridges[0].gap()).is_equal(4)

func test_stone_never_roots() -> void:
	var map := _map([
		"..........",
		"###....SSS",
		"###....SSS",
	] as Array[String])
	assert_int(_of(_find(map), RootSpanFinder.Kind.BRIDGE).size()).is_equal(0)

func test_a_gap_too_wide_has_no_bridge() -> void:
	var map := _map([
		"................",
		"##...........###",
	] as Array[String])
	assert_int(_of(_find(map), RootSpanFinder.Kind.BRIDGE).size()).is_equal(0)

func test_a_bank_is_not_a_wall() -> void:
	# The right side rises above the left: its cell at the bank's row has
	# earth above, so it is a wall face, not a bank top.
	var map := _map([
		".......###",
		"###....###",
	] as Array[String])
	assert_int(_of(_find(map), RootSpanFinder.Kind.BRIDGE).size()).is_equal(0)

func test_facing_walls_make_a_shaft() -> void:
	var map := _map([
		"#..#",
		"#..#",
		"#..#",
		"####",
	] as Array[String])
	var shafts := _of(_find(map), RootSpanFinder.Kind.SHAFT)
	assert_int(shafts.size()).is_equal(1)
	assert_vector(shafts[0].rows).is_equal(Vector2i(0, 2))

func test_a_floor_under_a_ceiling_makes_pillars() -> void:
	var map := _map([
		"###",
		"...",
		"...",
		"###",
	] as Array[String])
	var pillars := _of(_find(map), RootSpanFinder.Kind.PILLAR)
	assert_int(pillars.size()).is_equal(3)
	assert_int(pillars[0].gap()).is_equal(2)

func test_each_span_lists_the_air_cells_it_crosses() -> void:
	var bridge := RootSpanFinder.Span.new(RootSpanFinder.Kind.BRIDGE, Vector2i(2, 1), Vector2i(5, 1), Vector2i(1, 1))
	assert_array(bridge.cells()).contains_exactly([Vector2i(3, 1), Vector2i(4, 1)])
	var pillar := RootSpanFinder.Span.new(RootSpanFinder.Kind.PILLAR, Vector2i(1, 3), Vector2i(1, 0), Vector2i(0, 3))
	assert_array(pillar.cells()).contains_exactly([Vector2i(1, 1), Vector2i(1, 2)])
	var shaft := RootSpanFinder.Span.new(RootSpanFinder.Kind.SHAFT, Vector2i(0, 2), Vector2i(2, 2), Vector2i(2, 3))
	assert_array(shaft.cells()).contains_exactly([Vector2i(1, 2), Vector2i(1, 3)])

func test_a_span_over_a_blocked_cell_is_dropped() -> void:
	var map := _map([
		"..........",
		"###....###",
		"###....###",
	] as Array[String])
	var spans := _of(_find(map), RootSpanFinder.Kind.BRIDGE)
	var blocked: Dictionary[Vector2i, bool] = {Vector2i(5, 1): true}
	assert_array(RootSpanFinder.clear_of(spans, blocked)).is_empty()
	assert_array(RootSpanFinder.clear_of(spans, {} as Dictionary[Vector2i, bool])).has_size(1)

## bugs/enraizar-grows-a-root-bridge-over-the-closed-street-grate: the closed grate is solid to roots, the open hole is not.
func test_the_closed_street_grate_holds_no_root_bridge_and_the_open_one_does() -> void:
	var map := load("res://scenes/world/rooms/home_village/contents/village_gate_east.room") as RoomMap
	var spans := RootSpanFinder.find(map, 14, 4, 2, 8)
	var grate := (load("res://scenes/world/interactables/fact_barrier/fact_grate.tscn") as PackedScene).instantiate() as FactBarrier
	grate.requires = load("res://resources/save_facts/guardian_restored_summer.tres")
	var at := Vector2(29 * RoomMap.CELL_PX + RoomMap.CELL_PX * 0.5, 10 * RoomMap.CELL_PX)
	var closed: Dictionary[Vector2i, bool] = {}
	for cell: Vector2i in grate.reach_wall_cells(map, at):
		closed[cell] = true
	var data := PlayerData.new()
	assert_bool(grate.is_open_for(data)).is_false()
	assert_bool(_has_bridge(RootSpanFinder.clear_of(spans, closed), Vector2i(28, 9), Vector2i(33, 9))).is_false()
	data.restored_guardians[Enums.Guardian.SUMMER] = true
	assert_bool(grate.is_open_for(data)).is_true()
	assert_bool(_has_bridge(RootSpanFinder.clear_of(spans, {} as Dictionary[Vector2i, bool]), Vector2i(28, 9), Vector2i(33, 9))).is_true()
	grate.free()

func _has_bridge(spans: Array[RootSpanFinder.Span], a: Vector2i, b: Vector2i) -> bool:
	for span: RootSpanFinder.Span in spans:
		if span.kind == RootSpanFinder.Kind.BRIDGE and span.a == a and span.b == b:
			return true
	return false