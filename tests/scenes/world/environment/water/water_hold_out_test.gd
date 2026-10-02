class_name WaterHoldOutTest extends GdUnitTestSuite


const POOL := preload("res://scenes/world/environment/water/water_pool.tscn")
const LAKE := preload("res://scenes/world/environment/water/water_lake.tscn")

var _water: WaterBody
var _placed := 0

func before_test() -> void:
	_placed += 1
	_water = POOL.instantiate() as WaterBody
	_water.size = Vector2i(192, 64)
	_water.position = Vector2(2000 * _placed, 300)
	add_child(_water)
	auto_free(_water)

func _hazard_at(point: Vector2) -> bool:
	var hazard := _water.get_node("Hazard") as Area2D
	var base := hazard.get_node("Shape") as CollisionShape2D
	if not base.disabled:
		var rect := base.shape as RectangleShape2D
		return Rect2(base.global_position - rect.size * 0.5, rect.size).has_point(point)
	for child: Node in hazard.get_children():
		var outline := child as CollisionPolygon2D
		if outline and not outline.disabled and Geometry2D.is_point_in_polygon(hazard.to_local(point), outline.polygon):
			return true
	return false

func test_columns_in_the_disc_are_dry_and_the_rest_are_not() -> void:
	var left := _water.global_position.x - 96.0
	_water.hold_out(self, Vector2(left, 300), 40.0)
	assert_bool(_water.is_held_out(left + 8.0)).is_true()
	assert_bool(_water.is_held_out(left + 150.0)).is_false()

func test_the_hazard_follows_the_curve() -> void:
	var middle := _water.global_position.x
	_water.hold_out(self, Vector2(middle, 300), 40.0)
	# Collision outlines are refit deferred, so query them after an idle frame.
	await await_idle_frame()
	assert_bool(_hazard_at(Vector2(middle, 330))).is_false()
	assert_bool(_hazard_at(Vector2(middle + 30, 318))).is_false()
	assert_bool(_hazard_at(Vector2(middle, 350))).is_true()
	assert_bool(_hazard_at(Vector2(middle + 60, 310))).is_true()

func test_a_disc_under_the_surface_leaves_water_over_it() -> void:
	var middle := _water.global_position.x
	_water.hold_out(self, Vector2(middle, 335), 20.0)
	await await_idle_frame()
	assert_bool(_hazard_at(Vector2(middle, 335))).is_false()
	assert_bool(_hazard_at(Vector2(middle, 308))).is_true()
	assert_bool(_hazard_at(Vector2(middle, 360))).is_true()

func test_a_lake_is_never_held_out() -> void:
	var lake := LAKE.instantiate() as WaterBody
	lake.size = Vector2i(192, 64)
	lake.position = Vector2(-4000, 300)
	add_child(lake)
	auto_free(lake)
	lake.hold_out(self, Vector2(-4000, 300), 40.0)
	assert_bool(lake.is_held_out(-4000.0)).is_false()

func test_a_level_moving_under_a_still_shell_asks_again() -> void:
	var water := _water
	var left := water.global_position.x - 96.0
	water.hold_out(self, Vector2(left, 300), 20.0)
	assert_bool(water.is_held_out(left + 8.0)).is_true()
	water.set_level(340.0)
	assert_bool(water.is_held_out(left + 8.0)).is_false()

func test_letting_go_gives_the_water_back() -> void:
	var left := _water.global_position.x - 96.0
	_water.hold_out(self, Vector2(left, 300), 40.0)
	_water.release(self)
	assert_bool(_water.is_held_out(left + 8.0)).is_false()
	await await_idle_frame()
	assert_bool(_hazard_at(Vector2(left + 8.0, 330))).is_true()
