class_name ArriveMathTest extends GdUnitTestSuite

## A scripted walk never overshoots its mark by more than a pixel, for Ivo's and the actors' locomotion, from any start, and
## ends within ArriveMath.SETTLE_PX for the teleport to close.

const IVO_STATS := preload("res://resources/characters/ivo/ivo_locomotion_stats.tres")
const DAUGHTER_STATS := preload("res://resources/characters/story/daughter_locomotion_stats.tres")
const STEP := 1.0 / 60.0


## The locomotion's ground update, stepped like the physics; returns the furthest px past the target and the end x.
func _walk(stats: LocomotionStats, from: float, target: float, pace: float) -> Vector2:
	var x := from
	var velocity := 0.0
	var past := 0.0
	var direction := signf(target - from)
	for i: int in 3000:
		if ArriveMath.arrived(x, target):
			return Vector2(past, x)
		var axis := ArriveMath.axis(x, target, velocity, pace, stats.deceleration, STEP)
		if is_zero_approx(axis):
			velocity = move_toward(velocity, 0.0, stats.deceleration * STEP)
		elif is_zero_approx(velocity) or signf(velocity) == signf(axis):
			velocity = move_toward(velocity, axis * stats.move_speed, stats.acceleration * STEP)
		else:
			velocity = move_toward(velocity, axis * stats.move_speed, stats.deceleration * STEP)
		x += velocity * STEP
		past = maxf(past, (x - target) * direction)
	return Vector2(INF, x)

func test_no_walk_overshoots_its_mark() -> void:
	for stats: LocomotionStats in [IVO_STATS, DAUGHTER_STATS]:
		for gap: float in [3.0, 7.0, 16.0, 33.0, 64.0, 121.0, 400.0]:
			for pace: float in [0.25, 0.5, 1.0]:
				for side: float in [-1.0, 1.0]:
					var walked := _walk(stats, 100.0, 100.0 + gap * side, pace)
					var label := "speed %d gap %d pace %.2f side %d" % [int(stats.move_speed), int(gap), pace, int(side)]
					assert_float(walked.x).override_failure_message(label).is_less_equal(1.0)
					assert_float(absf(walked.y - (100.0 + gap * side))).override_failure_message(label).is_less_equal(ArriveMath.SETTLE_PX)

func test_inside_the_settle_distance_it_has_arrived() -> void:
	assert_bool(ArriveMath.arrived(10.0, 11.5)).is_true()
	assert_float(ArriveMath.axis(10.0, 11.5, 0.0, 1.0, 1000.0, STEP)).is_equal(0.0)

func test_far_off_it_walks_at_its_pace_toward_the_mark() -> void:
	assert_float(ArriveMath.axis(0.0, -100.0, 0.0, 0.5, 1000.0, STEP)).is_equal(-0.5)
