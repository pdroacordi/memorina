class_name WaterDisplacementTest extends GdUnitTestSuite

## A pool painted with a shell reach rises around a Redoma shell and falls back when it lets go; ice is a lid.

const POOL := preload("res://scenes/world/interactables/freezable_water/freezable_water.tscn")
const REST := 24.0

var _pool: FreezableWater
var _water: WaterBody
var _placed := 0

func before_test() -> void:
	_placed += 1
	_pool = POOL.instantiate() as FreezableWater
	_pool.position = Vector2(400, -3000 - 1000 * _placed)
	_water = _pool.get_node("Water") as WaterBody
	_water.rest_depth = REST
	_water.displaces = true
	add_child(_pool)
	auto_free(_pool)
	_water.set_level(_water.rest_level())

func _run(seconds: float) -> void:
	for i in roundi(seconds / 0.1):
		_water._step_displacement(0.1)

func _hold() -> void:
	var left := _water.global_position.x - _water.size.x * 0.5
	_water.hold_out(self, Vector2(left, _water.rest_level() + 20.0), 60.0)

## Without a hand: the body sets its own rest level, deferred, once it is in the tree.
func test_it_stands_at_rest() -> void:
	var pool := POOL.instantiate() as FreezableWater
	pool.position = Vector2(-400, -9000)
	var water := pool.get_node("Water") as WaterBody
	water.rest_depth = REST
	water.displaces = true
	add_child(pool)
	auto_free(pool)
	await get_tree().process_frame
	assert_float(water.surface_rest_y()).is_equal(water.rest_level())

func test_a_shell_raises_it_no_higher_than_its_reach() -> void:
	_hold()
	_run(3.0)
	assert_float(_water.surface_rest_y()).is_less(_water.rest_level())
	assert_float(_water.surface_rest_y()).is_greater_equal(_water.level_range().x)

func test_it_falls_back_when_the_shell_lets_go() -> void:
	_hold()
	_run(3.0)
	_water.release(self)
	_run(3.0)
	assert_float(_water.surface_rest_y()).is_equal(_water.rest_level())

func test_ice_is_a_lid() -> void:
	_water.set_lid(true)
	_hold()
	_run(3.0)
	assert_float(_water.surface_rest_y()).is_equal(_water.rest_level())
