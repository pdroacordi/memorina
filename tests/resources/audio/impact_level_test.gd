class_name ImpactLevelTest extends GdUnitTestSuite

## An impact sounds QUIETEST at the slowest heard speed, rises linearly, and holds 0 dB from full speed.

func test_the_slowest_heard_impact_is_the_quietest() -> void:
	assert_float(ImpactLevel.db(200.0, 200.0, 800.0)).is_equal(ImpactLevel.QUIETEST)

func test_full_speed_and_over_is_0_db() -> void:
	assert_float(ImpactLevel.db(800.0, 200.0, 800.0)).is_equal(0.0)
	assert_float(ImpactLevel.db(2000.0, 200.0, 800.0)).is_equal(0.0)

func test_halfway_is_half_the_range() -> void:
	assert_float(ImpactLevel.db(500.0, 200.0, 800.0)).is_equal_approx(ImpactLevel.QUIETEST * 0.5, 0.001)

func test_under_the_slowest_speed_stays_quietest() -> void:
	assert_float(ImpactLevel.db(50.0, 200.0, 800.0)).is_equal(ImpactLevel.QUIETEST)

func test_an_empty_range_is_full_level() -> void:
	assert_float(ImpactLevel.db(300.0, 800.0, 800.0)).is_equal(0.0)
