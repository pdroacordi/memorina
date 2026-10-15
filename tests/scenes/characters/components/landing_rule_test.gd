class_name LandingRuleTest extends GdUnitTestSuite

## A fall that would be hard is soft inside a soft-landing zone; outside one it stays hard (systems/rooms "Soft landing").

const HARD := 800.0


func test_a_fast_landing_outside_a_zone_is_hard() -> void:
	assert_bool(LandingRule.is_hard(1000.0, HARD, 0)).is_true()
	assert_bool(LandingRule.is_hard(HARD, HARD, 0)).is_true()

func test_a_slow_landing_is_never_hard() -> void:
	assert_bool(LandingRule.is_hard(HARD - 1.0, HARD, 0)).is_false()
	assert_bool(LandingRule.is_hard(0.0, HARD, 0)).is_false()

func test_a_fast_landing_inside_a_zone_is_soft() -> void:
	assert_bool(LandingRule.is_hard(1000.0, HARD, 1)).is_false()
	assert_bool(LandingRule.is_hard(1000.0, HARD, 2)).is_false()

func test_the_component_counts_overlapping_zones() -> void:
	var landing: LandingComponent = auto_free(LandingComponent.new())
	assert_bool(landing.in_soft_zone()).is_false()
	landing.enter_soft_zone()
	landing.enter_soft_zone()
	landing.exit_soft_zone()
	assert_bool(landing.in_soft_zone()).is_true()
	landing.exit_soft_zone()
	assert_bool(landing.in_soft_zone()).is_false()
	# An exit with no matching entry never goes negative, so the next entry still counts.
	landing.exit_soft_zone()
	landing.enter_soft_zone()
	assert_bool(landing.in_soft_zone()).is_true()
