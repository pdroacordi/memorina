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
