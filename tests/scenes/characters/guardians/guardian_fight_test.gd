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
	_stats.extra_hits_per_failure = 2
	_stats.window_scale_per_failure = 0.5
	_stats.cooldown_scale_per_failure = 0.5
	_stats.max_aggression = 2
	_fight = GuardianFight.new(_stats)

func _hit_until_open() -> void:
	for i: int in _stats.hits_to_open + 10:
		if _fight.register_hit():
			return

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
	assert_int(_fight.phase()).is_equal(GuardianFight.Phase.PRESSURE)
	assert_int(_fight.aggression()).is_equal(1)

func test_a_good_answer_returns_to_pressure_until_the_last_cycle() -> void:
	_fight.begin()
	_hit_until_open()
	_fight.open_window()
	_fight.answer_succeeded()
	assert_int(_fight.phase()).is_equal(GuardianFight.Phase.PRESSURE)
	assert_float(_fight.lucidity()).is_equal_approx(0.5, 0.001)
	assert_int(_fight.aggression()).is_equal(0)

func test_the_last_good_answer_restores_the_guardian() -> void:
	_fight.begin()
	for cycle: int in _stats.cycles_to_restore:
		_hit_until_open()
		_fight.open_window()
		_fight.answer_succeeded()
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
	assert_int(_fight.aggression()).is_equal(_stats.max_aggression)

func test_the_next_window_needs_the_raised_threshold() -> void:
	_fight.begin()
	_hit_until_open()
	_fight.answer_failed()
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
