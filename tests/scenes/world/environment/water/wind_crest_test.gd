class_name WindCrestTest extends GdUnitTestSuite

## The wind piles water against the downwind bank, at the memory over it (design 02 section 8.4, A Onda Parada).

const WIDTH := 1000.0

func _profile() -> WaterProfile:
	return WaterProfile.new()

func _crest(width := WIDTH) -> WindCrest:
	return WindCrest.new(_profile(), width)

func _run(crest: WindCrest, wind: float, rate: float, seconds: float) -> void:
	for i in roundi(seconds / 0.1):
		crest.step(0.1, wind, rate)

func test_without_wind_nothing_piles() -> void:
	var crest := _crest()
	_run(crest, 0.0, 1.0, 5.0)
	assert_float(crest.height()).is_equal(0.0)

func test_a_breeze_under_the_threshold_piles_nothing() -> void:
	var crest := _crest()
	_run(crest, _profile().crest_min_wind, 1.0, 5.0)
	assert_float(crest.height()).is_equal(0.0)

func test_a_full_wind_reaches_the_cap_in_the_rise_time() -> void:
	var crest := _crest()
	_run(crest, 300.0, 1.0, _profile().crest_rise_time)
	assert_float(crest.height()).is_equal_approx(crest.cap(), 0.01)

func test_it_builds_at_half_speed_at_half_memory() -> void:
	var crest := _crest()
	_run(crest, 300.0, 0.5, _profile().crest_rise_time * 0.5)
	assert_float(crest.height()).is_equal_approx(crest.cap() * 0.25, 0.5)

func test_in_the_grey_it_holds_bit_for_bit() -> void:
	var crest := _crest()
	_run(crest, 300.0, 1.0, 3.0)
	var held := crest.height()
	_run(crest, 0.0, 0.0, 5.0)
	assert_float(crest.height()).is_equal(held)

func test_it_settles_in_the_settle_time() -> void:
	var crest := _crest()
	_run(crest, 300.0, 1.0, _profile().crest_rise_time)
	_run(crest, 0.0, 1.0, _profile().crest_settle_time)
	assert_float(crest.height()).is_equal_approx(0.0, 0.01)

func test_it_piles_at_the_end_the_wind_blows_to() -> void:
	var right := _crest()
	var left := _crest()
	_run(right, 300.0, 1.0, 3.0)
	_run(left, -300.0, 1.0, 3.0)
	assert_float(right.height()).is_greater(0.0)
	assert_float(left.height()).is_less(0.0)
	assert_float(right.offset(99, 100, 10.0)).is_greater(right.offset(0, 100, 10.0))
	assert_float(left.offset(0, 100, 10.0)).is_greater(left.offset(99, 100, 10.0))

func test_a_narrow_pool_piles_less() -> void:
	assert_float(_crest(100.0).cap()).is_equal(100.0 * _profile().crest_per_fetch)
	assert_float(_crest(WIDTH).cap()).is_equal(_profile().crest_height)

func test_the_offset_is_a_wedge_ending_at_its_length() -> void:
	var crest := _crest()
	_run(crest, 300.0, 1.0, _profile().crest_rise_time)
	var length := _profile().crest_length
	var near := crest.offset(99, 100, 10.0)
	var mid := crest.offset(int(100 - length / 20.0), 100, 10.0)
	assert_float(near).is_greater(mid)
	assert_float(crest.offset(int(100 - length / 10.0) - 1, 100, 10.0)).is_equal(0.0)
	assert_float(mid).is_equal_approx(near * 0.5, crest.cap() * 0.05)

func test_a_turning_wind_passes_through_flat() -> void:
	var crest := _crest()
	_run(crest, 300.0, 1.0, 3.0)
	_run(crest, -300.0, 1.0, 6.0)
	assert_float(crest.height()).is_less(0.0)

func test_water_never_piles_over_its_bank() -> void:
	var crest := _crest()
	crest.set_banks(8.0, 300.0)
	_run(crest, -300.0, 1.0, _profile().crest_rise_time)
	assert_float(crest.height()).is_equal_approx(-8.0, 0.01)
	_run(crest, 300.0, 1.0, _profile().crest_rise_time * 2.0)
	assert_float(crest.height()).is_equal_approx(crest.cap(), 0.01)
