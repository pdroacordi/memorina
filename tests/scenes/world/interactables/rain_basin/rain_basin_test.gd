class_name RainBasinTest extends GdUnitTestSuite

## Covers rain basin fill, drain, floating, and freeze behavior; direct signal setup uses memory 1 without a memory field.

const BASIN := preload("res://scenes/world/interactables/rain_basin/rain_basin.tscn")
const FLOATER := preload("res://scenes/world/interactables/floater/floater.tscn")
const RAIN := preload("res://resources/songs/rain.tres")
const FREEZE := preload("res://resources/songs/freeze.tres")

var _basin: FreezableWater
var _water: WaterBody
var _rain: RainBasin
# Keep test basins spatially separate because freed nodes remain until frame end and WaterBody.at() searches the tree.
var _placed := 0

func before_test() -> void:
	_placed += 1
	_basin = BASIN.instantiate() as FreezableWater
	_basin.position = Vector2(400 + 1000 * _placed, 200)
	add_child(_basin)
	auto_free(_basin)
	_water = _basin.get_node("Water") as WaterBody
	_rain = _basin.get_node("Rain") as RainBasin
	# Apply the deferred initial dry level before assertions run.
	_water.set_level(_water.level_range().y)

func _run(seconds: float) -> void:
	var steps := int(seconds / 0.1)
	for i in steps:
		_rain._physics_process(0.1)

func _rain_on(lit: bool) -> void:
	var receiver := _basin.get_node("RainReceiver") as SongReceiver
	if lit:
		receiver._lit_by = 1
		receiver.song_entered.emit(RAIN, _water.global_position)
	else:
		receiver._lit_by = 0
		receiver.song_left.emit(RAIN)

func test_it_is_dry_until_it_rains() -> void:
	assert_bool(_water.is_dry()).is_true()
	assert_float(_water.surface_rest_y()).is_equal(_water.level_range().y)

func test_rain_fills_it_to_its_painted_level() -> void:
	_rain_on(true)
	_run(_rain.fill_time + 0.2)
	assert_bool(_water.is_dry()).is_false()
	assert_float(_water.surface_rest_y()).is_equal(_water.level_range().x)

func test_the_last_pulse_leaving_drains_it() -> void:
	_rain_on(true)
	_run(_rain.fill_time + 0.2)
	_rain_on(false)
	_run(_rain.drain_time + 0.2)
	assert_bool(_water.is_dry()).is_true()

func test_what_floats_rides_up_with_the_water() -> void:
	var floater := FLOATER.instantiate() as Floater
	floater.position = Vector2(_water.global_position.x, _water.level_range().y)
	add_child(floater)
	auto_free(floater)
	floater._physics_process(0.0)
	assert_bool(floater.is_afloat()).is_false()
	_rain_on(true)
	_run(_rain.fill_time + 0.2)
	floater._physics_process(0.0)
	assert_bool(floater.is_afloat()).is_true()
	var line := roundf(_water.surface_y(floater.global_position.x) + floater.draft)
	assert_float(floater.ride_y()).is_equal_approx(line, 0.5)

func test_a_dry_basin_has_nothing_to_freeze() -> void:
	_basin._on_song_entered(FREEZE, _water.global_position)
	assert_bool(_basin.is_frozen()).is_false()

func test_frozen_it_holds_its_level() -> void:
	_rain_on(true)
	_run(_rain.fill_time + 0.2)
	_basin._on_song_entered(FREEZE, _water.global_position)
	_rain_on(false)
	_run(1.0)
	assert_float(_water.surface_rest_y()).is_equal(_water.level_range().x)
