class_name GaleShapeTest extends GdUnitTestSuite

## Verifies the gale's directional wind profile and zero-strength boundaries.

func test_the_eye_is_still() -> void:
	assert_float(GaleShape.strength(30.0, 600.0, 48.0)).is_equal(0.0)

func test_nothing_blows_past_the_edge() -> void:
	assert_float(GaleShape.strength(600.0, 600.0, 48.0)).is_equal(0.0)
	assert_float(GaleShape.strength(700.0, 600.0, 48.0)).is_equal(0.0)

func test_it_peaks_a_little_way_out() -> void:
	var peak := 48.0 + (600.0 - 48.0) * GaleShape.PEAK_AT
	assert_float(GaleShape.strength(peak, 600.0, 48.0)).is_equal_approx(1.0, 0.001)
	assert_float(GaleShape.strength(peak * 0.6, 600.0, 48.0)).is_less(1.0)
	assert_float(GaleShape.strength(500.0, 600.0, 48.0)).is_less(1.0)

func test_it_blows_the_way_it_faces_on_both_sides() -> void:
	var ahead := GaleShape.wind(Vector2(100, 0), Vector2(300, 0), 600.0, 48.0, 260.0, 1.0)
	var behind := GaleShape.wind(Vector2(100, 0), Vector2(-100, 0), 600.0, 48.0, 260.0, 1.0)
	assert_float(ahead.x).is_greater(0.0)
	assert_float(behind.x).is_greater(0.0)
	var left := GaleShape.wind(Vector2(100, 0), Vector2(300, 0), 600.0, 48.0, 260.0, -1.0)
	assert_float(left.x).is_less(0.0)

func test_it_blows_along_the_ground_never_up() -> void:
	var above := GaleShape.wind(Vector2.ZERO, Vector2(200, -200), 600.0, 48.0, 260.0, 1.0)
	assert_float(above.y).is_equal(0.0)
	assert_float(above.x).is_greater(0.0)

func test_a_pulse_smaller_than_its_eye_is_still() -> void:
	assert_float(GaleShape.strength(20.0, 40.0, 48.0)).is_equal(0.0)
