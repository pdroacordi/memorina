class_name SideTrackerTest extends GdUnitTestSuite

## The side holds inside TURN_BAND and turns outside it.

func test_it_holds_inside_the_band() -> void:
	var tracker := SideTracker.new()
	assert_float(tracker.update(-30.0)).is_equal(-1.0)
	for dx: float in [2.0, -2.0, 9.0, SideTracker.TURN_BAND]:
		assert_float(tracker.update(dx)).is_equal(-1.0)

func test_it_turns_outside_the_band() -> void:
	var tracker := SideTracker.new()
	assert_float(tracker.update(-SideTracker.TURN_BAND - 0.5)).is_equal(-1.0)
	assert_float(tracker.update(SideTracker.TURN_BAND + 0.5)).is_equal(1.0)

func test_it_starts_facing_east() -> void:
	assert_float(SideTracker.new().update(0.0)).is_equal(1.0)
