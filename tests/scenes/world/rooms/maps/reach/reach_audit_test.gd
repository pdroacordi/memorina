class_name ReachAuditTest extends GdUnitTestSuite

## One fixture per finding: unreachable, leads nowhere, redundant route, dead-end pocket, no way back; doors, wall
## shelves and the roots a ledge grows.

func _audit(grid: ReachGrid) -> ReachReport:
	return ReachAudit.run(grid, ReachFixture.ivo())

# A 22-wide room with a floor at row 11, empty above but for `extra` rows by index.
func _room(extra: Dictionary) -> PackedStringArray:
	var rows := PackedStringArray()
	for y: int in 11:
		rows.append(extra.get(y, "......................"))
	rows.append("######################")
	return rows

# Every finding but OPEN_EDGE: most fixtures leave a room's sides open; _edge_kinds() checks those.
func _kinds(report: ReachReport) -> Array:
	return _named(report.findings.filter(func(finding: ReachFinding) -> bool: return finding.kind != ReachFinding.Kind.OPEN_EDGE))

func _edge_kinds(report: ReachReport) -> Array:
	return _named(report.findings.filter(func(finding: ReachFinding) -> bool: return finding.kind == ReachFinding.Kind.OPEN_EDGE))

# Sky bands over every room of a hand-built grid, as if each first row were open.
func _add_sky(grid: ReachGrid) -> void:
	var maps: Array[RoomMap] = []
	for i: int in grid.room_count():
		var rect := grid.room_rect(i)
		var map := RoomMap.new()
		map.size = rect.size
		map.ground.resize(rect.size.x * rect.size.y)
		map.platform.resize(rect.size.x * rect.size.y)
		maps.append(map)
	ReachWorldLoader.add_sky(grid, maps)

func _named(findings: Array) -> Array:
	return findings.map(func(finding: ReachFinding) -> String: return "%s %d,%d %s" % [finding.kind_name(), finding.local.x, finding.local.y, "error" if finding.error else "warning"])

func test_a_flat_floor_has_no_findings() -> void:
	assert_array(_kinds(_audit(ReachFixture.grid(_room({}), Vector2i(2, 10))))).is_empty()

func test_a_platform_out_of_reach_is_an_error() -> void:
	var report := _audit(ReachFixture.grid(_room({1: "..........====........"}), Vector2i(2, 10)))
	assert_array(_kinds(report)).contains_exactly(["UNREACHABLE 10,0 error"])

func test_ground_out_of_reach_is_a_warning() -> void:
	var report := _audit(ReachFixture.grid(_room({1: "SSSS.................."}), Vector2i(8, 10)))
	assert_array(_kinds(report)).contains_exactly(["UNREACHABLE 0,0 warning"])

func test_a_platform_that_holds_nothing_leads_nowhere() -> void:
	var report := _audit(ReachFixture.grid(_room({8: "..........====........"}), Vector2i(2, 10)))
	assert_array(_kinds(report)).contains_exactly(["LEADS_NOWHERE 10,7 error"])

func test_a_platform_holding_content_is_fine() -> void:
	var grid := ReachFixture.grid(_room({7: "...........R..........", 8: "..........====........"}), Vector2i(2, 10),
		PackedStringArray(), PackedStringArray(["11,7 = {\"bench_id\": \"fixture_bench\"}"]))
	assert_array(_kinds(_audit(grid))).is_empty()

func test_ground_that_holds_nothing_is_a_dead_end_pocket() -> void:
	var report := _audit(ReachFixture.grid(_terrace(), Vector2i(10, 10)))
	assert_array(_kinds(report)).contains_exactly(["DEAD_END_POCKET 0,7 warning"])

# A raised terrace, solid down to the floor.
func _terrace() -> PackedStringArray:
	return _room({8: "SSSS..................", 9: "SSSS..................", 10: "SSSS.................."})

# The wall of the room's west edge, with `extra` rows by index.
func _walled(extra: Dictionary) -> PackedStringArray:
	var rows := PackedStringArray()
	for y: int in 11:
		rows.append(extra.get(y, "S....................."))
	rows.append("######################")
	return rows

func test_a_wall_shelf_that_holds_nothing_leads_nowhere() -> void:
	var report := _audit(ReachFixture.grid(_walled({8: "SSSS.................."}), Vector2i(10, 10)))
	assert_array(_kinds(report)).contains_exactly(["LEADS_NOWHERE 1,7 error"])

func test_a_wall_shelf_on_the_way_to_content_is_fine() -> void:
	var grid := ReachFixture.grid(_walled({4: "S......R..............", 5: "S.....====............", 8: "SSSS.................."}), Vector2i(10, 10),
		PackedStringArray(), PackedStringArray(["7,4 = {\"bench_id\": \"fixture_bench\"}"]))
	assert_array(_kinds(_audit(grid))).is_empty()

func test_a_roof_that_holds_nothing_is_a_dead_end_pocket() -> void:
	var report := _audit(ReachFixture.grid(_room({8: "..........^^^^........"}), Vector2i(2, 10)))
	assert_array(_kinds(report)).contains_exactly(["DEAD_END_POCKET 10,7 warning"])

# A block on a floor one cell thick: thin underneath, but its ends step down onto the floor, so it is no shelf.
func test_a_block_on_a_thin_floor_is_a_step_not_a_shelf() -> void:
	var rows := PackedStringArray()
	for y: int in 7:
		rows.append("S....................S")
	rows.append_array(["S.........SS.........S", "SSSSSSSSSSSSSSSSSSSSSS", "SSSSSSSSSS..SSSSSSSSSS", "SSSSSSSSSSSSSSSSSSSSSS"])
	var report := _audit(ReachFixture.grid(rows, Vector2i(2, 7)))
	assert_array(_kinds(report)).contains_exactly(["DEAD_END_POCKET 10,6 warning"])

func test_a_platform_next_to_a_secret_is_fine() -> void:
	var rows := _room({8: "..........====........"})
	var secret := PackedStringArray()
	for y: int in rows.size():
		secret.append("..............k......." if y == 7 else "......................")
	var text := "[room]\norigin = 0, 0\ntileset = legacy\n\n[grid]\n%s\n\n[secret]\n%s\n" % ["\n".join(rows), "\n".join(secret)]
	var parsed := RoomMapParser.parse(text, RoomLegend.load_default(), "fixture.room")
	var grid := ReachGrid.new()
	grid.add_room(&"fixture", parsed.map, Vector2i.ZERO)
	_add_sky(grid)
	grid.set_start(Vector2i(2, 10))
	assert_array(_kinds(_audit(grid))).is_empty()

func test_a_platform_beside_a_dead_end_pocket_still_leads_nowhere() -> void:
	var rows := _terrace()
	rows[5] = "......====............"
	var report := _audit(ReachFixture.grid(rows, Vector2i(10, 10)))
	assert_array(_kinds(report)).contains_exactly_in_any_order(["DEAD_END_POCKET 0,7 warning", "LEADS_NOWHERE 6,4 error"])

func test_a_door_without_a_partner_in_its_region_is_an_error() -> void:
	var grid := ReachGrid.new()
	grid.add_room(&"outside", ReachFixture.map(PackedStringArray(["....E...", "########"]), PackedStringArray(),
		PackedStringArray(["4,0 = {\"link\": \"fixture_door\", \"to_room\": \"inside\"}"])), Vector2i.ZERO, &"village")
	grid.add_room(&"inside", ReachFixture.map(PackedStringArray(["..E.....", "########"]), PackedStringArray(),
		PackedStringArray(["2,0 = {\"link\": \"fixture_door\", \"to_room\": \"outside\"}"])), Vector2i(100, 100), &"woods")
	_add_sky(grid)
	grid.set_start(Vector2i(1, 0))
	assert_array(_kinds(_audit(grid))).contains(["UNPAIRED_DOOR 4,0 error", "UNPAIRED_DOOR 2,0 error"])

# Two stepping stones, each enough alone to reach a bench too high for one jump: only the first is flagged.
func test_of_two_parallel_routes_only_one_leads_nowhere() -> void:
	var rows := PackedStringArray()
	for y: int in 13:
		match y:
			4:
				rows.append("..............R...............")
			5:
				rows.append("..........==========..........")
			9:
				rows.append("...===..................===...")
			_:
				rows.append("..............................")
	rows.append("##############################")
	var grid := ReachFixture.grid(rows, Vector2i(14, 12), PackedStringArray(), PackedStringArray(["14,4 = {\"bench_id\": \"fixture_bench\"}"]))
	assert_array(_kinds(_audit(grid))).contains_exactly(["LEADS_NOWHERE 3,8 error", "REDUNDANT_ROUTE 24,8 warning"])

func test_a_pit_too_deep_to_jump_out_of_has_no_way_back() -> void:
	var rows := PackedStringArray()
	for y: int in 7:
		rows.append("................")
	rows.append("#####...########")
	for y: int in 9:
		rows.append("SSSSS...SSSSSSSS")
	rows.append("SSSSSSSSSSSSSSSS")
	var report := _audit(ReachFixture.grid(rows, Vector2i(1, 6)))
	assert_array(_kinds(report)).contains(["NO_WAY_BACK 5,16 error"])

func test_doors_join_their_rooms_both_ways() -> void:
	var grid := ReachGrid.new()
	grid.add_room(&"outside", ReachFixture.map(PackedStringArray(["....E...", "########"]), PackedStringArray(),
		PackedStringArray(["4,0 = {\"link\": \"fixture_door\", \"to_room\": \"inside\"}"])), Vector2i.ZERO)
	grid.add_room(&"inside", ReachFixture.map(PackedStringArray(["..E.....", "########"]), PackedStringArray(),
		PackedStringArray(["2,0 = {\"link\": \"fixture_door\", \"to_room\": \"outside\"}"])), Vector2i(100, 100))
	_add_sky(grid)
	grid.set_start(Vector2i(1, 0))
	var report := _audit(grid)
	assert_array(_kinds(report)).is_empty()
	assert_int(report.reached.size()).is_equal(ReachAudit.TIERS.size())
	for tier: PackedByteArray in report.reached:
		assert_array(Array(tier)).contains_exactly([1, 1])

# A ledge too high for any jump, and the same ledge at the head of a helix stair (role STAIR).
func _high_ledge() -> PackedStringArray:
	return _room({2: "..................SSSS"})

func test_a_ledge_too_high_to_jump_to_is_unreached() -> void:
	assert_array(_kinds(_audit(ReachFixture.grid(_high_ledge(), Vector2i(2, 10))))).contains(["UNREACHABLE 18,1 warning"])

func test_a_stair_joins_its_foot_and_head_both_ways() -> void:
	var grid := ReachFixture.grid(_high_ledge(), Vector2i(2, 10))
	grid.add_stair(Vector2i(6, 10), Vector2i(18, 1))
	var report := _audit(grid)
	assert_array(_kinds(report)).is_empty()
	for tier: PackedByteArray in report.reached:
		assert_array(Array(tier)).contains_exactly([1, 1])

func test_a_stair_out_of_a_pit_is_a_way_back() -> void:
	var rows := PackedStringArray()
	for y: int in 7:
		rows.append("................")
	rows.append("#####...########")
	for y: int in 9:
		rows.append("SSSSS...SSSSSSSS")
	rows.append("SSSSSSSSSSSSSSSS")
	var grid := ReachFixture.grid(rows, Vector2i(1, 6))
	grid.add_stair(Vector2i(6, 16), Vector2i(9, 6))
	assert_array(_kinds(_audit(grid)).filter(func(kind: String) -> bool: return kind.begins_with("NO_WAY_BACK"))).is_empty()

# An earth block whose root pillar from the floor is the only base-kit way up to a bench on a stone ledge; `stone`
# adds a stepping stone, a second way.
func _rooted(stone: bool) -> ReachGrid:
	var rows := PackedStringArray()
	for y: int in 13:
		match y:
			3:
				rows.append("...##.........................")
			4:
				rows.append("...##.........R...............")
			5:
				rows.append("..........SSSSSSSSSS..........")
			9:
				rows.append("........................SSS..." if stone else "..............................")
			_:
				rows.append("..............................")
	rows.append("##############################")
	return ReachFixture.rooted_grid(rows, Vector2i(26, 12), PackedStringArray(["14,4 = {\"bench_id\": \"fixture_bench\"}"]))

func test_a_ledge_whose_roots_lead_to_content_is_fine() -> void:
	assert_array(_kinds(_audit(_rooted(false)))).is_empty()

# Removing the block removes its pillar too, so the stepping stone is the last way up.
func test_removing_a_ledge_removes_the_roots_it_grows() -> void:
	assert_array(_kinds(_audit(_rooted(true)))).contains_exactly(["LEADS_NOWHERE 3,2 error", "REDUNDANT_ROUTE 24,8 warning"])

# A 4-wide earth shaft, the only way up to a bench, with a 2-cell earth shelf out of its east wall at row 12. The
# shelf's pillars join the shaft's roots in one transit node; the shaft stays when the shelf goes.
func test_a_shelf_in_a_needed_root_shaft_still_leads_nowhere() -> void:
	var rows := PackedStringArray(["SSSSSSSSSSSSSSSSSSSS", "S..................S", "S..................S", "S...........R......S"])
	for y: int in range(4, 21):
		rows.append("SSSS#..###SSSSSSSSSS" if y == 12 else "SSSS#....#SSSSSSSSSS")
	rows.append_array(["SSSS######SSSSSSSSSS", "SSSSSSSSSSSSSSSSSSSS"])
	var grid := ReachFixture.rooted_grid(rows, Vector2i(6, 20), PackedStringArray(["12,3 = {\"bench_id\": \"fixture_bench\"}"]))
	assert_array(_kinds(_audit(grid))).contains_exactly(["LEADS_NOWHERE 7,11 error"])

# The support of the surface holding feet cell `cell`, -1 if none does.
func _support_at(report: ReachReport, cell: Vector2i) -> int:
	for surface: ReachReport.Surface in report.surfaces:
		if surface.cells.has(cell):
			return surface.support
	return -1

func test_a_shelf_is_six_cells_at_most() -> void:
	var six := _audit(ReachFixture.grid(_walled({8: "SSSSSSS..............."}), Vector2i(10, 10)))
	assert_int(_support_at(six, Vector2i(1, 7))).is_equal(ReachReport.Support.SHELF)
	var seven := _audit(ReachFixture.grid(_walled({8: "SSSSSSSS.............."}), Vector2i(10, 10)))
	assert_int(_support_at(seven, Vector2i(1, 7))).is_equal(ReachReport.Support.GROUND)
	assert_array(_kinds(seven)).contains_exactly(["DEAD_END_POCKET 1,7 warning"])

func test_a_slab_two_rows_thick_is_a_shelf_and_three_is_ground() -> void:
	var two := _audit(ReachFixture.grid(_walled({8: "SSSS..................", 9: "SSSS.................."}), Vector2i(10, 10)))
	assert_int(_support_at(two, Vector2i(1, 7))).is_equal(ReachReport.Support.SHELF)
	var three := _audit(ReachFixture.grid(_walled({6: "SSSS..................", 7: "SSSS..................", 8: "SSSS.................."}), Vector2i(10, 10)))
	assert_int(_support_at(three, Vector2i(1, 5))).is_equal(ReachReport.Support.GROUND)

# A shelf hanging off a wall down from the room's top, running east to the room's edge or stopping one cell short.
func _edge_shelf(to_edge: bool) -> PackedStringArray:
	var rows := PackedStringArray()
	for y: int in 11:
		if y == 8:
			rows.append(".................SSSSS" if to_edge else ".................SSSS.")
		else:
			rows.append(".................S...." if y < 8 else "......................")
	rows.append("######################")
	return rows

func test_a_cell_beside_a_shelf_outside_every_room_is_no_drop() -> void:
	assert_int(_support_at(_audit(ReachFixture.grid(_edge_shelf(false), Vector2i(2, 10))), Vector2i(18, 7))).is_equal(ReachReport.Support.SHELF)
	assert_int(_support_at(_audit(ReachFixture.grid(_edge_shelf(true), Vector2i(2, 10))), Vector2i(18, 7))).is_equal(ReachReport.Support.GROUND)

# A wall ledge on the room's last row: nothing is below it, which counts as solid, so it is no shelf.
func test_outside_every_room_under_a_slab_counts_as_solid() -> void:
	var report := _audit(ReachFixture.grid(PackedStringArray(["S.......", "S.......", "SSSS...."]), Vector2i(1, 1)))
	assert_int(_support_at(report, Vector2i(1, 1))).is_equal(ReachReport.Support.GROUND)

# A floor a song makes in an open first row stands Ivo in the sky band over it, outside every room: reached or not.
func test_a_floor_in_the_first_row_under_the_sky_stands_outside_the_room() -> void:
	var grid := ReachFixture.grid(_room({}), Vector2i(2, 10))
	grid.add_cells([Vector2i(10, 0), Vector2i(11, 0)] as Array[Vector2i], ReachGrid.SONG_FLOOR)
	assert_array(_kinds(_audit(grid))).contains(["OUTSIDE_ROOM 10,-1 error"])

# bugs/outside-room-misses-a-song-floor-above-a-rooms-first-row: a band cell keeps its grid flags.
func test_a_song_floor_rounded_into_the_sky_band_stands_outside_the_room() -> void:
	var grid := ReachFixture.grid(_room({}), Vector2i(2, 10))
	grid.add_cells([Vector2i(10, -2)] as Array[Vector2i], ReachGrid.SONG_FLOOR)
	assert_array(_kinds(_audit(grid))).contains(["OUTSIDE_ROOM 10,-3 error"])

# A long seesaw in row 1 under an open top: its raised end's floor rounds into row -1, a sky-band cell.
func test_a_seesaw_raised_over_an_open_top_stands_outside_the_room() -> void:
	var grid := ReachFixture.moving_grid(_room({1: "..........T..........."}), Vector2i(2, 10),
		PackedStringArray(["10,1 = {\"length\": 320.0}"]))
	var outside := _kinds(_audit(grid)).filter(func(kind: String) -> bool: return kind.begins_with("OUTSIDE_ROOM") and kind.contains(",-2 "))
	assert_array(outside).is_not_empty()

# A flag in no room and no band is a mover or current authored past its room.
func test_a_flag_beside_a_room_is_outside_it() -> void:
	var grid := ReachFixture.grid(_room({}), Vector2i(2, 10))
	grid.add_cells([Vector2i(-3, 5)] as Array[Vector2i], ReachGrid.SONG_FLOOR)
	assert_array(_kinds(_audit(grid))).contains(["OUTSIDE_ROOM -3,5 error"])

func test_a_closed_first_row_has_no_sky_to_stand_in() -> void:
	var grid := ReachFixture.grid(_room({0: "SSSSSSSSSSSSSSSSSSSSSS"}), Vector2i(2, 10))
	grid.add_cells([Vector2i(10, 1)] as Array[Vector2i], ReachGrid.SONG_FLOOR)
	assert_array(_kinds(_audit(grid)).filter(func(kind: String) -> bool: return kind.begins_with("OUTSIDE_ROOM"))).is_empty()

# A walled room with a gap in its east wall at rows 9-10, over a floor whose lake runs off the bottom at cols 0-5.
func _gapped() -> PackedStringArray:
	var rows := PackedStringArray()
	for y: int in 11:
		rows.append("S....................S" if y < 9 else "S.....................")
	rows.append_array(["SSSSSSSSSSSSSSSSSSSSSS", "......SSSSSSSSSSSSSSSS"])
	return rows

func _gapped_lake() -> PackedStringArray:
	var water := PackedStringArray()
	for y: int in 13:
		water.append("wwwwww................" if y == 12 else "......................")
	return water

# The lake on the bottom edge is no opening: Ivo sinks in it before he meets the wall.
func test_an_opening_onto_the_void_is_an_open_edge() -> void:
	var report := _audit(ReachFixture.grid(_gapped(), Vector2i(2, 10), _gapped_lake()))
	assert_array(_edge_kinds(report)).contains_exactly(["OPEN_EDGE 21,9 error"])

func test_an_opening_onto_a_neighbour_is_a_seam() -> void:
	var grid := ReachGrid.new()
	var near := ReachFixture.map(_gapped(), _gapped_lake())
	var beside := ReachFixture.map(PackedStringArray(["S...", "S...", "S...", "S...", "S...", "S...", "S...", "S...", "S...", "....", "....", "SSSS", "SSSS"]))
	grid.add_room(&"near", near, Vector2i.ZERO)
	grid.add_room(&"beside", beside, Vector2i(22, 0))
	ReachWorldLoader.add_sky(grid, [near, beside] as Array[RoomMap])
	grid.set_start(Vector2i(2, 10))
	var seam := _edge_kinds(_audit(grid)).filter(func(kind: String) -> bool: return kind.contains(" 21,"))
	assert_array(seam).is_empty()
