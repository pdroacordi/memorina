class_name WindProfileTest extends GdUnitTestSuite

func _profile() -> WindProfile:
	var profile := WindProfile.new()
	profile.calm_time = 2.0
	profile.rise_time = 1.0
	profile.gust_time = 1.0
	profile.fall_time = 1.0
	profile.calm_strength = 0.2
	return profile

func test_the_calm_holds_its_strength() -> void:
	assert_float(_profile().strength(1.0)).is_equal(0.2)

func test_the_gust_is_full() -> void:
	assert_float(_profile().strength(3.5)).is_equal(1.0)

func test_it_rises_and_falls_between() -> void:
	var profile := _profile()
	assert_float(profile.strength(2.5)).is_between(0.2, 1.0)
	assert_float(profile.strength(4.5)).is_between(0.2, 1.0)

func test_it_repeats() -> void:
	var profile := _profile()
	assert_float(profile.strength(3.5 + profile.period())).is_equal_approx(1.0, 0.0001)
