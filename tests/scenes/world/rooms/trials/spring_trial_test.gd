class_name SpringTrialTest extends GdUnitTestSuite

## Chuva's puzzles are only puzzles if Ivo alone cannot do them, and never a
## trap if he tries. Read from the real map, the real floating log, the rain
## basin's water layer and Ivo's reach.

const ROOM := "res://scenes/world/rooms/trials_spring/contents/spring_trial.room"
const FLOATER_SCENE := "res://scenes/world/interactables/floater/floater.tscn"
const BASIN_LAYER := "res://scenes/world/interactables/rain_basin/rain_basin_layer.tscn"
const PULSE_STATS := "res://resources/memory/default_pulse_stats.tres"
const CELL := 32.0
const FLOOR_ROW := 16
const MARGIN := 8.0
## The basin's far wall, where the passage is, and its near wall.
const PASSAGE_COL := 19
const BASIN_WALL_COL := 9

var _map: RoomMap

func before() -> void:
	var result := RoomMapParser.parse(FileAccess.get_file_as_string(ROOM), RoomLegend.load_default(), ROOM)
	assert(result.ok(), str(result.errors))
	_map = result.map

func _solid(col: int, row: int) -> bool:
	return _map.is_solid(_map.origin + Vector2i(col, row))

## Height above the floor of the top of the first solid cell at or below `row`.
func _top_from(col: int, row: int) -> float:
	for r: int in range(row, _map.size.y):
		if _solid(col, r):
			return (FLOOR_ROW - r) * CELL
	return 0.0

func _top(col: int) -> float:
	return _top_from(col, 0)

func _peak() -> float:
	return MapGuide.ivo_reach().peak()

## The lowest open run in the far wall above the floor: its floor is the solid
## cell under the open rows.
func _passage_floor() -> float:
	var row := FLOOR_ROW - 1
	while _solid(PASSAGE_COL, row):
		row -= 1
	return (FLOOR_ROW - row - 1) * CELL

func _step_col() -> int:
	return BASIN_WALL_COL + 1

func _lip() -> float:
	var layer := (load(BASIN_LAYER) as PackedScene).instantiate() as WaterLayer
	var lip := float(layer.surface_inset)
	layer.free()
	return lip

## Where rain brings the basin's water: its top painted row, less the lip.
func _full_level() -> float:
	var top := FLOOR_ROW
	for cell: Vector2 in _map.water.get("r", PackedVector2Array()):
		var col := int(cell.x) - _map.origin.x
		if col > BASIN_WALL_COL and col < PASSAGE_COL:
			top = mini(top, int(cell.y) - _map.origin.y)
	return (FLOOR_ROW - top) * CELL - _lip()

func test_the_passage_is_out_of_reach_from_the_basin_floor() -> void:
	assert_float(_passage_floor()).is_greater(_peak())

func test_from_the_step_it_is_too_far_across() -> void:
	var rise := _passage_floor() - _top(_step_col())
	var across := (PASSAGE_COL - _step_col() - 1) * CELL
	assert_float(MapGuide.ivo_reach().reach_at(rise)).is_less(across)

func test_from_the_wall_top_the_basin_is_too_wide_to_jump() -> void:
	assert_float(_top(BASIN_WALL_COL)).is_less_equal(_passage_floor())
	assert_float((PASSAGE_COL - BASIN_WALL_COL - 1) * CELL).is_greater(MapGuide.ivo_reach().gap())

func test_a_dry_basin_never_traps_him() -> void:
	assert_float(_top(BASIN_WALL_COL) - _top(_step_col())).is_less_equal(_peak() - MARGIN)
	assert_float(_top(_step_col())).is_less_equal(_peak() - MARGIN)

## The geometry of the lift; that a real basin fills and floats a real log is
## rain_basin_test.
func test_the_full_basin_floats_the_log_up_to_the_passage() -> void:
	var floater := auto_free((load(FLOATER_SCENE) as PackedScene).instantiate()) as Floater
	var shape := floater.get_node("CollisionShape2D") as CollisionShape2D
	var top_above_bottom := -(shape.position.y - (shape.shape as RectangleShape2D).size.y * 0.5)
	var standing := _full_level() - floater.draft + top_above_bottom
	assert_float(standing + _peak()).is_greater_equal(_passage_floor() + MARGIN)
	assert_float(_full_level()).is_greater(0.0)

func _moat() -> Vector2i:
	var start := -1
	for col: int in _map.size.x:
		var open := not _solid(col, FLOOR_ROW)
		if open and start < 0:
			start = col
		elif not open and start >= 0:
			return Vector2i(start, col)
	return Vector2i.ZERO

## The passage is walked into off the log, not jumped at: tall enough to take
## him standing, and the log lies by it, a hop away at most.
func test_he_steps_off_the_log_into_the_passage() -> void:
	var row := FLOOR_ROW - 1
	while _solid(PASSAGE_COL, row):
		row -= 1
	var open := 0
	while row >= 0 and not _solid(PASSAGE_COL, row):
		open += 1
		row -= 1
	assert_int(open).is_greater_equal(3)
	var log_cell := Vector2i.ZERO
	for placed: Dictionary in _map.entities:
		if placed.symbol == "O":
			log_cell = (placed.cell as Vector2i) - _map.origin
	var floater := auto_free((load(FLOATER_SCENE) as PackedScene).instantiate()) as Floater
	var half := ((floater.get_node("CollisionShape2D") as CollisionShape2D).shape as RectangleShape2D).size.x * 0.5
	var gap := PASSAGE_COL * CELL - ((log_cell.x + 0.5) * CELL + half)
	assert_float(gap).is_less_equal(CELL)

func test_the_moat_is_too_wide_to_jump() -> void:
	var moat := _moat()
	assert_float((moat.y - moat.x) * CELL).is_greater(MapGuide.ivo_reach().gap())

func test_a_dry_moat_can_be_climbed_out_of() -> void:
	var moat := _moat()
	var depth := -_top_from(moat.x, FLOOR_ROW)
	assert_float(depth).is_less_equal(_peak() - MARGIN)

## Only that the pulse is wide enough; that the ice forms and holds is
## rain_basin_test and the song_rain_freeze_moat playtest.
func test_congelar_at_its_edge_is_wide_enough_for_the_moat() -> void:
	var moat := _moat()
	var radius := (load(PULSE_STATS) as PulseStats).max_radius
	assert_float(radius).is_greater((moat.y - moat.x + 1) * CELL)

# --- Enraizar ------------------------------------------------------------------

const ROOT_STATS := "res://resources/memory/root_pulse_stats.tres"
const ROOT_SCENE := "res://scenes/world/memory/song_effects/roots/root_grower.tscn"
const SHAFT_NEAR_WALL := 22
const SHAFT_FAR_WALL := 26
const LEDGE_COL := 49

func _root_radius() -> float:
	return (load(ROOT_STATS) as PulseStats).max_radius

func _grower() -> RootGrower:
	return auto_free((load(ROOT_SCENE) as PackedScene).instantiate()) as RootGrower

## Height above the floor of the far wall's opening: the solid cell under the
## lowest open run above its doorway's lintel.
func _opening_floor() -> float:
	var row := FLOOR_ROW - 1
	while not _solid(SHAFT_FAR_WALL, row):
		row -= 1
	while _solid(SHAFT_FAR_WALL, row):
		row -= 1
	return (FLOOR_ROW - row - 1) * CELL

func test_the_shaft_opening_is_out_of_reach_from_the_floor() -> void:
	assert_float(_opening_floor()).is_greater(_peak())

func test_the_near_wall_runs_to_the_ceiling() -> void:
	for row: int in range(0, FLOOR_ROW - 2):
		assert_bool(_solid(SHAFT_NEAR_WALL, row)).is_true()

func test_from_the_floor_the_web_reaches_the_opening() -> void:
	# Every rung up to the opening's floor has both faces inside the pulse lit
	# on the floor between the walls.
	var half := (SHAFT_FAR_WALL - SHAFT_NEAR_WALL - 1) * 0.5 * CELL
	var top_row := FLOOR_ROW - int(_opening_floor() / CELL)
	for row: int in range(top_row, FLOOR_ROW - 2):
		var height := (FLOOR_ROW - row - 0.5) * CELL
		assert_float(Vector2(half, height).length()).is_less(_root_radius())

func _chasm() -> Vector2i:
	var start := -1
	for col: int in range(_moat().y, _map.size.x):
		var open := not _solid(col, FLOOR_ROW)
		if open and start < 0:
			start = col
		elif not open and start >= 0:
			return Vector2i(start, col)
	return Vector2i.ZERO

func test_the_chasm_is_too_wide_to_jump_but_not_for_roots() -> void:
	var chasm := _chasm()
	var gap := chasm.y - chasm.x
	assert_float(gap * CELL).is_greater(MapGuide.ivo_reach().gap())
	assert_int(gap).is_less_equal(_grower().max_bridge_cells)

func _ledge_top() -> float:
	return -_top_from(LEDGE_COL, FLOOR_ROW)

func test_from_the_near_bank_the_pulse_misses_the_far_one() -> void:
	var chasm := _chasm()
	assert_float((chasm.y - chasm.x) * CELL).is_greater(_root_radius())

func test_from_the_ledge_the_pulse_covers_both_banks() -> void:
	var chasm := _chasm()
	var x := (LEDGE_COL + 0.5) * CELL
	var depth := _ledge_top()
	assert_float(Vector2(x - chasm.x * CELL, depth).length()).is_less(_root_radius())
	assert_float(Vector2(chasm.y * CELL - x, depth).length()).is_less(_root_radius())

func test_from_the_ledge_the_far_bank_is_out_of_reach_and_the_near_is_not() -> void:
	var chasm := _chasm()
	var reach := MapGuide.ivo_reach().reach_at(_ledge_top())
	assert_float(chasm.y * CELL - (LEDGE_COL + 1) * CELL).is_greater(reach)
	assert_float(LEDGE_COL * CELL - chasm.x * CELL).is_less(reach)

func test_from_the_ledge_he_jumps_up_through_the_bridge() -> void:
	assert_float(_peak()).is_greater_equal(_ledge_top() + MARGIN)

## The roots the trial relies on are the ones the real finder sees in this map,
## with the real grower's limits: a shaft across the opening's rows, and a
## bridge across the chasm.
func _spans() -> Array[RootSpanFinder.Span]:
	var grower := _grower()
	return RootSpanFinder.find(_map, grower.wet_bridge_cells, grower.max_shaft_width, grower.min_shaft_rows, grower.max_pillar_cells)

func test_the_finder_sees_a_shaft_up_to_the_opening() -> void:
	var top_row := FLOOR_ROW - int(_opening_floor() / CELL) + _map.origin.y
	var found := false
	for span: RootSpanFinder.Span in _spans():
		if span.kind == RootSpanFinder.Kind.SHAFT and span.a.x - _map.origin.x == SHAFT_NEAR_WALL and span.rows.x <= top_row and span.rows.y >= FLOOR_ROW - 3 + _map.origin.y:
			found = true
	assert_bool(found).is_true()

func test_the_finder_sees_a_bridge_across_the_chasm() -> void:
	var chasm := _chasm()
	var found := false
	for span: RootSpanFinder.Span in _spans():
		if span.kind == RootSpanFinder.Kind.BRIDGE and span.a.x - _map.origin.x == chasm.x - 1 and span.b.x - _map.origin.x == chasm.y:
			found = span.gap() <= _grower().max_bridge_cells
	assert_bool(found).is_true()

# --- Chuva then Enraizar --------------------------------------------------------

const RAIN := "res://resources/songs/rain.tres"
const WET_STEP_COL := 61
const WET_LEDGE_COL := 65

func _wet_chasm() -> Vector2i:
	var start := -1
	for col: int in range(_chasm().y, _map.size.x):
		var open := not _solid(col, FLOOR_ROW)
		if open and start < 0:
			start = col
		elif not open and start >= 0:
			return Vector2i(start, col)
	return Vector2i.ZERO

func _wet_ledge_top() -> float:
	return -_top_from(WET_LEDGE_COL, FLOOR_ROW)

func test_the_wet_chasm_needs_wet_earth() -> void:
	var chasm := _wet_chasm()
	var gap := chasm.y - chasm.x
	assert_float(gap * CELL).is_greater(MapGuide.ivo_reach().gap())
	assert_int(gap).is_greater(_grower().max_bridge_cells)
	assert_int(gap).is_less_equal(_grower().wet_bridge_cells)

func test_from_the_wet_ledge_enraizar_covers_both_banks() -> void:
	var chasm := _wet_chasm()
	var x := (WET_LEDGE_COL + 0.5) * CELL
	var depth := _wet_ledge_top()
	assert_float(Vector2(x - chasm.x * CELL, depth).length()).is_less(_root_radius())
	assert_float(Vector2(chasm.y * CELL - x, depth).length()).is_less(_root_radius())

func test_from_the_near_bank_enraizar_misses_the_far_one() -> void:
	var chasm := _wet_chasm()
	assert_float((chasm.y - chasm.x) * CELL).is_greater(_root_radius())

func test_chuva_from_the_wet_ledge_wets_both_banks() -> void:
	var chasm := _wet_chasm()
	var radius := (load(RAIN) as Song).pulse_stats.max_radius
	var x := (WET_LEDGE_COL + 0.5) * CELL
	var depth := _wet_ledge_top()
	assert_float(Vector2(x - chasm.x * CELL, depth).length()).is_less(radius)
	assert_float(Vector2(chasm.y * CELL - x, depth).length()).is_less(radius)

func test_from_the_wet_ledge_and_step_the_far_bank_is_out_of_reach() -> void:
	var chasm := _wet_chasm()
	var reach := MapGuide.ivo_reach()
	assert_float(chasm.y * CELL - (WET_LEDGE_COL + 1) * CELL).is_greater(reach.reach_at(_wet_ledge_top()))
	assert_float(chasm.y * CELL - (WET_STEP_COL + 1) * CELL).is_greater(reach.reach_at(-_top_from(WET_STEP_COL, FLOOR_ROW)))

## Ledge to step to near bank: the chasm never traps him.
func test_the_wet_ledge_leads_back_to_the_near_bank() -> void:
	var chasm := _wet_chasm()
	var reach := MapGuide.ivo_reach()
	var step_top := -_top_from(WET_STEP_COL, FLOOR_ROW)
	assert_float((WET_LEDGE_COL - WET_STEP_COL - 1) * CELL).is_less(reach.reach_at(_wet_ledge_top() - step_top))
	assert_float((WET_STEP_COL - chasm.x) * CELL).is_less(reach.reach_at(step_top))

func test_the_finder_sees_a_bridge_across_the_wet_chasm() -> void:
	var chasm := _wet_chasm()
	var found := false
	for span: RootSpanFinder.Span in _spans():
		if span.kind == RootSpanFinder.Kind.BRIDGE and span.a.x - _map.origin.x == chasm.x - 1 and span.b.x - _map.origin.x == chasm.y:
			found = true
	assert_bool(found).is_true()

## The far bank is one cell before the wall: the way back is a drop onto the ledge.
func test_from_the_far_bank_the_ledge_is_in_reach() -> void:
	var chasm := _wet_chasm()
	var across := (chasm.y - WET_LEDGE_COL - 1) * CELL
	assert_float(MapGuide.ivo_reach().reach_at(-_wet_ledge_top())).is_greater_equal(across)
