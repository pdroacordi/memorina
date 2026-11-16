class_name SfxMuffleMathTest extends GdUnitTestSuite

## The SfxWorld cutoff runs from 20 kHz at memory 1 to 1.2 kHz at 0 in even pitch steps, clamped; only full memory
## leaves the filter off.

func test_the_ends() -> void:
	assert_float(SfxMuffleMath.cutoff(1.0)).is_equal_approx(20000.0, 0.01)
	assert_float(SfxMuffleMath.cutoff(0.0)).is_equal_approx(1200.0, 0.01)

func test_out_of_range_memory_clamps() -> void:
	assert_float(SfxMuffleMath.cutoff(1.5)).is_equal_approx(20000.0, 0.01)
	assert_float(SfxMuffleMath.cutoff(-0.5)).is_equal_approx(1200.0, 0.01)

## Equal memory steps divide the cutoff by the same ratio: the midpoint is the geometric mean.
func test_even_steps_in_pitch() -> void:
	assert_float(SfxMuffleMath.cutoff(0.5)).is_equal_approx(sqrt(20000.0 * 1200.0), 0.5)
	var ratio := SfxMuffleMath.cutoff(0.9) / SfxMuffleMath.cutoff(0.8)
	assert_float(SfxMuffleMath.cutoff(0.3) / SfxMuffleMath.cutoff(0.2)).is_equal_approx(ratio, 0.0001)

func test_it_falls_as_memory_falls() -> void:
	var last := SfxMuffleMath.cutoff(1.0)
	for i: int in range(9, -1, -1):
		var now := SfxMuffleMath.cutoff(i / 10.0)
		assert_float(now).is_less(last)
		last = now

func test_only_full_memory_is_open() -> void:
	assert_bool(SfxMuffleMath.is_open(1.0)).is_true()
	assert_bool(SfxMuffleMath.is_open(0.999)).is_false()
	assert_bool(SfxMuffleMath.is_open(0.0)).is_false()
