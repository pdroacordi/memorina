class_name ReachAuditTest extends GdUnitTestSuite

## One fixture per finding: unreachable, leads nowhere, redundant route, dead-end pocket, no way back; and doors.

func _audit(grid: ReachGrid) -> ReachReport:
	return ReachAudit.run(grid, ReachFixture.ivo())

# A 22-wide room with a floor at row 11, empty above but for `extra` rows by index.
func _room(extra: Dictionary) -> PackedStringArray:
	var rows := PackedStringArray()
	for y: int in 11:
		rows.append(extra.get(y, "......................"))
	rows.append("######################")
	return rows

func _kinds(report: ReachReport) -> Array:
	return report.findings.map(func(finding: ReachFinding) -> String: return "%s %d,%d %s" % [finding.kind_name(), finding.local.x, finding.local.y, "error" if finding.error else "warning"])

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
	var report := _audit(ReachFixture.grid(_room({8: "SSSS.................."}), Vector2i(10, 10)))
	assert_array(_kinds(report)).contains_exactly(["DEAD_END_POCKET 0,7 warning"])

func test_a_platform_next_to_a_secret_is_fine() -> void:
	var rows := _room({8: "..........====........"})
	var secret := PackedStringArray()
	for y: int in rows.size():
		secret.append("..............k......." if y == 7 else "......................")
	var text := "[room]\norigin = 0, 0\ntileset = legacy\n\n[grid]\n%s\n\n[secret]\n%s\n" % ["\n".join(rows), "\n".join(secret)]
	var parsed := RoomMapParser.parse(text, RoomLegend.load_default(), "fixture.room")
	var grid := ReachGrid.new()
	grid.add_room(&"fixture", parsed.map, Vector2i.ZERO)
	grid.set_start(Vector2i(2, 10))
	assert_array(_kinds(_audit(grid))).is_empty()

func test_a_platform_beside_a_dead_end_pocket_still_leads_nowhere() -> void:
	var report := _audit(ReachFixture.grid(_room({5: "......====............", 8: "SSSS.................."}), Vector2i(10, 10)))
	assert_array(_kinds(report)).contains_exactly_in_any_order(["DEAD_END_POCKET 0,7 warning", "LEADS_NOWHERE 6,4 error"])

func test_a_door_without_a_partner_in_its_region_is_an_error() -> void:
	var grid := ReachGrid.new()
	grid.add_room(&"outside", ReachFixture.map(PackedStringArray(["....E...", "########"]), PackedStringArray(),
		PackedStringArray(["4,0 = {\"link\": \"fixture_door\", \"to_room\": \"inside\"}"])), Vector2i.ZERO, &"village")
	grid.add_room(&"inside", ReachFixture.map(PackedStringArray(["..E.....", "########"]), PackedStringArray(),
		PackedStringArray(["2,0 = {\"link\": \"fixture_door\", \"to_room\": \"outside\"}"])), Vector2i(100, 100), &"woods")
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
	grid.set_start(Vector2i(1, 0))
	var report := _audit(grid)
	assert_array(_kinds(report)).is_empty()
	for tier: PackedByteArray in report.reached:
		assert_array(Array(tier)).contains_exactly([1, 1])
