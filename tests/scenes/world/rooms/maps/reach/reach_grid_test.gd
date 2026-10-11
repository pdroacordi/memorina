class_name ReachGridTest extends GdUnitTestSuite

## Checks what each map character becomes in the stitched grid.

func test_ground_ledges_and_roofs_are_flagged() -> void:
	var grid := ReachFixture.grid(PackedStringArray(["#=^.", "SSSS"]), Vector2i.ZERO)
	assert_int(grid.flags(Vector2i(0, 0))).is_equal(ReachGrid.SOLID)
	assert_int(grid.flags(Vector2i(1, 0))).is_equal(ReachGrid.ONE_WAY)
	assert_int(grid.flags(Vector2i(2, 0))).is_equal(ReachGrid.ONE_WAY | ReachGrid.ROOF)
	assert_int(grid.flags(Vector2i(3, 0))).is_equal(0)

func test_outside_every_room_is_air() -> void:
	var grid := ReachFixture.grid(PackedStringArray(["####"]), Vector2i.ZERO)
	assert_int(grid.flags(Vector2i(-1, 0))).is_equal(0)
	assert_int(grid.room_at(Vector2i(-1, 0))).is_equal(-1)

func test_a_room_is_placed_at_its_cell_origin() -> void:
	var grid := ReachGrid.new()
	grid.add_room(&"far", ReachFixture.map(PackedStringArray(["..", "#."])), Vector2i(10, 20))
	assert_int(grid.flags(Vector2i(10, 21))).is_equal(ReachGrid.SOLID)
	assert_that(grid.bounds()).is_equal(Rect2i(10, 20, 2, 2))
	assert_str(String(grid.room_id(grid.room_at(Vector2i(11, 21))))).is_equal("far")

func test_a_lake_is_a_hazard() -> void:
	var grid := ReachFixture.grid(PackedStringArray(["....", "####"]), Vector2i.ZERO, PackedStringArray(["www.", "...."]))
	assert_int(grid.flags(Vector2i(1, 0)) & ReachGrid.HAZARD).is_not_equal(0)

func test_a_freezable_pool_is_water_with_ice_on_its_top() -> void:
	var grid := ReachFixture.grid(PackedStringArray(["#..#", "#..#", "####"]), Vector2i.ZERO, PackedStringArray([".ff.", ".ff.", "...."]))
	assert_int(grid.flags(Vector2i(1, 0))).is_equal(ReachGrid.WATER | ReachGrid.SONG_FLOOR)
	assert_int(grid.flags(Vector2i(1, 1))).is_equal(ReachGrid.WATER)

func test_a_plain_pool_never_freezes() -> void:
	var grid := ReachFixture.grid(PackedStringArray(["#..#", "####"]), Vector2i.ZERO, PackedStringArray([".~~.", "...."]))
	assert_int(grid.flags(Vector2i(1, 0))).is_equal(ReachGrid.WATER)

func test_a_rain_reach_freezes_at_its_top() -> void:
	var grid := ReachFixture.grid(PackedStringArray(["#..#", "#..#", "####"]), Vector2i.ZERO, PackedStringArray([".rr.", ".ff.", "...."]))
	assert_int(grid.flags(Vector2i(1, 0))).is_equal(ReachGrid.SONG_FLOOR)
	assert_int(grid.flags(Vector2i(1, 1))).is_equal(ReachGrid.WATER)

func test_content_and_doors_come_from_the_legend_roles() -> void:
	var grid := ReachFixture.grid(PackedStringArray(["R.E.B", "#####"]), Vector2i.ZERO, PackedStringArray(), PackedStringArray([
		"0,0 = {\"bench_id\": \"fixture_bench\"}",
		"2,0 = {\"link\": \"fixture_door\", \"to_room\": \"fixture\"}",
		"4,0 = {\"save_id\": \"fixture_brute\"}",
	]))
	assert_array(grid.anchors).contains_exactly([Vector2i(0, 0)])
	assert_int(grid.doors.size()).is_equal(1)
	assert_that(grid.doors[0].cell).is_equal(Vector2i(2, 0))
	assert_str(String(grid.doors[0].link)).is_equal("fixture_door")

func test_root_spans_become_floors_and_climbs() -> void:
	var map := ReachFixture.map(PackedStringArray([
		"#....#",
		"#....#",
		"#....#",
		"######",
	]))
	var grid := ReachGrid.new()
	grid.add_room(&"fixture", map, Vector2i.ZERO)
	grid.add_roots(RootSpanFinder.find(map, 14, 4, 2, 8), map, Vector2i.ZERO)
	assert_int(grid.flags(Vector2i(2, 1)) & ReachGrid.CLIMB).is_not_equal(0)

func test_a_door_remembers_its_room_and_region() -> void:
	var grid := ReachGrid.new()
	grid.add_room(&"inn", ReachFixture.map(PackedStringArray(["E.", "##"]), PackedStringArray(),
		PackedStringArray(["0,0 = {\"link\": \"inn_door\", \"to_room\": \"town\"}"])), Vector2i.ZERO, &"orchards")
	assert_str(String(grid.doors[0].region)).is_equal("orchards")
	assert_str(String(grid.doors[0].room)).is_equal("inn")

func test_no_board_mark_is_a_legend_symbol() -> void:
	var legend := RoomLegend.load_default()
	for mark: String in ReachFinding.MARKS.values():
		assert_object(legend.entry(mark)).is_null()
		assert_str(mark).is_not_equal(RoomLegend.EMPTY)
	assert_int(ReachFinding.MARKS.size()).is_equal(ReachFinding.Kind.size())
