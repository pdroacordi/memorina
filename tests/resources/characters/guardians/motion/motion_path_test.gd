class_name MotionPathTest extends GdUnitTestSuite

## A planned reposition by strike time (architecture/grd-12-guardian-fight-engine).


func test_a_segment_moves_from_the_previous_end_and_holds_before_and_after() -> void:
	var path := MotionPath.new(1.0).add(0.2, 0.6, Vector2(100.0, 0.0))
	assert_vector(path.at(0.0)).is_equal(Vector2.ZERO)
	assert_vector(path.at(0.4)).is_equal_approx(Vector2(50.0, 0.0), Vector2.ONE * 0.01)
	assert_vector(path.at(0.9)).is_equal(Vector2(100.0, 0.0))
	assert_float(path.end_time()).is_equal_approx(0.6, 0.0001)

func test_an_arc_rises_at_its_middle_and_owns_the_vertical_there() -> void:
	var path := MotionPath.new(1.0).add(0.0, 1.0, Vector2(80.0, 0.0), 50.0, true)
	assert_vector(path.at(0.5)).is_equal_approx(Vector2(40.0, -50.0), Vector2.ONE * 0.01)
	assert_bool(path.holds_vertical(0.5)).is_true()

func test_segments_are_clipped_to_the_strike() -> void:
	var path := MotionPath.new(0.5).add(0.2, 0.9, Vector2(100.0, 0.0))
	assert_float(path.end_time()).is_equal(0.5)
	assert_vector(path.at(0.5)).is_equal(Vector2(100.0, 0.0))

func test_a_blink_jumps_and_is_intangible_around_it() -> void:
	var path := MotionPath.new(1.0).blink(0.3, Vector2(-120.0, 0.0), 0.1)
	assert_vector(path.at(0.29)).is_equal(Vector2.ZERO)
	assert_vector(path.at(0.31)).is_equal(Vector2(-120.0, 0.0))
	assert_bool(path.is_intangible(0.25)).is_true()
	assert_bool(path.is_intangible(0.45)).is_false()
	assert_bool(path.holds_vertical(0.3)).is_false()
