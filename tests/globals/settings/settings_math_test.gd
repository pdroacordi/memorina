class_name SettingsMathTest extends GdUnitTestSuite

## Volume steps to dB, the boot locale, and window scales that skip what the screen cannot hold.

const FULL_HD := Vector2i(1920, 1040)


func test_volume_db_is_zero_at_ten_about_minus_twelve_at_five_and_rises() -> void:
	assert_float(SettingsMath.volume_db(10)).is_equal_approx(0.0, 0.001)
	assert_float(SettingsMath.volume_db(5)).is_equal_approx(-12.04, 0.01)
	assert_float(SettingsMath.volume_db(0)).is_less_equal(-60.0)
	for step: int in range(1, 11):
		assert_float(SettingsMath.volume_db(step)).is_greater(SettingsMath.volume_db(step - 1))

func test_locale_for_maps_any_portuguese_to_pt_br_and_the_rest_to_english() -> void:
	for os_locale: String in ["pt_BR", "pt_PT", "pt", "PT_br"]:
		assert_str(SettingsMath.locale_for(os_locale)).is_equal("pt_BR")
	for os_locale: String in ["en_US", "fr_FR", ""]:
		assert_str(SettingsMath.locale_for(os_locale)).is_equal("en")

func test_window_size_is_the_viewport_times_the_scale() -> void:
	assert_vector(SettingsMath.window_size(1)).is_equal(Vector2i(640, 360))
	assert_vector(SettingsMath.window_size(3)).is_equal(Vector2i(1920, 1080))

## A 1080p screen's usable rect (less the taskbar) holds 2x but not 3x.
func test_step_scale_skips_sizes_over_the_usable_rect() -> void:
	assert_bool(SettingsMath.fits(2, FULL_HD)).is_true()
	assert_bool(SettingsMath.fits(3, FULL_HD)).is_false()
	assert_int(SettingsMath.step_scale(2, 1, FULL_HD)).is_equal(2)
	assert_int(SettingsMath.step_scale(2, -1, FULL_HD)).is_equal(1)
	assert_int(SettingsMath.step_scale(1, -1, FULL_HD)).is_equal(1)
	assert_int(SettingsMath.step_scale(1, 1, Vector2i(3840, 2100))).is_equal(2)
	assert_int(SettingsMath.step_scale(1, 1, Vector2i(800, 600))).is_equal(1)

func test_largest_fitting_falls_back_and_one_always_fits() -> void:
	assert_int(SettingsMath.largest_fitting(3, FULL_HD)).is_equal(2)
	assert_int(SettingsMath.largest_fitting(3, Vector2i(100, 100))).is_equal(1)
