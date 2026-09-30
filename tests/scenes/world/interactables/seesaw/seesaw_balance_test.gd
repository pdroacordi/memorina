class_name SeesawBalanceTest extends GdUnitTestSuite

## A seesaw leans toward the heavier side, by mass times distance, up to its
## limit - the shadow on the low end lifts Ivo on the high one.

func test_balanced_loads_hold_it_level() -> void:
	var loads: Array[Vector2] = [Vector2(-60, 1.0), Vector2(60, 1.0)]
	assert_float(SeesawBalance.settle_angle(loads, 0.35, 24.0)).is_equal_approx(0.0, 0.0001)

func test_the_right_side_heavy_turns_it_down_on_the_right() -> void:
	var loads: Array[Vector2] = [Vector2(40, 1.0)]
	assert_float(SeesawBalance.settle_angle(loads, 0.35, 24.0)).is_equal_approx(deg_to_rad(14.0), 0.0001)

func test_distance_is_leverage() -> void:
	var near: Array[Vector2] = [Vector2(-70, 1.0), Vector2(30, 2.0)]
	assert_float(SeesawBalance.torque(near)).is_equal_approx(-10.0, 0.0001)

func test_it_stops_at_its_limit() -> void:
	var loads: Array[Vector2] = [Vector2(-70, 3.0)]
	assert_float(SeesawBalance.settle_angle(loads, 0.35, 24.0)).is_equal_approx(deg_to_rad(-24.0), 0.0001)
