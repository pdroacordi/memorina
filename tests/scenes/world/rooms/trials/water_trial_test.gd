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
const FREEZABLE_LAYER := "res://scenes/world/interactables/freezable_water/freezable_water_layer.tscn"
const POOL_PROFILE := "res://resources/world/water/still_pool_profile.tres"
const ICE := "res://resources/world/water/frost_ice.tres"
const GALE := "res://resources/songs/gale.tres"
const GALE_FIELD := "res://scenes/world/memory/song_effects/gale/gale_field.tscn"
## Where Ivo plays Vendaval in the frozen wave.
const SHORE_COL := 29
const WAVE_WALL_COL := 42
## World seconds from drawing the Memorina for Congelar to its ice reaching the wall, measured in playtests/2026-10-08-frozen-wave.
const CONGELAR_TO_WALL := 7.2

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

# --- The frozen wave ---------------------------------------------------------

## The frozen wave's pool, as (first column, one past the last).
func _wave_pool() -> Vector2i:
	var start := -1
	for col: int in range(SHORE_COL, _map.size.x):
		var open := not _solid(col, FLOOR_ROW)
		if open and start < 0:
			start = col
		elif not open and start >= 0:
			return Vector2i(start, col)
	return Vector2i.ZERO

func _wave_crest() -> WindCrest:
	var pool := _wave_pool()
	return WindCrest.new(load(POOL_PROFILE) as WaterProfile, (pool.y - pool.x) * CELL)

func _wall_top() -> float:
	return _top_from(WAVE_WALL_COL, 0)

func _freezable_inset() -> float:
	var layer := (load(FREEZABLE_LAYER) as PackedScene).instantiate() as WaterLayer
	var inset := float(layer.surface_inset)
	layer.free()
	return inset

## Height above the shore of the ice's top over the crest of a wave `height` px tall.
func _ramp_top(height: float) -> float:
	return height - _freezable_inset()

func test_the_wall_is_out_of_reach_from_the_shore_and_from_flat_ice() -> void:
	assert_float(_wall_top()).is_greater(_peak())
	assert_float(_wall_top() - _ramp_top(0.0)).is_greater(_peak())

func test_from_the_top_of_a_full_crest_the_wall_is_in_reach() -> void:
	assert_float(_wall_top() - _ramp_top(_wave_crest().cap())).is_less_equal(_peak() - MARGIN)


## The crest over time after Vendaval's pulse is lit: the real gale's mean wind over the pool, its pulse growing and contracting.
func _crest_over_time(seconds: float, step: float) -> PackedFloat32Array:
	var field := auto_free((load(GALE_FIELD) as PackedScene).instantiate()) as GaleField
	var stats := (load(GALE) as Song).pulse_stats
	var timeline := PulseTimeline.new(stats, 1.0)
	var crest := _wave_crest()
	var pool := _wave_pool()
	var origin := Vector2((SHORE_COL + 0.5) * CELL, 0.0)
	var heights := PackedFloat32Array()
	for i in roundi(seconds / step):
		timeline.advance(step)
		var strength := field.contracting if timeline.phase == PulseTimeline.Phase.CONTRACT else 1.0
		var total := 0.0
		for col: int in range(pool.x, pool.y):
			total += GaleShape.wind(origin, Vector2((col + 0.5) * CELL, 8.0), timeline.radius(), field.eye, field.speed * strength, 1.0).x
		crest.step(step, total / (pool.y - pool.x), 1.0)
		heights.append(crest.height())
	return heights

## The crest the ramp needs for its top to bring the wall within a jump.
func _needed_crest() -> float:
	return _wall_top() - (_peak() - MARGIN) + _freezable_inset()

func test_congelar_at_once_freezes_a_wave_too_low() -> void:
	var step := 0.05
	var heights := _crest_over_time(CONGELAR_TO_WALL + 1.0, step)
	var at_once := heights[roundi(CONGELAR_TO_WALL / step) - 1]
	assert_float(at_once).is_less(_needed_crest())

## There is a window of at least two seconds in which the wave stands high enough when the ice reaches it.
func test_waiting_a_little_freezes_a_ramp() -> void:
	var step := 0.05
	var heights := _crest_over_time(20.0, step)
	var window := 0.0
	for height: float in heights:
		if height >= _needed_crest():
			window += step
	assert_float(window).is_greater_equal(2.0)

func test_vendaval_from_the_shore_blows_hard_enough_over_the_pool() -> void:
	var field := auto_free((load(GALE_FIELD) as PackedScene).instantiate()) as GaleField
	var radius := (load(GALE) as Song).pulse_stats.max_radius
	var pool := _wave_pool()
	var origin := Vector2((SHORE_COL + 0.5) * CELL, 0.0)
	var total := 0.0
	for col: int in range(pool.x, pool.y):
		total += GaleShape.wind(origin, Vector2((col + 0.5) * CELL, 8.0), radius, field.eye, field.speed, 1.0).x
	assert_float(total / (pool.y - pool.x)).is_greater_equal((load(POOL_PROFILE) as WaterProfile).crest_full_wind)

func test_every_part_of_the_full_ramp_is_walkable() -> void:
	var crest := _wave_crest()
	var profile := load(POOL_PROFILE) as WaterProfile
	for i in roundi(profile.crest_rise_time / 0.1):
		crest.step(0.1, 1000.0, 1.0)
	var pool := _wave_pool()
	var columns := int((pool.y - pool.x) * CELL / profile.column_width)
	var shape := IceSheetShape.new(columns, profile.column_width, 0.0)
	for column in columns:
		var top := -crest.offset(column, columns, profile.column_width)
		shape.capture(column, top, top + 6.0)
	var per_segment := int(float((load(ICE) as IceProfile).segment_width) / profile.column_width)
	var points := shape.segment_points(per_segment)
	for i in points.size() - 1:
		assert_bool(IceSheetShape.walkable(points, i, IceCollider.MAX_FLOOR_ANGLE)).is_true()
