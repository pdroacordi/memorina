class_name RisingPoolTest extends GdUnitTestSuite

## A pool painted with a reach rests at its water and Chuva raises it to the reach (design 03 section 6.5).

const POOL := preload("res://scenes/world/interactables/rain_basin/rising_pool.tscn")
const RAIN := preload("res://resources/songs/rain.tres")

var _pool: Node2D
var _water: WaterBody
var _rain: RainBasin
# Keep test pools apart because freed nodes remain until frame end and WaterBody.at() searches the tree.
var _placed := 0

func before_test() -> void:
	_placed += 1
	_pool = POOL.instantiate() as Node2D
	_pool.position = Vector2(-400 - 1000 * _placed, 200)
	add_child(_pool)
	auto_free(_pool)
	_water = _pool.get_node("Water") as WaterBody
	_rain = _pool.get_node("Rain") as RainBasin
	# Apply the deferred initial rest level before assertions run.
	_water.set_level(_water.rest_level())

func _run(seconds: float) -> void:
	for i in int(seconds / 0.1):
		_rain._physics_process(0.1)

func _rain_on(lit: bool) -> void:
	var receiver := _pool.get_node("RainReceiver") as SongReceiver
	if lit:
		receiver._lit_by = 1
		receiver.song_entered.emit(RAIN, _water.global_position)
	else:
		receiver._lit_by = 0
		receiver.song_left.emit(RAIN)

func test_it_stands_at_its_rest_below_the_reach() -> void:
	assert_bool(_water.is_dry()).is_false()
	assert_float(_water.surface_rest_y()).is_equal(_water.level_range().x + _water.rest_depth)

func test_rain_raises_it_to_the_reach() -> void:
	_rain_on(true)
	_run(_rain.fill_time + 0.2)
	assert_float(_water.surface_rest_y()).is_equal(_water.level_range().x)

func test_the_last_pulse_leaving_returns_it_to_rest_not_dry() -> void:
	_rain_on(true)
	_run(_rain.fill_time + 0.2)
	_rain_on(false)
	_run(_rain.drain_time + 0.2)
	assert_bool(_water.is_dry()).is_false()
	assert_float(_water.surface_rest_y()).is_equal(_water.rest_level())
