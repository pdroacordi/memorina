class_name RootGrowerTest extends GdUnitTestSuite

## Wet earth lets a bridge reach farther (design 02 section 7.4, Chuva then Enraizar).

func test_a_dry_bridge_crosses_up_to_its_limit() -> void:
	assert_bool(RootGrower.may_bridge(10, 10, 14, false)).is_true()
	assert_bool(RootGrower.may_bridge(11, 10, 14, false)).is_false()

func test_a_wet_bridge_crosses_up_to_the_wet_limit() -> void:
	assert_bool(RootGrower.may_bridge(12, 10, 14, true)).is_true()
	assert_bool(RootGrower.may_bridge(14, 10, 14, true)).is_true()
	assert_bool(RootGrower.may_bridge(15, 10, 14, true)).is_false()
