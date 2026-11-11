class_name WeatherGustTest extends GdUnitTestSuite

## The gust clock: calm on restart, stopped by the grey, eased down in a fight and restarted after it, still at intensity
## 0, and signed by the region's direction.

const STEP := 1.0 / 60.0

func _profile() -> WeatherProfile:
	var gusts := WindProfile.new()
	gusts.calm_time = 2.0
	gusts.rise_time = 1.0
	gusts.gust_time = 2.0
	gusts.fall_time = 1.0
	gusts.calm_strength = 0.0
	var profile := WeatherProfile.new()
	profile.speed = 200.0
	profile.gusts = gusts
	profile.fight_scale = 0.1
	profile.fight_ease = 1.0
	return profile

## Steps `seconds` of physics frames.
func _run(gust: WeatherGust, seconds: float, memory: float = 1.0, fighting: bool = false) -> void:
	for i: int in roundi(seconds / STEP):
		gust.step(STEP, memory, fighting)

func test_a_restart_is_calm() -> void:
	var gust := WeatherGust.new(_profile())
	_run(gust, 3.5)
	assert_float(gust.strength()).is_equal(1.0)
	gust.restart()
	assert_float(gust.strength()).is_equal(0.0)
	assert_float(gust.air(1, 1.0)).is_equal(0.0)

func test_memory_zero_stops_the_clock() -> void:
	var gust := WeatherGust.new(_profile())
	_run(gust, 10.0, 0.0)
	assert_float(gust.strength()).is_equal(0.0)
	_run(gust, 3.5, 0.5)
	assert_float(gust.strength()).override_failure_message("half memory: half the profile time").is_equal(0.0)
	_run(gust, 3.5, 0.5)
	assert_float(gust.strength()).is_equal(1.0)

func test_a_fight_eases_to_its_scale_and_its_end_restarts() -> void:
	var gust := WeatherGust.new(_profile())
	_run(gust, 3.5)
	_run(gust, 0.5, 1.0, true)
	assert_float(gust.strength()).is_between(0.4, 0.6)
	_run(gust, 0.6, 1.0, true)
	assert_float(gust.strength()).is_equal_approx(0.1, 0.001)
	gust.step(STEP, 1.0, false)
	assert_float(gust.strength()).override_failure_message("the fight's end restarts in a calm").is_equal(0.0)
	_run(gust, 3.5)
	assert_float(gust.strength()).override_failure_message("the level is back to 1 by the gust").is_equal(1.0)

func test_intensity_zero_is_still_air() -> void:
	var gust := WeatherGust.new(_profile())
	_run(gust, 3.5)
	assert_float(gust.air(-1, 0.0)).is_equal(0.0)
	assert_float(gust.air(-1, 0.5)).is_equal_approx(-100.0, 0.001)

func test_the_sign_follows_the_direction() -> void:
	var gust := WeatherGust.new(_profile())
	_run(gust, 3.5)
	assert_float(gust.air(-1, 1.0)).is_equal_approx(-200.0, 0.001)
	assert_float(gust.air(1, 1.0)).is_equal_approx(200.0, 0.001)

func test_no_profile_is_no_air() -> void:
	var gust := WeatherGust.new(null)
	gust.step(1.0, 1.0, false)
	assert_float(gust.air(1, 1.0)).is_equal(0.0)
