class_name GaleShapeTest extends GdUnitTestSuite

## Vendaval blows outward, still in an eye around the player, strongest a
## little way out and gone at the pulse's clean edge.

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

func test_it_blows_away_from_the_origin() -> void:
	var right := GaleShape.wind(Vector2(100, 0), Vector2(300, 0), 600.0, 48.0, 260.0)
	var left := GaleShape.wind(Vector2(100, 0), Vector2(-100, 0), 600.0, 48.0, 260.0)
	assert_float(right.x).is_greater(0.0)
	assert_float(left.x).is_less(0.0)
	assert_float(right.y).is_equal(0.0)

func test_it_blows_across_the_ground_more_than_up() -> void:
	var up := GaleShape.wind(Vector2.ZERO, Vector2(200, -200), 600.0, 48.0, 260.0)
	assert_float(absf(up.y)).is_less(absf(up.x))

func test_a_pulse_smaller_than_its_eye_is_still() -> void:
	assert_float(GaleShape.strength(20.0, 40.0, 48.0)).is_equal(0.0)
