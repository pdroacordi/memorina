class_name LocomotionWindTest extends GdUnitTestSuite

## Wind affects grounded movement only above the gust threshold.

func _locomotion() -> LocomotionComponent:
	var locomotion: LocomotionComponent = auto_free(LocomotionComponent.new())
	locomotion.stats = LocomotionStats.new()
	locomotion.stats.wind_deadzone = 90.0
	locomotion.stats.wind_grip = 0.5
	return locomotion

func test_a_breeze_does_not_move_feet() -> void:
	assert_float(_locomotion().ground_drift(80.0)).is_equal(0.0)

func test_a_gust_slides_them_at_grip_of_the_excess() -> void:
	assert_float(_locomotion().ground_drift(190.0)).is_equal_approx(50.0, 0.001)
	assert_float(_locomotion().ground_drift(-190.0)).is_equal_approx(-50.0, 0.001)

## MEM-16: a headwind under the deadzone still slows the step, so the brace pose never runs at full speed.
func test_a_headwind_slows_the_step_up_to_the_deadzone() -> void:
	var locomotion := _locomotion()
	locomotion.stats.headwind_slow = 0.25
	assert_float(locomotion.headwind_factor(1.0, -45.0)).is_equal_approx(0.875, 0.001)
	assert_float(locomotion.headwind_factor(1.0, -90.0)).is_equal_approx(0.75, 0.001)
	assert_float(locomotion.headwind_factor(-1.0, 300.0)).is_equal_approx(0.75, 0.001)

func test_a_tailwind_or_standing_keeps_full_speed() -> void:
	var locomotion := _locomotion()
	assert_float(locomotion.headwind_factor(1.0, 60.0)).is_equal(1.0)
	assert_float(locomotion.headwind_factor(0.0, -60.0)).is_equal(1.0)
	assert_float(locomotion.headwind_factor(1.0, 0.0)).is_equal(1.0)
