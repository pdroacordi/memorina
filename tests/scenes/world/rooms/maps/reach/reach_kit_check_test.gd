class_name ReachKitCheckTest extends GdUnitTestSuite

## The kit check on small fixtures: a one-way drop traps only a kit that cannot climb back, and gates, water, roots and
## sealed doors open only for the kit holding their fact (architecture/room-reachability-audit, TECH-08).

const OWNS_MEMORINA := "res://resources/save_facts/owns_memorina.tres"

func _milestone(id: StringName, skills: Array[Enums.PlayerSkill] = [], songs: Array[Enums.Song] = [], items: Array[Enums.PlayerItem] = [], room: StringName = &"") -> ReachMilestone:
	var milestone := ReachMilestone.new()
	milestone.id = id
	milestone.room = room
	milestone.skills = skills
	milestone.songs = songs
	milestone.items = items
	return milestone

func _kit(id: StringName, milestones: Array[ReachMilestone]) -> ReachKit:
	var kit := ReachKit.new()
	kit.id = id
	kit.milestones = milestones
	return kit

func _base() -> ReachKit:
	return _kit(&"base", [])

func _with(skills: Array[Enums.PlayerSkill] = [], songs: Array[Enums.Song] = [], items: Array[Enums.PlayerItem] = []) -> ReachKit:
	return _kit(&"kit", [_milestone(&"gift", skills, songs, items)])

func _check(grid: ReachGrid, kit: ReachKit) -> ReachReport:
	return ReachAudit.run_kit(grid.for_kit(kit), ReachFixture.ivo(), kit)

func _traps(report: ReachReport) -> Array:
	return report.findings.map(func(finding: ReachFinding) -> String: return "%s %d,%d" % [finding.kind_name(), finding.local.x, finding.local.y])

# A floor at row 7 with a 3-cell hole into a pit whose floor is 6 rows lower: out of a single jump's reach (4 rows), in
# a double jump's (8). `ceiling` closes rows 0-3, so a 3-row corridor runs over the floor. Ivo starts at 1,6.
func _pit(ceiling: bool = false, bottom: String = "SSSSS...SSSSSSSS") -> PackedStringArray:
	var rows := PackedStringArray()
	for y: int in 7:
		rows.append("SSSSSSSSSSSSSSSS" if ceiling and y < 4 else "................")
	rows.append("#####...########")
	for y: int in 4:
		rows.append("SSSSS...SSSSSSSS")
	rows.append(bottom)
	rows.append("SSSSSSSSSSSSSSSS")
	return rows

func test_a_drop_with_no_way_back_traps_the_base_kit() -> void:
	var report := _check(ReachFixture.grid(_pit(), Vector2i(1, 6)), _base())
	assert_array(_traps(report)).contains_exactly(["KIT_TRAP 5,12"])
	assert_str(String(report.findings[0].kit)).is_equal("base")
	assert_int(report.pockets.size()).is_equal(1)
	assert_bool(report.pockets[0].entrances.is_empty()).is_false()

func test_a_kit_that_jumps_twice_climbs_back_out() -> void:
	assert_array(_traps(_check(ReachFixture.grid(_pit(), Vector2i(1, 6)), _with([Enums.PlayerSkill.DOUBLE_JUMP])))).is_empty()

func test_a_kit_that_climbs_walls_climbs_back_out() -> void:
	assert_array(_traps(_check(ReachFixture.grid(_pit(), Vector2i(1, 6)), _with([Enums.PlayerSkill.WALL_CLIMB])))).is_empty()

# The bench at the pit's bottom saves there, so a death respawns Ivo inside: still no way back.
func test_a_bench_in_a_pocket_does_not_make_it_safe() -> void:
	var grid := ReachFixture.grid(_pit(false, "SSSSS.R.SSSSSSSS"), Vector2i(1, 6), PackedStringArray(), PackedStringArray(["6,12 = {\"bench_id\": \"fixture_bench\"}"]))
	var report := _check(grid, _base())
	assert_array(_traps(report)).contains_exactly(["KIT_TRAP 5,12"])
	assert_bool(report.pockets[0].bench).is_true()

# A barred gate filling the corridor before the hole (design 04 section 2, "ter a Memorina").
func _barred() -> ReachGrid:
	var rows := _pit(true)
	rows[6] = "...X............"
	return ReachFixture.moving_grid(rows, Vector2i(1, 6), PackedStringArray(["3,6 = {\"requires\": \"%s\"}" % OWNS_MEMORINA]))

func test_a_barrier_holds_back_a_kit_without_its_fact() -> void:
	var report := _check(_barred(), _base())
	assert_array(_traps(report)).is_empty()
	assert_int(Array(report.reach).count(1)).is_equal(1)

func test_a_barrier_opens_for_the_kit_holding_its_fact() -> void:
	assert_array(_traps(_check(_barred(), _with([], [], [Enums.PlayerItem.MEMORINA])))).contains_exactly(["KIT_TRAP 5,12"])

func test_the_union_assumes_every_barrier_open() -> void:
	var grid := _barred()
	assert_int(grid.flags(Vector2i(3, 6)) & ReachGrid.SOLID).is_equal(0)
	assert_int(grid.for_kit(_base()).flags(Vector2i(3, 6)) & ReachGrid.SOLID).is_equal(ReachGrid.SOLID)

# woods_deep's shape: a two-row tunnel over a pool, then the hole into the pit. Without a shell the pool is a hazard
# and the tunnel leaves no room to jump it.
func _flooded() -> ReachGrid:
	var rows := PackedStringArray()
	for y: int in 5:
		rows.append("SSSSSSSSSSSSSSSSSSSS")
	rows.append("S..................S")
	rows.append("S..................S")
	rows.append("SSSS.......SS...SSSS")
	rows.append("SSSS.......SS...SSSS")
	for y: int in 3:
		rows.append("SSSSSSSSSSSSS...SSSS")
	rows.append("SSSSSSSSSSSSS...SSSS")
	rows.append("SSSSSSSSSSSSSSSSSSSS")
	var water := PackedStringArray()
	for y: int in rows.size():
		water.append("....~~~~~~~........." if y in [7, 8] else "....................")
	return ReachFixture.grid(rows, Vector2i(1, 6), water)

func test_water_turns_back_a_kit_without_redoma() -> void:
	assert_array(_traps(_check(_flooded(), _base()))).is_empty()

func test_redoma_takes_a_kit_through_the_water_and_down_the_hole() -> void:
	assert_array(_traps(_check(_flooded(), _with([], [Enums.Song.BELL_JAR])))).contains_exactly(["KIT_TRAP 13,12"])

func test_a_root_bridge_needs_enraizar_and_a_wide_one_chuva() -> void:
	var grid := ReachGrid.new()
	# Gaps of 13 cells (over RootGrower's dry 10) and 5 between earth tops.
	var map := ReachFixture.map(PackedStringArray([
		"#.............#.....#",
		"#####################",
	]))
	grid.add_room(&"fixture", map, Vector2i.ZERO)
	grid.add_roots(RootSpanFinder.find(map, 14, 4, 2, 8), map, Vector2i.ZERO, 10)
	var wide := Vector2i(7, 0)
	var narrow := Vector2i(17, 0)
	assert_int(grid.flags(wide) & ReachGrid.SONG_FLOOR).is_equal(ReachGrid.SONG_FLOOR)
	assert_int(grid.for_kit(_base()).flags(narrow) & ReachGrid.SONG_FLOOR).is_equal(0)
	var root := grid.for_kit(_with([], [Enums.Song.ROOT]))
	assert_int(root.flags(narrow) & ReachGrid.SONG_FLOOR).is_equal(ReachGrid.SONG_FLOOR)
	assert_int(root.flags(wide) & ReachGrid.SONG_FLOOR).is_equal(0)
	assert_int(grid.for_kit(_with([], [Enums.Song.ROOT, Enums.Song.RAIN])).flags(wide) & ReachGrid.SONG_FLOOR).is_equal(ReachGrid.SONG_FLOOR)

func test_a_sealed_door_joins_nothing_for_a_kit_without_its_fact() -> void:
	var grid := ReachGrid.new()
	var outside := ReachFixture.map(PackedStringArray(["....E...", "########"]), PackedStringArray(),
		PackedStringArray(["4,0 = {\"link\": \"fixture_door\", \"to_room\": \"inside\", \"requires\": \"%s\"}" % OWNS_MEMORINA]))
	var inside := ReachFixture.map(PackedStringArray(["..E.....", "########"]), PackedStringArray(),
		PackedStringArray(["2,0 = {\"link\": \"fixture_door\", \"to_room\": \"outside\"}"]))
	grid.add_room(&"outside", outside, Vector2i.ZERO)
	grid.add_room(&"inside", inside, Vector2i(100, 100))
	ReachWorldLoader.add_sky(grid, [outside, inside] as Array[RoomMap])
	grid.set_start(Vector2i(1, 0))
	assert_array(_check(grid, _base()).rooms).contains_exactly([&"outside"])
	assert_array(_check(grid, _with([], [], [Enums.PlayerItem.MEMORINA])).rooms).contains_exactly_in_any_order([&"outside", &"inside"])

# bugs/the-kit-check-drops-a-door-sealed-on-one-side-so-a-one-way-door-trap-is-never-flagged: the outside door opens,
# the inside one needs the Memorina, and the inside room has no other way out (trial_hatch's shape).
func _one_way_door() -> ReachGrid:
	var grid := ReachGrid.new()
	var outside := ReachFixture.map(PackedStringArray(["....E...", "########"]), PackedStringArray(),
		PackedStringArray(["4,0 = {\"link\": \"fixture_door\", \"to_room\": \"inside\"}"]))
	var inside := ReachFixture.map(PackedStringArray(["SSSSSSSS", "S......S", "S..E...S", "SSSSSSSS"]), PackedStringArray(),
		PackedStringArray(["3,2 = {\"link\": \"fixture_door\", \"to_room\": \"outside\", \"requires\": \"%s\"}" % OWNS_MEMORINA]))
	grid.add_room(&"outside", outside, Vector2i.ZERO)
	grid.add_room(&"inside", inside, Vector2i(100, 100))
	ReachWorldLoader.add_sky(grid, [outside, inside] as Array[RoomMap])
	grid.set_start(Vector2i(1, 0))
	return grid

func test_a_door_open_only_inward_traps_a_kit_without_its_fact() -> void:
	var report := _check(_one_way_door(), _base())
	assert_array(report.rooms).contains_exactly_in_any_order([&"outside", &"inside"])
	assert_int(report.pockets.size()).is_equal(1)
	assert_array(report.pockets[0].rooms).contains_exactly([&"inside"])

func test_a_door_open_both_ways_for_the_kit_holding_its_fact_traps_nothing() -> void:
	assert_array(_traps(_check(_one_way_door(), _with([], [], [Enums.PlayerItem.MEMORINA])))).is_empty()

# The pit is its own room below: the arena of a milestone that gives the double jump and restores the Bloom Guardian.
func _arena_kits(room: StringName) -> ReachKits:
	var kits := ReachKits.new()
	var gift := _milestone(&"guardian", [Enums.PlayerSkill.DOUBLE_JUMP], [], [], room)
	gift.restored_guardians = [Enums.Guardian.BLOOM] as Array[Enums.Guardian]
	kits.kits = [_kit(&"before", []), _kit(&"after", [gift])] as Array[ReachKit]
	return kits

# `guardian_room`: where the world places the Bloom Guardian; empty for nowhere.
func _two_rooms(guardian_room: StringName = &"arena") -> ReachGrid:
	var rows := _pit()
	var grid := ReachGrid.new()
	var upper := ReachFixture.map(rows.slice(0, 8))
	var arena := ReachFixture.map(rows.slice(8))
	grid.add_room(&"upper", upper, Vector2i.ZERO)
	grid.add_room(&"arena", arena, Vector2i(0, 8))
	ReachWorldLoader.add_sky(grid, [upper, arena] as Array[RoomMap])
	grid.set_start(Vector2i(1, 6))
	if not guardian_room.is_empty():
		grid.guardians[Enums.Guardian.BLOOM] = guardian_room
	return grid

func test_a_milestone_room_the_next_kit_leaves_is_a_way_out() -> void:
	var reports := ReachKitCheck.run(_two_rooms(), ReachFixture.ivo(), _arena_kits(&"arena"))
	assert_array(_traps(reports[0])).is_empty()
	assert_array(reports[0].exits).contains_exactly([&"arena"])
	assert_array(_traps(reports[1])).is_empty()

func test_a_pocket_holding_no_milestone_room_stays_a_trap() -> void:
	var reports := ReachKitCheck.run(_two_rooms(&"elsewhere"), ReachFixture.ivo(), _arena_kits(&"elsewhere"))
	assert_array(_traps(reports[0])).contains_exactly(["KIT_TRAP 5,4"])
	assert_array(reports[0].pockets[0].rooms).contains_exactly([&"arena"])

# bugs/the-kit-check-counts-a-guardian-arena-as-an-exit-before-the-guardian-exists.
func test_an_arena_without_its_guardian_is_no_way_out() -> void:
	var reports := ReachKitCheck.run(_two_rooms(&""), ReachFixture.ivo(), _arena_kits(&"arena"))
	assert_array(_traps(reports[0])).contains_exactly(["KIT_TRAP 5,4"])
	assert_array(reports[0].exits).is_empty()

func test_a_milestone_without_a_guardian_is_never_given() -> void:
	var grid := _two_rooms()
	assert_bool(ReachKitCheck.given(grid, _milestone(&"memorina", [], [], [Enums.PlayerItem.MEMORINA], &"arena"))).is_false()

# bugs/a-fact-barrier-without-requires-is-open-to-every-kit-in-the-kit-check: it never opens in the game.
func test_a_barrier_without_requires_stays_shut_for_every_kit() -> void:
	var barrier := auto_free(load("res://scenes/world/interactables/fact_barrier/fact_barrier.tscn").instantiate()) as FactBarrier
	var need := ReachKit.opened_by(barrier.reach_needs())
	var songs: Array[Enums.Song] = []
	songs.assign(Enums.Song.values())
	var everything := _with([Enums.PlayerSkill.DOUBLE_JUMP, Enums.PlayerSkill.WALL_CLIMB], songs, [Enums.PlayerItem.MEMORINA])
	assert_bool(everything.holds(need)).is_false()
	assert_bool(_base().holds(need)).is_false()

# bugs/kit-check-ice-forms-only-on-the-highest-water-any-song-can-raise: `f` water rests at rows 2-3, a Redoma shell
# raises it to row 1.
func test_congelar_alone_freezes_the_water_where_it_rests() -> void:
	var grid := ReachGrid.new()
	var map := ReachFixture.map(PackedStringArray(["S......S", "S......S", "S......S", "S......S", "SSSSSSSS"]),
		PackedStringArray(["........", ".uuuuuu.", ".ffffff.", ".ffffff.", "........"]))
	grid.add_room(&"fixture", map, Vector2i.ZERO)
	var freeze := grid.for_kit(_with([], [Enums.Song.FREEZE]))
	assert_int(freeze.flags(Vector2i(3, 2)) & ReachGrid.SONG_FLOOR).is_equal(ReachGrid.SONG_FLOOR)
	assert_int(freeze.flags(Vector2i(3, 1)) & ReachGrid.SONG_FLOOR).is_equal(0)
	var shell := grid.for_kit(_with([], [Enums.Song.FREEZE, Enums.Song.BELL_JAR]))
	assert_int(shell.flags(Vector2i(3, 1)) & ReachGrid.SONG_FLOOR).is_equal(ReachGrid.SONG_FLOOR)
	assert_int(grid.for_kit(_base()).flags(Vector2i(3, 2)) & ReachGrid.SONG_FLOOR).is_equal(0)

# A GATE entity's closed body, placed at map px (48, 96): its cell (1, 2), feet anchor.
func _walls(scene: String, params: Dictionary = {}) -> Array[Vector2i]:
	var node := auto_free(load(scene).instantiate()) as Node2D
	EntityParams.apply(node, params)
	return node.call(&"reach_wall_cells", null, Vector2(48, 96))

func test_a_gate_walls_its_own_column_three_cells_tall() -> void:
	assert_array(_walls("res://scenes/world/interactables/gate/gate.tscn")).contains_exactly_in_any_order([Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 2)])

func test_a_gate_that_starts_open_and_a_lift_wall_nothing() -> void:
	assert_array(_walls("res://scenes/world/interactables/gate/gate.tscn", {"start_moved": true})).is_empty()
	assert_array(_walls("res://scenes/world/interactables/lift/lift.tscn")).is_empty()

func test_a_leaf_curtain_walls_its_size() -> void:
	assert_array(_walls("res://scenes/world/interactables/leaf_cover/leaf_cover.tscn", {"size": [32, 64]})).contains_exactly_in_any_order([Vector2i(1, 1), Vector2i(1, 2)])

func test_a_barrier_walls_three_cells() -> void:
	assert_array(_walls("res://scenes/world/interactables/fact_barrier/fact_barrier.tscn")).contains_exactly_in_any_order([Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 2)])

func test_a_kit_reads_facts_as_the_save_does() -> void:
	var kit := _with([Enums.PlayerSkill.DOUBLE_JUMP], [Enums.Song.ROOT], [Enums.PlayerItem.MEMORINA])
	assert_bool(kit.holds(PackedInt32Array([ReachKit.of(load(OWNS_MEMORINA) as SaveFact)]))).is_true()
	assert_bool(kit.holds(PackedInt32Array([ReachKit.song(Enums.Song.ROOT), ReachKit.song(Enums.Song.RAIN)]))).is_false()
	assert_bool(kit.holds(PackedInt32Array())).is_true()
	assert_bool(kit.has_skill(Enums.PlayerSkill.WALL_CLIMB)).is_false()
