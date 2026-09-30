class_name PulseStretchTest extends GdUnitTestSuite

## Solstice stretches a pulse once, while it still opens or holds: farther,
## longer, grown into rather than jumped to.

func _timeline() -> PulseTimeline:
	var stats := PulseStats.new()
	stats.max_radius = 100.0
	stats.attack_time = 1.0
	stats.sustain_time = 4.0
	stats.contract_time = 2.0
	return PulseTimeline.new(stats, 1.0)

func test_a_stretch_reaches_farther_and_holds_longer() -> void:
	var timeline := _timeline()
	timeline.advance(2.0)
	var before := timeline.total_time()
	assert_bool(timeline.stretch(1.5, 2.0)).is_true()
	assert_float(timeline.total_time()).is_equal_approx(before + 4.0, 0.001)
	timeline.advance(PulseTimeline.GROW_TIME + 0.1)
	assert_float(timeline.radius()).is_equal_approx(150.0, 0.001)

func test_it_grows_into_the_new_reach() -> void:
	var timeline := _timeline()
	timeline.advance(2.0)
	timeline.stretch(1.5, 2.0)
	timeline.advance(PulseTimeline.GROW_TIME * 0.5)
	assert_float(timeline.radius()).is_between(100.0, 150.0)

func test_only_once() -> void:
	var timeline := _timeline()
	timeline.advance(2.0)
	timeline.stretch(1.5, 2.0)
	assert_bool(timeline.stretch(1.5, 2.0)).is_false()

func test_never_once_the_grey_is_taking_it_back() -> void:
	var timeline := _timeline()
	timeline.advance(5.5)
	assert_bool(timeline.stretch(1.5, 2.0)).is_false()
