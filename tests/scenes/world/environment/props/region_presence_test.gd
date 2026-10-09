class_name RegionPresenceTest extends GdUnitTestSuite

## A prop is shown at and above its minimum region baseline and hidden below it.


func test_shown_at_and_above_the_threshold() -> void:
	assert_bool(RegionPresence.shown(0.7, 0.7)).is_true()
	assert_bool(RegionPresence.shown(0.8, 0.7)).is_true()
	assert_bool(RegionPresence.shown(0.6, 0.7)).is_false()
	assert_bool(RegionPresence.shown(0.0, 0.0)).is_true()

func test_apply_toggles_the_parent() -> void:
	var parent := auto_free(Sprite2D.new()) as Sprite2D
	var presence := RegionPresence.new()
	presence.min_baseline = 0.7
	parent.add_child(presence)
	add_child(parent)
	presence.apply(0.6)
	assert_bool(parent.visible).is_false()
	presence.apply(1.0)
	assert_bool(parent.visible).is_true()
