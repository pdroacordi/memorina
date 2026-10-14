class_name ReachLatticeTest extends GdUnitTestSuite

## Pins the lattice to JumpReach and checks one-ways, ceilings, hazards, song floors and walls on small grids.

const CELL := 32.0

var _reach: JumpReach

func before() -> void:
	_reach = MapGuide.ivo_reach()

# A floor with a one-way ledge `rise` rows above it, off to the side.
func _ledge_grid(rise: int) -> ReachGrid:
	var rows := PackedStringArray()
	for y: int in 13:
		rows.append("..........=======......." if y == 13 - rise else "........................")
	rows.append("########################")
	return ReachFixture.grid(rows, Vector2i(4, 12))

func _reaches_ledge(rise: int, tier: ReachLattice.Tier) -> bool:
	return Vector2i(12, 12 - rise) in ReachFixture.closure(_ledge_grid(rise), Vector2i(4, 12), tier)

# Two floors with `gap` cells of open drop between them.
func _gap_grid(gap: int) -> ReachGrid:
	var rows := PackedStringArray([".".repeat(16 + gap), ".".repeat(16 + gap), ".".repeat(16 + gap)])
	for y: int in 3:
		rows.append("#".repeat(8) + ".".repeat(gap) + "#".repeat(8))
	return ReachFixture.grid(rows, Vector2i(7, 2))

func _clears(gap: int, tier: ReachLattice.Tier) -> bool:
	var landings := ReachFixture.ivo().landings(_gap_grid(gap), [Vector2i(7, 2)] as Array[Vector2i], tier)
	return Vector2i(8 + gap, 2) in landings

func test_the_body_is_read_from_the_capsule() -> void:
	assert_that(ReachFixture.ivo().body).is_equal(Vector2i(1, 2))

func test_a_jump_rises_as_many_cells_as_its_peak() -> void:
	var cells := floori(_reach.peak() / CELL)
	assert_bool(_reaches_ledge(cells, ReachLattice.Tier.BASE)).is_true()
	assert_bool(_reaches_ledge(cells + 1, ReachLattice.Tier.BASE)).is_false()

func test_a_double_jump_rises_as_many_cells_as_both_peaks() -> void:
	var cells := floori(_reach.peak(true) / CELL)
	assert_bool(_reaches_ledge(cells, ReachLattice.Tier.DOUBLE_JUMP)).is_true()
	assert_bool(_reaches_ledge(cells + 1, ReachLattice.Tier.DOUBLE_JUMP)).is_false()

func test_a_jump_clears_as_many_cells_as_its_gap() -> void:
	var cells := floori(_reach.gap() / CELL)
	assert_bool(_clears(cells, ReachLattice.Tier.BASE)).is_true()
	assert_bool(_clears(cells + 1, ReachLattice.Tier.BASE)).is_false()

# JumpReach.gap(true) presses the air jump at the apex; a later press carries further, and the lattice presses at every
# step. The widest gap over every press, from the same heights, rounded optimistically by under a cell.
func test_a_double_jump_clears_as_many_cells_as_its_latest_press() -> void:
	var cells := floori(_best_double_jump_gap() / CELL)
	assert_int(cells).is_greater_equal(floori(_reach.gap(true) / CELL))
	assert_bool(_clears(cells, ReachLattice.Tier.DOUBLE_JUMP)).is_true()
	assert_bool(_clears(cells + 2, ReachLattice.Tier.DOUBLE_JUMP)).is_false()

# Px across the widest same-height gap, pressing the air jump at whichever physics step carries furthest.
func _best_double_jump_gap() -> float:
	var jump := _reach.heights(_reach.jump.jump_height)
	var air := _reach.heights(_reach.double_jump_height)
	var steps := 0
	for press: int in jump.size():
		for j: int in range(1, air.size()):
			if air[j] < air[j - 1] and jump[press] + air[j] <= 0.0 and jump[press] + air[j - 1] > 0.0:
				steps = maxi(steps, press + j)
				break
	return steps * JumpReach.STEP * _reach.locomotion.move_speed + _reach.body_radius * 2.0

func test_a_one_way_is_jumped_up_through_and_never_dropped_through() -> void:
	var grid := ReachFixture.grid(PackedStringArray([
		"#..........#",
		"#..........#",
		"#..........#",
		"#==========#",
		"#..........#",
		"#..........#",
		"############",
	]), Vector2i(5, 5))
	var up := ReachFixture.ivo().landings(grid, [Vector2i(5, 5)] as Array[Vector2i], ReachLattice.Tier.BASE)
	var down := ReachFixture.ivo().landings(grid, [Vector2i(5, 2)] as Array[Vector2i], ReachLattice.Tier.BASE)
	assert_bool(Vector2i(5, 2) in up).is_true()
	assert_bool(down.any(func(cell: Vector2i) -> bool: return cell.y == 5)).is_false()

func test_a_roof_carries_like_a_one_way() -> void:
	var grid := ReachFixture.grid(PackedStringArray([
		"............",
		"....^^^^....",
		"............",
		"............",
		"############",
	]), Vector2i(1, 3))
	assert_bool(Vector2i(5, 0) in ReachFixture.closure(grid, Vector2i(1, 3), ReachLattice.Tier.BASE)).is_true()

# gotchas/zigzag-ledges-two-rows-apart-seal-a-shaft: ledges meeting corner to corner need two rows between them.
func _shaft(lower_ledge_row: int) -> ReachGrid:
	var rows := PackedStringArray()
	for y: int in 12:
		if y == 0 or y == 11:
			rows.append("SSSSSSSSS")
		elif y == 4:
			rows.append("SSSS....S")
		elif y == lower_ledge_row:
			rows.append("S...SSSSS")
		else:
			rows.append("S.......S")
	return ReachFixture.grid(rows, Vector2i(2, 3))

func test_zigzag_ledges_two_rows_apart_seal_the_shaft_both_ways() -> void:
	var tier := ReachLattice.Tier.DOUBLE_JUMP
	assert_bool(Vector2i(2, 10) in ReachFixture.closure(_shaft(6), Vector2i(2, 3), tier)).is_false()
	assert_bool(Vector2i(2, 3) in ReachFixture.closure(_shaft(6), Vector2i(2, 10), tier)).is_false()

func test_zigzag_ledges_three_rows_apart_leave_the_shaft_open() -> void:
	var tier := ReachLattice.Tier.DOUBLE_JUMP
	assert_bool(Vector2i(2, 10) in ReachFixture.closure(_shaft(7), Vector2i(2, 3), tier)).is_true()
	assert_bool(Vector2i(2, 3) in ReachFixture.closure(_shaft(7), Vector2i(2, 10), tier)).is_true()

func test_a_low_ceiling_caps_the_jump() -> void:
	var grid := ReachFixture.grid(PackedStringArray([
		"..............",
		"......====....",
		"SSSSSS........",
		"..............",
		"..............",
		"##############",
	]), Vector2i(2, 4))
	assert_bool(Vector2i(7, 0) in ReachFixture.closure(grid, Vector2i(2, 4), ReachLattice.Tier.BASE)).is_true()
	var capped := ReachFixture.ivo().landings(grid, [Vector2i(2, 4)] as Array[Vector2i], ReachLattice.Tier.BASE)
	assert_bool(capped.any(func(cell: Vector2i) -> bool: return cell.x < 6 and cell.y < 2)).is_false()

func test_a_lake_is_never_landed_in() -> void:
	var grid := ReachFixture.grid(PackedStringArray([
		"................",
		"................",
		"####........####",
		"################",
	]), Vector2i(1, 1), PackedStringArray([
		"................",
		"................",
		"....wwwwwwww....",
		"................",
	]))
	var landings := ReachFixture.ivo().landings(grid, [Vector2i(3, 1)] as Array[Vector2i], ReachLattice.Tier.BASE)
	assert_bool(landings.any(func(cell: Vector2i) -> bool: return cell.y == 2)).is_false()

func test_a_pool_lets_ivo_in_and_freezes_into_a_floor() -> void:
	var grid := ReachFixture.grid(PackedStringArray([
		"................",
		"................",
		"####........####",
		"####........####",
		"################",
	]), Vector2i(1, 1), PackedStringArray([
		"................",
		"................",
		"....ffffffff....",
		"....ffffffff....",
		"................",
	]))
	var landings := ReachFixture.ivo().landings(grid, [Vector2i(3, 1)] as Array[Vector2i], ReachLattice.Tier.BASE)
	assert_bool(Vector2i(6, 3) in landings).is_true()
	assert_bool(Vector2i(6, 1) in landings).is_true()
	assert_bool(ReachFixture.ivo().is_wet(Vector2i(6, 3))).is_true()

func test_a_song_floor_is_landed_on_or_fallen_through() -> void:
	var grid := ReachFixture.grid(PackedStringArray([
		"................",
		"................",
		"####........####",
		"................",
		"................",
		"################",
	]), Vector2i(1, 1))
	grid.add_cells([Vector2i(6, 2), Vector2i(7, 2)] as Array[Vector2i], ReachGrid.SONG_FLOOR)
	var landings := ReachFixture.ivo().landings(grid, [Vector2i(3, 1)] as Array[Vector2i], ReachLattice.Tier.BASE)
	assert_bool(Vector2i(6, 1) in landings).is_true()
	assert_bool(Vector2i(6, 4) in landings).is_true()

func test_a_root_is_climbed() -> void:
	var grid := ReachFixture.grid(PackedStringArray([
		"................",
		"######..........",
		"................",
		"................",
		"................",
		"................",
		"................",
		"................",
		"################",
	]), Vector2i(8, 7))
	var column: Array[Vector2i] = []
	for y: int in range(2, 8):
		column.append(Vector2i(6, y))
	grid.add_cells(column, ReachGrid.CLIMB)
	assert_bool(Vector2i(2, 0) in ReachFixture.closure(grid, Vector2i(8, 7), ReachLattice.Tier.BASE)).is_true()

# bugs/the-reach-audit-jumps-from-mid-air-inside-a-current: a current is no floor to jump from.
func test_a_current_gives_no_jump_from_mid_air() -> void:
	var rows := PackedStringArray()
	for y: int in 11:
		rows.append("....====........" if y == 2 else "................")
	rows.append("################")
	var grid := ReachFixture.grid(rows, Vector2i(1, 10))
	var box: Array[Vector2i] = []
	var exits: Array[Vector2i] = []
	for y: int in range(5, 9):
		for x: int in range(2, 12):
			box.append(Vector2i(x, y))
			if x == 11:
				exits.append(Vector2i(x, y))
	grid.add_cells(box, ReachGrid.CURRENT)
	grid.add_cells(exits, ReachGrid.CURRENT_EXIT)
	var reached := ReachFixture.closure(grid, Vector2i(1, 10), ReachLattice.Tier.BASE)
	assert_bool(Vector2i(6, 7) in reached).is_true()
	assert_bool(Vector2i(5, 1) in reached).is_false()

func test_only_wall_climb_slides_up_a_tall_pit() -> void:
	var rows := PackedStringArray(["S.........S", "SSSS...SSSS"])
	for y: int in 10:
		rows.append("SSSS...SSSS")
	rows.append("SSSSSSSSSSS")
	var grid := ReachFixture.grid(rows, Vector2i(5, 11))
	assert_bool(Vector2i(2, 0) in ReachFixture.closure(grid, Vector2i(5, 11), ReachLattice.Tier.DOUBLE_JUMP)).is_false()
	assert_bool(Vector2i(2, 0) in ReachFixture.closure(grid, Vector2i(5, 11), ReachLattice.Tier.WALL_CLIMB)).is_true()

# A short open-topped room: a floor at row 2, walls nowhere.
func _open_top() -> ReachGrid:
	return ReachFixture.grid(PackedStringArray(["................", "................", "################"]), Vector2i(8, 1))

# The sky band opens floori(RoomEdges.CEILING_RISE / 32) rows: the feet reach row -3, the head row -4, never higher, and
# nothing beside the room is open (the side poke is gone).
func test_an_open_top_opens_its_sky_band_and_nothing_else_outside() -> void:
	var lattice := ReachFixture.ivo()
	lattice.bake(_open_top())
	assert_int(floori(RoomEdges.CEILING_RISE / CELL)).is_equal(4)
	assert_bool(lattice.is_open(Vector2i(8, -3))).is_true()
	assert_bool(lattice.is_open(Vector2i(8, -4))).is_false()
	assert_bool(lattice.is_open(Vector2i(-1, 1))).is_false()
	assert_bool(lattice.is_open(Vector2i(16, 1))).is_false()
	assert_bool(lattice.is_open(Vector2i(0, 1))).is_true()

func test_a_closed_top_has_no_sky_band() -> void:
	var grid := ReachFixture.grid(PackedStringArray(["SSSSSSSSSSSSSSSS", "................", "................", "################"]), Vector2i(8, 2))
	assert_array(grid.bands).is_empty()
	var reached := ReachFixture.ivo().search(grid, [Vector2i(8, 2)] as Array[Vector2i], true, false)
	assert_bool(reached.keys().any(func(cell: Vector2i) -> bool: return cell.y < 2)).is_false()
