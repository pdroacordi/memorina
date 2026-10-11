class_name HelixMathTest extends GdUnitTestSuite

## The rider's path: on the axis, rising linearly, with the front tread passing under the feet at his run speed.

const SHAPE := preload("res://resources/world/helix/bell_tower_helix.tres")
const EPSILON := 0.001
## Ivo's run speed, px/s.
const SPEED := 192.0


func test_the_feet_stay_on_the_axis() -> void:
	for n: int in 50:
		assert_float(HelixMath.feet(SHAPE, HelixMath.head_u(SHAPE) * n / 50.0).x).is_equal(0.0)

func test_the_feet_rise_linearly_to_the_head() -> void:
	for n: int in 50:
		var u := HelixMath.head_u(SHAPE) * n / 50.0
		assert_float(HelixMath.feet(SHAPE, u).y).is_equal_approx(-SHAPE.pitch * u / TAU, EPSILON)
	assert_float(HelixMath.feet(SHAPE, HelixMath.head_u(SHAPE)).y).is_equal_approx(-1120.0, EPSILON)

func test_the_front_tread_passes_under_the_feet_at_the_run_speed() -> void:
	var omega := HelixMath.angular_speed(SHAPE, SPEED)
	var dt := 0.0001
	for phi: float in [0.0, 2.0, 9.0]:
		var theta := phi
		var before := HelixProjection.project_polar(SHAPE, 1, theta, SHAPE.walk_radius, 0.0, phi, 0.0)
		var after := HelixProjection.project_polar(SHAPE, 1, theta, SHAPE.walk_radius, 0.0, phi + omega * dt, 0.0)
		assert_float(absf(after.x - before.x) / dt).is_equal_approx(SPEED * SHAPE.speed_scale, 0.1)

func test_speed_scale_scales_the_turn() -> void:
	var shape := SHAPE.duplicate() as HelixStairShape
	shape.speed_scale = 1.5
	assert_float(HelixMath.angular_speed(shape, SPEED)).is_equal_approx(HelixMath.angular_speed(SHAPE, SPEED) * 1.5, EPSILON)

func test_steps_tile_the_stair_a_riser_apart() -> void:
	assert_int(HelixMath.step_at(SHAPE, 0.0)).is_equal(0)
	assert_int(HelixMath.step_at(SHAPE, HelixMath.head_u(SHAPE))).is_equal(SHAPE.step_count() - 1)
	assert_float(HelixMath.tread_rise(SHAPE, 3) - HelixMath.tread_rise(SHAPE, 2)).is_equal_approx(SHAPE.riser(), EPSILON)
	assert_float(SHAPE.riser()).is_equal(10.0)

## "ivo while running doesn't touch the ground" (user, 2026-10-11): the feet stand on the tread under the axis.
func test_the_feet_stand_on_the_tread_top_under_the_axis_at_every_u() -> void:
	var samples := 4000
	for n: int in range(1, samples):
		var u := HelixMath.head_u(SHAPE) * n / samples
		# The step under the axis spans the tower angle at the front, which is u while he rides.
		var under := floori(u / (TAU / SHAPE.steps_per_turn))
		var tread := HelixProjection.project(SHAPE, Vector3(0.0, -HelixMath.tread_rise(SHAPE, under), SHAPE.walk_radius), -600.0)
		assert_float(HelixMath.stand(SHAPE, u).y).is_equal_approx(tread.y, 0.5)

func test_the_feet_stand_on_the_floor_at_the_foot_and_the_gallery_at_the_head() -> void:
	assert_float(HelixMath.stand(SHAPE, 0.0).y).is_equal(0.0)
	assert_float(HelixMath.stand(SHAPE, HelixMath.head_u(SHAPE)).y).is_equal(-1120.0)

func test_each_riser_is_climbed_at_once_and_never_more_than_one() -> void:
	var last := HelixMath.stand(SHAPE, 0.001).y
	for n: int in range(1, 2000):
		var y := HelixMath.stand(SHAPE, HelixMath.head_u(SHAPE) * n / 2000.0).y
		assert_float(last - y).is_less_equal(SHAPE.riser() + 0.001)
		assert_float(last - y).is_greater_equal(-0.001)
		last = y
