class_name FinaleFightTest extends GdUnitTestSuite

## Winter windows until one is answered, the revelation exactly once (and never again once the save holds it),
## two-track windows after, and the spring's stage once both are past;
## a window's first mixed input is a warning, then the veil, the drain and the damage table; a chosen track runs the
## final call phrase by phrase (design 02 section 5; architecture/grd-06-final-battle).


func _stats() -> FinaleStats:
	var stats := FinaleStats.new()
	stats.winter_cycles = 1
	stats.final_phrases = [Song.new(), Song.new()]
	return stats

func test_winter_then_the_revelation_once_then_two_tracks() -> void:
	var fight := FinaleFight.new(_stats())
	assert_int(fight.open_window(0)).is_equal(FinaleFight.Stage.WINTER)
	assert_int(fight.open_window(1)).is_equal(FinaleFight.Stage.REVELATION)
	fight.reveal()
	assert_int(fight.open_window(1)).is_equal(FinaleFight.Stage.DUAL)
	assert_int(fight.open_window(1)).is_equal(FinaleFight.Stage.DUAL)

## The revelation comes only after a winter window was won (design 02 section 5.1): a failed one is winter again, so the
## final call is always the last cycle.
func test_a_failed_winter_window_is_winter_again() -> void:
	var fight := FinaleFight.new(_stats())
	assert_int(fight.open_window(0)).is_equal(FinaleFight.Stage.WINTER)
	assert_int(fight.open_window(0)).is_equal(FinaleFight.Stage.WINTER)
	assert_int(fight.open_window(1)).is_equal(FinaleFight.Stage.REVELATION)

func test_a_save_that_holds_the_revelation_skips_it() -> void:
	var fight := FinaleFight.new(_stats(), true)
	assert_int(fight.open_window(0)).is_equal(FinaleFight.Stage.WINTER)
	assert_int(fight.open_window(1)).is_equal(FinaleFight.Stage.DUAL)

## The spring joins the pressure as one more stage once the revelation is seen and the winter answered, in this attempt
## or a later one; before either it is winter.
func test_the_revelation_is_a_stage_after_the_winter_answer() -> void:
	var fresh := FinaleFight.new(_stats())
	assert_int(fresh.extra_stages(0)).is_equal(0)
	assert_int(fresh.extra_stages(1)).is_equal(0)
	fresh.reveal()
	assert_int(fresh.extra_stages(1)).is_equal(1)
	var returning := FinaleFight.new(_stats(), true)
	assert_int(returning.extra_stages(0)).is_equal(0)
	assert_int(returning.extra_stages(1)).is_equal(1)

func test_the_first_mixed_input_warns_then_the_cost_grows() -> void:
	var fight := FinaleFight.new(_stats(), true)
	fight.open_window(0)
	fight.open_window(1)
	assert_int(fight.mix()).is_equal(0)
	assert_float(fight.veil()).is_equal(0.0)
	assert_float(fight.drain()).is_equal_approx(1.6, 0.001)
	assert_int(fight.mix()).is_equal(1)
	assert_float(fight.veil()).is_equal_approx(0.35, 0.001)
	assert_int(fight.mix()).is_equal(1)
	assert_int(fight.mix()).is_equal(2)
	assert_int(fight.mix()).is_equal(2)
	assert_float(fight.veil()).is_equal(1.0)

func test_a_new_window_starts_with_a_warning_again() -> void:
	var fight := FinaleFight.new(_stats(), true)
	fight.open_window(1)
	fight.mix()
	fight.mix()
	fight.open_window(1)
	assert_int(fight.mix()).is_equal(0)
	assert_float(fight.drain()).is_equal_approx(1.6, 0.001)

func test_a_chosen_track_runs_the_final_call_phrase_by_phrase() -> void:
	var stats := _stats()
	var fight := FinaleFight.new(stats, true)
	fight.open_window(1)
	fight.mix()
	fight.mix()
	fight.choose()
	assert_int(fight.stage()).is_equal(FinaleFight.Stage.FINAL)
	assert_float(fight.veil()).is_equal(0.0)
	assert_object(fight.phrase()).is_same(stats.final_phrases[0])
	assert_bool(fight.advance_phrase()).is_false()
	assert_object(fight.phrase()).is_same(stats.final_phrases[1])
	assert_bool(fight.advance_phrase()).is_true()
	assert_object(fight.phrase()).is_null()
