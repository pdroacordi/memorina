class_name CueTrackerTest extends GdUnitTestSuite

## CueTracker is pure logic, so these run with no scene tree and no audio.

func _tracker(cues: Array[float] = [1.0, 2.0, 3.0]) -> CueTracker:
	return CueTracker.new(PackedFloat32Array(cues))

func test_empty_cues_are_done_from_the_start() -> void:
	var tracker := _tracker([])
	assert_bool(tracker.is_done()).is_true()
	assert_array(tracker.advance(10.0)).is_empty()

func test_nothing_is_reported_before_the_first_cue() -> void:
	var tracker := _tracker()
	assert_array(tracker.advance(0.99)).is_empty()
	assert_bool(tracker.is_done()).is_false()

func test_crossing_one_cue_reports_it() -> void:
	assert_array(_tracker().advance(1.0)).is_equal([0])

func test_crossing_several_cues_at_once_reports_them_in_order() -> void:
	assert_array(_tracker().advance(2.5)).is_equal([0, 1])

func test_a_cue_is_reported_only_once() -> void:
	var tracker := _tracker()
	tracker.advance(1.5)
	assert_array(tracker.advance(1.6)).is_empty()
	assert_array(tracker.advance(2.0)).is_equal([1])

func test_moving_backwards_reports_nothing() -> void:
	var tracker := _tracker()
	tracker.advance(2.5)
	assert_array(tracker.advance(0.0)).is_empty()

func test_a_cue_at_zero_fires_at_position_zero() -> void:
	assert_array(_tracker([0.0, 1.0]).advance(0.0)).is_equal([0])

func test_is_done_once_the_last_cue_is_crossed() -> void:
	var tracker := _tracker()
	tracker.advance(3.0)
	assert_bool(tracker.is_done()).is_true()

func test_reset_reports_the_cues_again() -> void:
	var tracker := _tracker()
	tracker.advance(3.0)
	tracker.reset()
	assert_bool(tracker.is_done()).is_false()
	assert_array(tracker.advance(1.0)).is_equal([0])
