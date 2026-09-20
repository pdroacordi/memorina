class_name AbilityRecallComponentTest extends GdUnitTestSuite

## The component is driven by pushed-in stats, action names and real
## seconds, so it tests without input, a save file or a time scale.

var _recall: AbilityRecallComponent
var _roll: AbilityRecallStats

func before_test() -> void:
	_roll = AbilityRecallStats.new()
	_roll.skill = Enums.PlayerSkill.ROLL
	_roll.action = &"roll"
	_roll.window = 1.0
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
