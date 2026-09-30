class_name ReleaseStateTest extends GdUnitTestSuite

## What Soltar lets go of comes back when the grey takes the pulse - but not
## while something holds it, and not while another pulse still covers it.

func test_a_pulse_lets_it_go_once() -> void:
	var state := ReleaseState.new()
	assert_int(state.lit()).is_equal(ReleaseState.Event.RELEASED)
	assert_int(state.lit()).is_equal(ReleaseState.Event.NONE)
	assert_bool(state.is_released()).is_true()

func test_the_last_pulse_leaving_restores_it() -> void:
	var state := ReleaseState.new()
	state.lit()
	assert_int(state.unlit(true)).is_equal(ReleaseState.Event.NONE)
	assert_int(state.unlit(false)).is_equal(ReleaseState.Event.RESTORED)
	assert_bool(state.is_released()).is_false()

func test_a_hold_defers_the_return_until_let_go() -> void:
	var state := ReleaseState.new()
	state.lit()
	state.hold()
	assert_int(state.unlit(false)).is_equal(ReleaseState.Event.NONE)
	assert_bool(state.is_waiting()).is_true()
	assert_int(state.let_go()).is_equal(ReleaseState.Event.RESTORED)

func test_two_holds_need_two_let_gos() -> void:
	var state := ReleaseState.new()
	state.lit()
	state.hold()
	state.hold()
	state.unlit(false)
	assert_int(state.let_go()).is_equal(ReleaseState.Event.NONE)
	assert_int(state.let_go()).is_equal(ReleaseState.Event.RESTORED)

func test_a_new_pulse_while_waiting_keeps_it_released() -> void:
	var state := ReleaseState.new()
	state.lit()
	state.hold()
	state.unlit(false)
	assert_int(state.lit()).is_equal(ReleaseState.Event.NONE)
	assert_int(state.let_go()).is_equal(ReleaseState.Event.NONE)
	assert_bool(state.is_released()).is_true()

func test_letting_go_of_nothing_does_nothing() -> void:
	var state := ReleaseState.new()
	assert_int(state.let_go()).is_equal(ReleaseState.Event.NONE)
	assert_int(state.unlit(false)).is_equal(ReleaseState.Event.NONE)
