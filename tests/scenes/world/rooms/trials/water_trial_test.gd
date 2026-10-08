class_name WaterTrialTest extends GdUnitTestSuite

## The water trials are puzzles only if Ivo alone cannot do them; read from the real map, log, water layer and Ivo's reach.

const ROOM := "res://scenes/world/rooms/trials_solstice/contents/water_trial.room"
const FLOATER_SCENE := "res://scenes/world/interactables/floater/floater.tscn"
const POOL_LAYER := "res://scenes/world/environment/water/water_pool_layer.tscn"
const CELL := 32.0
const FLOOR_ROW := 16
const MARGIN := 8.0
const TANK_WALL_COL := 9
const PASSAGE_COL := 18

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

func _peak() -> float:
	return MapGuide.ivo_reach().peak()

## Height above the floor of the passage's floor: the solid cell under the open run in the far wall.
func _passage_floor() -> float:
	var row := 0
	while _solid(PASSAGE_COL, row):
		row += 1
	while not _solid(PASSAGE_COL, row):
		row += 1
	return (FLOOR_ROW - row) * CELL

func _inset() -> float:
	var layer := (load(POOL_LAYER) as PackedScene).instantiate() as WaterLayer
	var inset := float(layer.surface_inset)
	layer.free()
	return inset

## Height above the floor of the waterline when the top painted row of `cells` is the surface.
func _level(cells: PackedVector2Array) -> float:
	var top := _map.size.y
	for cell: Vector2 in cells:
		top = mini(top, int(cell.y) - _map.origin.y)
	return (FLOOR_ROW - top) * CELL - _inset()

## Height above the floor of the log's top when the water stands at `level`.
func _log_top(level: float) -> float:
	var floater := auto_free((load(FLOATER_SCENE) as PackedScene).instantiate()) as Floater
	var shape := floater.get_node("CollisionShape2D") as CollisionShape2D
	var top_above_bottom := -(shape.position.y - (shape.shape as RectangleShape2D).size.y * 0.5)
	return level - floater.draft + top_above_bottom

func test_the_reach_joins_the_pool() -> void:
	assert_bool(_map.reach.has("~")).is_true()
	assert_bool(_map.reach.has("r")).is_false()

func test_the_passage_is_out_of_reach_from_the_floor() -> void:
	assert_float(_passage_floor()).is_greater(_peak())

func test_from_the_tank_wall_it_is_too_far_across() -> void:
	var rise := _passage_floor() - _top_from(TANK_WALL_COL, 0)
	var across := (PASSAGE_COL - TANK_WALL_COL - 1) * CELL
	# The margin covers a late coyote jump, which JumpReach does not model.
	assert_float(MapGuide.ivo_reach().reach_at(rise) + 2.0 * MARGIN).is_less(across)

func test_from_the_log_at_rest_the_passage_is_out_of_reach() -> void:
	assert_float(_log_top(_level(_map.water["~"])) + _peak()).is_less(_passage_floor())

func test_from_the_log_at_the_reach_he_steps_into_the_passage() -> void:
	assert_float(_log_top(_level(_map.reach["~"])) + _peak()).is_greater_equal(_passage_floor() + MARGIN)

func test_the_log_floats_by_the_far_wall() -> void:
	var log_cell := Vector2i.ZERO
	for placed: Dictionary in _map.entities:
		if placed.symbol == "O":
			log_cell = (placed.cell as Vector2i) - _map.origin
	var floater := auto_free((load(FLOATER_SCENE) as PackedScene).instantiate()) as Floater
	var half := ((floater.get_node("CollisionShape2D") as CollisionShape2D).shape as RectangleShape2D).size.x * 0.5
	assert_float(PASSAGE_COL * CELL - ((log_cell.x + 0.5) * CELL + half)).is_less_equal(CELL)
