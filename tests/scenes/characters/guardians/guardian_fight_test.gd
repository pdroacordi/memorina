class_name GuardianFightTest extends GdUnitTestSuite

## GuardianFight is pure logic: no Node, no clock, no save file. Everything is
## driven through its methods and read back through its queries.

var _stats: GuardianStats
var _fight: GuardianFight

func before_test() -> void:
	_stats = GuardianStats.new()
	_stats.hits_to_open = 3
	_stats.cycles_to_restore = 2
	_stats.window = 4.0
	_stats.relapse_time = 1.0
	_stats.extra_hits_per_failure = 2
	_stats.window_scale_per_failure = 0.5
	_stats.cooldown_scale_per_failure = 0.5
	_stats.max_aggression = 2
	_fight = GuardianFight.new(_stats)

func _hit_until_open() -> void:
	for i: int in _stats.hits_to_open + 10:
		if _fight.register_hit():
			return

## Waits the relapse out, however long it was.
func _relapse_out() -> void:
	_fight.tick(_stats.relapse_time + 1.0)

func test_it_starts_dormant() -> void:
	assert_int(_fight.phase()).is_equal(GuardianFight.Phase.DORMANT)

func test_beginning_starts_the_pressure_phase() -> void:
	_fight.begin()
	assert_int(_fight.phase()).is_equal(GuardianFight.Phase.PRESSURE)

func test_hits_do_not_count_before_the_fight_begins() -> void:
	for i: int in 10:
		assert_bool(_fight.register_hit()).is_false()
	assert_int(_fight.phase()).is_equal(GuardianFight.Phase.DORMANT)

func test_enough_hits_open_a_lucidity_window() -> void:
	_fight.begin()
	assert_bool(_fight.register_hit()).is_false()
	assert_bool(_fight.register_hit()).is_false()
	assert_bool(_fight.register_hit()).is_true()
	assert_int(_fight.phase()).is_equal(GuardianFight.Phase.LUCIDITY)

func test_hits_during_lucidity_are_ignored() -> void:
	_fight.begin()
	_hit_until_open()
	assert_bool(_fight.register_hit()).is_false()
	assert_int(_fight.phase()).is_equal(GuardianFight.Phase.LUCIDITY)

func test_pressure_progress_climbs_with_the_hits() -> void:
	_fight.begin()
	assert_float(_fight.pressure_progress()).is_equal_approx(0.0, 0.001)
	_fight.register_hit()
	assert_float(_fight.pressure_progress()).is_equal_approx(1.0 / 3.0, 0.001)
	_fight.register_hit()
	assert_float(_fight.pressure_progress()).is_equal_approx(2.0 / 3.0, 0.001)

## The design's guarantee: the skill is always remembered inside the
## encounter, so no window opens while it is still pending.
func test_a_pending_recall_holds_the_window_shut() -> void:
	_fight.set_recall_pending(true)
	_fight.begin()
	for i: int in 10:
		assert_bool(_fight.register_hit()).is_false()
	assert_int(_fight.phase()).is_equal(GuardianFight.Phase.PRESSURE)
	assert_bool(_fight.is_saturated()).is_true()
	assert_float(_fight.pressure_progress()).is_equal_approx(1.0, 0.001)

func test_remembering_the_skill_opens_the_window_the_hits_were_waiting_on() -> void:
	_fight.set_recall_pending(true)
	_fight.begin()
	_hit_until_open()
	assert_bool(_fight.skill_recalled()).is_true()
	assert_int(_fight.phase()).is_equal(GuardianFight.Phase.LUCIDITY)
	assert_bool(_fight.recall_pending()).is_false()

func test_remembering_the_skill_early_only_lifts_the_gate() -> void:
	_fight.set_recall_pending(true)
	_fight.begin()
	_fight.register_hit()
	assert_bool(_fight.skill_recalled()).is_false()
	assert_int(_fight.phase()).is_equal(GuardianFight.Phase.PRESSURE)
	assert_bool(_fight.is_saturated()).is_false()
	assert_bool(_fight.register_hit()).is_false()
	assert_bool(_fight.register_hit()).is_true()

func test_nothing_is_gated_when_no_recall_is_pending() -> void:
	_fight.begin()
	assert_bool(_fight.is_saturated()).is_false()
	_hit_until_open()
	assert_int(_fight.phase()).is_equal(GuardianFight.Phase.LUCIDITY)

## The window only counts once the call has been heard.
func test_the_window_does_not_run_before_it_is_opened() -> void:
	_fight.begin()
	_hit_until_open()
	assert_bool(_fight.is_window_open()).is_false()
	assert_bool(_fight.tick(100.0)).is_false()
	assert_int(_fight.phase()).is_equal(GuardianFight.Phase.LUCIDITY)

func test_an_expired_window_fails_the_answer() -> void:
	_fight.begin()
	_hit_until_open()
	_fight.open_window()
	assert_bool(_fight.tick(3.9)).is_false()
	assert_bool(_fight.tick(0.2)).is_true()
	assert_int(_fight.phase()).is_equal(GuardianFight.Phase.RELAPSE)
	assert_bool(_fight.relapse_failed()).is_true()
	assert_int(_fight.aggression()).is_equal(1)

## The answer cannot be played faster than the call was sounded, so the
## phrase's own length is added to the slack.
func test_the_window_is_the_calls_length_plus_the_slack() -> void:
	_fight.begin()
	_hit_until_open()
	_fight.open_window(10.0)
	assert_float(_fight.window_left()).is_equal_approx(14.0, 0.001)
	assert_bool(_fight.tick(13.9)).is_false()
	assert_bool(_fight.tick(0.2)).is_true()

## The one clock. A meter asks for the fraction rather than counting its own
## seconds down, so it cannot drift from the deadline it is drawing.
func test_the_window_reports_the_fraction_it_has_left() -> void:
	_fight.begin()
	_hit_until_open()
	_fight.open_window(4.0)
	assert_float(_fight.window_fraction()).is_equal_approx(1.0, 0.001)
	_fight.tick(4.0)
	assert_float(_fight.window_fraction()).is_equal_approx(0.5, 0.001)
	_fight.tick(3.9)
	assert_float(_fight.window_fraction()).is_less(0.03)

## Nothing is draining when nothing is open, and an expired window reads
## empty rather than negative.
func test_the_fraction_is_zero_with_no_window_open() -> void:
	assert_float(_fight.window_fraction()).is_equal(0.0)
	_fight.begin()
	_hit_until_open()
	_fight.open_window()
	_fight.tick(5.0)
	assert_float(_fight.window_fraction()).is_equal(0.0)

func test_a_good_answer_relapses_until_the_last_cycle() -> void:
	_fight.begin()
	_hit_until_open()
	_fight.open_window()
	_fight.answer_succeeded()
	assert_int(_fight.phase()).is_equal(GuardianFight.Phase.RELAPSE)
	assert_bool(_fight.relapse_failed()).is_false()
	assert_float(_fight.relapse_duration()).is_equal_approx(1.0, 0.001)
	assert_float(_fight.lucidity()).is_equal_approx(0.5, 0.001)
	assert_int(_fight.aggression()).is_equal(0)

func test_the_relapse_ends_on_its_own() -> void:
	_fight.begin()
	_hit_until_open()
	_fight.answer_succeeded()
	assert_bool(_fight.tick(0.9)).is_false()
	assert_int(_fight.phase()).is_equal(GuardianFight.Phase.RELAPSE)
	assert_bool(_fight.tick(0.2)).is_false()
	assert_int(_fight.phase()).is_equal(GuardianFight.Phase.PRESSURE)

func test_hits_do_not_count_during_the_relapse() -> void:
	_fight.begin()
	_hit_until_open()
	_fight.answer_succeeded()
	for i: int in 10:
		assert_bool(_fight.register_hit()).is_false()
	assert_float(_fight.pressure_progress()).is_equal_approx(0.0, 0.001)

## A failure comes back sooner: the penalty is visible in the time it takes.
func test_a_failed_relapse_is_shorter() -> void:
	_fight.begin()
	_hit_until_open()
	_fight.answer_failed()
	assert_float(_fight.relapse_duration()).is_equal_approx(GuardianFight.FAILED_RELAPSE_SCALE, 0.001)
	assert_bool(_fight.tick(0.7)).is_false()
	assert_int(_fight.phase()).is_equal(GuardianFight.Phase.PRESSURE)

func test_a_relapse_of_no_length_is_immediate() -> void:
	_stats.relapse_time = 0.0
	_fight.begin()
	_hit_until_open()
	_fight.answer_failed()
	assert_int(_fight.phase()).is_equal(GuardianFight.Phase.PRESSURE)

func test_the_last_good_answer_restores_the_guardian() -> void:
	_fight.begin()
	for cycle: int in _stats.cycles_to_restore:
		_hit_until_open()
		_fight.open_window()
		_fight.answer_succeeded()
		_relapse_out()
	assert_int(_fight.phase()).is_equal(GuardianFight.Phase.RESTORED)
	assert_float(_fight.lucidity()).is_equal_approx(1.0, 0.001)

func test_a_restored_guardian_ignores_hits() -> void:
	_fight.restore_silently()
	assert_int(_fight.phase()).is_equal(GuardianFight.Phase.RESTORED)
	assert_bool(_fight.register_hit()).is_false()
	assert_float(_fight.lucidity()).is_equal_approx(1.0, 0.001)

## The design's penalty: not game over, a harder road back.
func test_failures_make_the_guardian_angrier() -> void:
	_fight.begin()
	assert_int(_fight.hits_to_open()).is_equal(3)
	assert_float(_fight.window_duration()).is_equal_approx(4.0, 0.001)
	assert_float(_fight.cooldown_scale()).is_equal_approx(1.0, 0.001)
	_hit_until_open()
	_fight.answer_failed()
	assert_int(_fight.hits_to_open()).is_equal(5)
	assert_float(_fight.window_duration()).is_equal_approx(2.0, 0.001)
	assert_float(_fight.cooldown_scale()).is_equal_approx(0.5, 0.001)

func test_aggression_is_capped() -> void:
	_fight.begin()
	for i: int in 5:
		_hit_until_open()
		_fight.answer_failed()
		_relapse_out()
	assert_int(_fight.aggression()).is_equal(_stats.max_aggression)

func test_the_next_window_needs_the_raised_threshold() -> void:
	_fight.begin()
	_hit_until_open()
	_fight.answer_failed()
	_relapse_out()
	for i: int in 4:
		assert_bool(_fight.register_hit()).is_false()
	assert_bool(_fight.register_hit()).is_true()

func test_answering_outside_a_window_does_nothing() -> void:
	_fight.begin()
	_fight.answer_succeeded()
	_fight.answer_failed()
	assert_int(_fight.phase()).is_equal(GuardianFight.Phase.PRESSURE)
	assert_int(_fight.aggression()).is_equal(0)
	assert_float(_fight.lucidity()).is_equal_approx(0.0, 0.001)

func test_phase_changes_are_announced() -> void:
	var monitor := monitor_signals(_fight)
	_fight.begin()
	await assert_signal(monitor).is_emitted("phase_changed", [GuardianFight.Phase.DORMANT, GuardianFight.Phase.PRESSURE])
