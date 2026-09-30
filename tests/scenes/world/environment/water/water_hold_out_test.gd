class_name WaterHoldOutTest extends GdUnitTestSuite

## Redoma holds water out of its shell: the columns whose waterline lies in
## the disc are dry - no depth, no hazard - until it lets go.

const POOL := preload("res://scenes/world/environment/water/water_pool.tscn")

var _water: WaterBody
var _placed := 0

func before_test() -> void:
	_placed += 1
	_water = POOL.instantiate() as WaterBody
	_water.size = Vector2i(192, 64)
	_water.position = Vector2(2000 * _placed, 300)
	add_child(_water)
	auto_free(_water)

func _hazard_runs() -> int:
	var runs := 0
	for child: Node in _water.get_node("Hazard").get_children():
		if child.name.begins_with("Run"):
			runs += 1
	return runs

func test_columns_in_the_disc_are_dry_and_the_rest_are_not() -> void:
	var left := _water.global_position.x - 96.0
	_water.hold_out(self, Vector2(left, 300), 40.0)
	assert_bool(_water.is_held_out(left + 8.0)).is_true()
	assert_bool(_water.is_held_out(left + 150.0)).is_false()

func test_the_hazard_covers_only_the_wet_columns() -> void:
	_water.hold_out(self, Vector2(_water.global_position.x, 300), 40.0)
	assert_int(_hazard_runs()).is_equal(2)

func test_a_level_moving_under_a_still_shell_asks_again() -> void:
	var water := _water
	var left := water.global_position.x - 96.0
	# Held out at the painted level; then the water sinks below the disc.
	water.hold_out(self, Vector2(left, 300), 20.0)
	assert_bool(water.is_held_out(left + 8.0)).is_true()
	water.set_level(340.0)
	assert_bool(water.is_held_out(left + 8.0)).is_false()

func test_letting_go_gives_the_water_back() -> void:
	var left := _water.global_position.x - 96.0
	_water.hold_out(self, Vector2(left, 300), 40.0)
	_water.release(self)
	assert_bool(_water.is_held_out(left + 8.0)).is_false()
	assert_int(_hazard_runs()).is_equal(0)
