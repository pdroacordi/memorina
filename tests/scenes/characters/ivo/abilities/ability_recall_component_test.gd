class_name AbilityRecallComponentTest extends GdUnitTestSuite

## The component is driven by pushed-in stats, action names and real
## seconds, so it tests without input, a save file or a time scale.

var _recall: AbilityRecallComponent
var _roll: AbilityRecallStats
## The double jump: two presses from the ground, the last one off it.
var _double_jump: AbilityRecallStats

func before_test() -> void:
	_roll = AbilityRecallStats.new()
	_roll.skill = Enums.PlayerSkill.ROLL
	_roll.action = &"roll"
	_roll.window = 1.0
	_double_jump = AbilityRecallStats.new()
	_double_jump.skill = Enums.PlayerSkill.DOUBLE_JUMP
	_double_jump.action = &"jump"
	_double_jump.window = 1.0
	_double_jump.grounded_steps = 2
	_double_jump.airborne_finish = true
	_double_jump.step_window = 2.0
	_recall = auto_free(AbilityRecallComponent.new())

func test_it_starts_unarmed() -> void:
	assert_bool(_recall.is_armed()).is_false()

func test_arming_opens_the_window() -> void:
	assert_bool(_recall.arm(_roll)).is_true()
	assert_bool(_recall.is_armed()).is_true()
	assert_object(_recall.armed_stats()).is_same(_roll)

func test_arming_twice_keeps_the_first_window() -> void:
	_recall.arm(_roll)
	var other := AbilityRecallStats.new()
	other.skill = Enums.PlayerSkill.DOUBLE_JUMP
	assert_bool(_recall.arm(other)).is_false()
	assert_object(_recall.armed_stats()).is_same(_roll)

func test_the_right_action_recalls_the_skill() -> void:
	_recall.arm(_roll)
	var monitor := monitor_signals(_recall)
	assert_bool(_recall.notify(&"roll")).is_true()
	await assert_signal(monitor).is_emitted("recalled", [_roll])
	assert_bool(_recall.is_armed()).is_false()

func test_the_wrong_action_is_ignored() -> void:
	_recall.arm(_roll)
	var monitor := monitor_signals(_recall)
	assert_bool(_recall.notify(&"jump")).is_false()
	await assert_signal(monitor).is_not_emitted("recalled")
	assert_bool(_recall.is_armed()).is_true()

func test_actions_while_unarmed_are_ignored() -> void:
	var monitor := monitor_signals(_recall)
	assert_bool(_recall.notify(&"roll")).is_false()
	await assert_signal(monitor).is_not_emitted("recalled")

func test_an_expired_window_is_a_miss() -> void:
	_recall.arm(_roll)
	var monitor := monitor_signals(_recall)
	_recall.tick(0.5)
	await assert_signal(monitor).is_not_emitted("missed")
	_recall.tick(0.6)
	await assert_signal(monitor).is_emitted("missed", [_roll])
	assert_bool(_recall.is_armed()).is_false()

func test_a_press_after_the_window_does_nothing() -> void:
	_recall.arm(_roll)
	_recall.tick(2.0)
	var monitor := monitor_signals(_recall)
	assert_bool(_recall.notify(&"roll")).is_false()
	await assert_signal(monitor).is_not_emitted("recalled")

func test_ticking_while_unarmed_does_nothing() -> void:
	var monitor := monitor_signals(_recall)
	_recall.tick(10.0)
	await assert_signal(monitor).is_not_emitted("missed")

## The owner died: the window is dropped without a verdict either way.
func test_cancelling_drops_the_window_silently() -> void:
	_recall.arm(_roll)
	var monitor := monitor_signals(_recall)
	assert_bool(_recall.cancel()).is_true()
	assert_bool(_recall.is_armed()).is_false()
	_recall.tick(5.0)
	await assert_signal(monitor).is_not_emitted("missed")
	await assert_signal(monitor).is_not_emitted("recalled")

func test_cancelling_while_unarmed_reports_nothing_to_drop() -> void:
	assert_bool(_recall.cancel()).is_false()

#############################################
##  A   M E M O R Y   I N   T W O   P R E S S E S
#############################################

func test_a_chained_memory_asks_for_every_press_from_the_ground() -> void:
	_recall.arm(_double_jump, true)
	assert_int(_recall.steps_left()).is_equal(2)

func test_the_same_memory_caught_airborne_asks_for_one() -> void:
	_recall.arm(_double_jump, false)
	assert_int(_recall.steps_left()).is_equal(1)

func test_the_first_press_of_a_chain_is_a_step_not_the_skill() -> void:
	_recall.arm(_double_jump, true)
	var monitor := monitor_signals(_recall)
	assert_bool(_recall.notify(&"jump", false)).is_true()
	await assert_signal(monitor).is_emitted("step_taken", [1, 2.0])
	await assert_signal(monitor).is_not_emitted("recalled")
	assert_bool(_recall.is_armed()).is_true()
	assert_int(_recall.steps_left()).is_equal(1)

func test_the_last_press_of_a_chain_recalls_the_skill() -> void:
	_recall.arm(_double_jump, true)
	_recall.notify(&"jump", false)
	var monitor := monitor_signals(_recall)
	assert_bool(_recall.notify(&"jump", true)).is_true()
	await assert_signal(monitor).is_emitted("recalled", [_double_jump])
	assert_bool(_recall.is_armed()).is_false()

## The ordinary jump the press also performs is what earns the last step.
func test_the_last_press_does_not_count_with_the_feet_down() -> void:
	_recall.arm(_double_jump, false)
	var monitor := monitor_signals(_recall)
	assert_bool(_recall.notify(&"jump", false)).is_false()
	await assert_signal(monitor).is_not_emitted("recalled")
	assert_bool(_recall.is_armed()).is_true()

func test_a_step_puts_its_own_seconds_back_on_the_clock() -> void:
	_recall.arm(_double_jump, true)
	_recall.tick(0.9)
	_recall.notify(&"jump", false)
	var monitor := monitor_signals(_recall)
	# The first window had 0.1s left; the step bought a fresh 2.0s.
	_recall.tick(1.5)
	await assert_signal(monitor).is_not_emitted("missed")
	_recall.tick(0.6)
	await assert_signal(monitor).is_emitted("missed", [_double_jump])

func test_a_chain_that_runs_out_mid_way_is_a_miss() -> void:
	_double_jump.step_window = 0.0
	_recall.arm(_double_jump, true)
	_recall.tick(0.9)
	_recall.notify(&"jump", false)
	var monitor := monitor_signals(_recall)
	_recall.tick(0.2)
	await assert_signal(monitor).is_emitted("missed", [_double_jump])

func test_an_unchained_memory_still_takes_one_press_from_the_ground() -> void:
	_recall.arm(_roll, true)
	assert_int(_recall.steps_left()).is_equal(1)
	var monitor := monitor_signals(_recall)
	assert_bool(_recall.notify(&"roll", false)).is_true()
	await assert_signal(monitor).is_emitted("recalled", [_roll])
