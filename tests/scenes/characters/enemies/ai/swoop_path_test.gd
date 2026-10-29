class_name SwoopPathTest extends GdUnitTestSuite

## A swoop starts at its start, passes its target at the midpoint and ends at the start's mirror, in a time set by its speed.

const START := Vector2(100.0, 50.0)
const TARGET := Vector2(160.0, 130.0)
const SPEED := 200.0


func test_it_starts_at_the_start_and_passes_the_target_at_the_midpoint() -> void:
	var path := SwoopPath.new(START, TARGET, SPEED)
	assert_vector(path.point_at(0.0)).is_equal_approx(START, Vector2.ONE * 0.01)
	assert_vector(path.point_at(path.duration * 0.5)).is_equal_approx(TARGET, Vector2.ONE * 0.01)

func test_it_ends_at_the_mirror_point_at_the_start_height() -> void:
	var path := SwoopPath.new(START, TARGET, SPEED)
	assert_vector(path.end()).is_equal(Vector2(220.0, 50.0))
	assert_vector(path.point_at(path.duration)).is_equal_approx(path.end(), Vector2.ONE * 0.01)
	assert_vector(path.point_at(path.duration + 1.0)).is_equal_approx(path.end(), Vector2.ONE * 0.01)
	assert_bool(path.is_done(path.duration)).is_true()
	assert_bool(path.is_done(path.duration * 0.9)).is_false()

func test_its_duration_is_twice_the_dive_over_the_speed() -> void:
	var path := SwoopPath.new(START, TARGET, SPEED)
	assert_float(path.duration).is_equal_approx(2.0 * START.distance_to(TARGET) / SPEED, 0.0001)
	assert_float(SwoopPath.new(START, START, SPEED).duration).is_equal(SwoopPath.MIN_DURATION)

func test_its_velocity_is_the_derivative_of_its_position() -> void:
	var path := SwoopPath.new(START, TARGET, SPEED)
	var h := 0.001
	for u: float in [0.1, 0.4, 0.5, 0.8]:
		var t := u * path.duration
		var numeric := (path.point_at(t + h) - path.point_at(t - h)) / (2.0 * h)
		assert_vector(path.velocity_at(t)).is_equal_approx(numeric, Vector2.ONE * 0.5)
	assert_vector(path.velocity_at(path.duration * 0.5)).is_equal_approx(Vector2((220.0 - 100.0) / path.duration, 0.0), Vector2.ONE * 0.01)
	assert_vector(path.velocity_at(path.duration + 0.1)).is_equal(Vector2.ZERO)
