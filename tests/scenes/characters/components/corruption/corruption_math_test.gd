class_name CorruptionMathTest extends GdUnitTestSuite

## The fray rises as health falls and stays in 0..1; a hit's spike fades to nothing.

func test_fray_runs_from_rest_at_full_health_to_hurt_at_none() -> void:
	assert_float(CorruptionMath.fray(0.15, 0.55, 4, 4)).is_equal_approx(0.15, 0.0001)
	assert_float(CorruptionMath.fray(0.15, 0.55, 2, 4)).is_equal_approx(0.35, 0.0001)
	assert_float(CorruptionMath.fray(0.15, 0.55, 0, 4)).is_equal_approx(0.55, 0.0001)

func test_fray_rises_as_health_falls() -> void:
	var last := -1.0
	for hp: int in range(8, -1, -1):
		var fray := CorruptionMath.fray(0.1, 0.9, hp, 8)
		assert_float(fray).is_greater(last)
		last = fray

func test_fray_is_clamped() -> void:
	assert_float(CorruptionMath.fray(-0.5, 2.0, 0, 3)).is_equal(1.0)
	assert_float(CorruptionMath.fray(-0.5, 2.0, 3, 3)).is_equal(0.0)
	assert_float(CorruptionMath.fray(0.2, 0.6, 9, 3)).is_equal_approx(0.2, 0.0001)
	assert_float(CorruptionMath.fray(0.2, 0.6, 1, 0)).is_equal_approx(0.2, 0.0001)

func test_spike_falls_linearly_to_zero() -> void:
	assert_float(CorruptionMath.spike(0.4, 0.3, 0.3)).is_equal_approx(0.4, 0.0001)
	assert_float(CorruptionMath.spike(0.4, 0.15, 0.3)).is_equal_approx(0.2, 0.0001)
	assert_float(CorruptionMath.spike(0.4, 0.0, 0.3)).is_equal(0.0)
	assert_float(CorruptionMath.spike(0.4, 0.2, 0.0)).is_equal(0.0)
