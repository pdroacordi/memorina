class_name LocomotionWindTest extends GdUnitTestSuite

## Wind is a velocity the air carries. Feet on the ground ignore a breeze
## (so a standing performance survives it) and slide in a gust.

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
