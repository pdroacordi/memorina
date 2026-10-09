class_name AmbientMathTest extends GdUnitTestSuite

## The memory clock holds in the grey, stops below its threshold, resumes where it stopped, and gives
## each placed prop a stable phase of its own.


func test_memory_zero_never_advances() -> void:
	var time := 1.25
	for i: int in 10000:
		time = AmbientMath.advance(time, 0.016, 0.0, 0.2)
	assert_float(time).is_equal(1.25)

func test_memory_one_sums_the_deltas_and_above_one_is_clamped() -> void:
	assert_float(AmbientMath.advance(0.0, 0.5, 1.0, 0.2)).is_equal(0.5)
	assert_float(AmbientMath.advance(0.0, 0.5, 3.0, 0.2)).is_equal(0.5)

func test_below_the_threshold_it_stops_and_above_it_scales() -> void:
	assert_float(AmbientMath.advance(2.0, 1.0, 0.19, 0.2)).is_equal(2.0)
	assert_float(AmbientMath.advance(2.0, 1.0, 0.5, 0.2)).is_equal(2.5)

## 1.3 s remembered, 5 s forgotten, 0.7 s remembered shows the frame of 2.0 s remembered.
func test_it_resumes_where_it_stopped() -> void:
	var time := 0.0
	time = AmbientMath.advance(time, 1.3, 1.0, 0.2)
	time = AmbientMath.advance(time, 5.0, 0.0, 0.2)
	time = AmbientMath.advance(time, 0.7, 1.0, 0.2)
	var none := PackedInt32Array()
	assert_int(AmbientMath.frame_at(time, 6.0, 8, 0.0, none)).is_equal(AmbientMath.frame_at(2.0, 6.0, 8, 0.0, none))

func test_frames_wrap_follow_a_sequence_and_shift_by_phase() -> void:
	var none := PackedInt32Array()
	assert_int(AmbientMath.frame_at(0.0, 6.0, 4, 0.0, none)).is_equal(0)
	assert_int(AmbientMath.frame_at(1.0, 6.0, 4, 0.0, none)).is_equal(2)
	assert_int(AmbientMath.frame_at(0.0, 6.0, 4, 0.5, none)).is_equal(2)
	var ping_pong := PackedInt32Array([0, 1, 2, 1])
	assert_int(AmbientMath.frame_at(3.0 / 6.0, 6.0, 3, 0.0, ping_pong)).is_equal(1)
	assert_int(AmbientMath.frame_at(4.0 / 6.0, 6.0, 3, 0.0, ping_pong)).is_equal(0)
	assert_int(AmbientMath.frame_at(1.0, 6.0, 0, 0.0, none)).is_equal(0)

func test_the_phase_is_stable_in_range_and_differs_between_neighbours() -> void:
	var a := AmbientMath.phase_for(Vector2(320, 288))
	assert_float(a).is_equal(AmbientMath.phase_for(Vector2(320.3, 287.8)))
	assert_float(a).is_between(0.0, 1.0)
	assert_float(a).is_not_equal(AmbientMath.phase_for(Vector2(352, 288)))
