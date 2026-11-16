class_name MenuCueGateTest extends GdUnitTestSuite

## One menu cue per frame by priority OPEN = CLOSE > PAGE > BACK > CONFIRM > MOVE; a focus change is a MOVE only in
## a frame with a navigation press (architecture/sound-effects-system).

var _gate: MenuCueGate


func before_test() -> void:
	_gate = MenuCueGate.new()

func test_an_empty_frame_plays_nothing() -> void:
	assert_int(_gate.flush()).is_equal(MenuCueGate.Cue.NONE)

func test_the_highest_priority_asked_wins_in_either_order() -> void:
	var ladder: Array[MenuCueGate.Cue] = [MenuCueGate.Cue.CONFIRM, MenuCueGate.Cue.BACK, MenuCueGate.Cue.PAGE,
			MenuCueGate.Cue.OPEN]
	for i: int in ladder.size() - 1:
		_gate.ask(ladder[i])
		_gate.ask(ladder[i + 1])
		assert_int(_gate.flush()).is_equal(ladder[i + 1])
		_gate.ask(ladder[i + 1])
		_gate.ask(ladder[i])
		assert_int(_gate.flush()).is_equal(ladder[i + 1])

func test_open_and_close_tie_and_the_first_keeps_it() -> void:
	_gate.ask(MenuCueGate.Cue.CLOSE)
	_gate.ask(MenuCueGate.Cue.OPEN)
	assert_int(_gate.flush()).is_equal(MenuCueGate.Cue.CLOSE)
	_gate.ask(MenuCueGate.Cue.OPEN)
	_gate.ask(MenuCueGate.Cue.CLOSE)
	assert_int(_gate.flush()).is_equal(MenuCueGate.Cue.OPEN)

func test_a_focus_change_without_a_press_is_silent() -> void:
	_gate.focus_moved()
	assert_int(_gate.flush()).is_equal(MenuCueGate.Cue.NONE)

## A press at the end of a list moves nothing.
func test_a_press_without_a_focus_change_is_silent() -> void:
	_gate.navigated()
	assert_int(_gate.flush()).is_equal(MenuCueGate.Cue.NONE)

func test_a_press_and_a_focus_change_is_a_move_in_either_order() -> void:
	_gate.navigated()
	_gate.focus_moved()
	assert_int(_gate.flush()).is_equal(MenuCueGate.Cue.MOVE)
	_gate.focus_moved()
	_gate.navigated()
	assert_int(_gate.flush()).is_equal(MenuCueGate.Cue.MOVE)

func test_a_move_loses_to_a_confirm() -> void:
	_gate.navigated()
	_gate.focus_moved()
	_gate.ask(MenuCueGate.Cue.CONFIRM)
	assert_int(_gate.flush()).is_equal(MenuCueGate.Cue.CONFIRM)

func test_a_flush_starts_a_fresh_frame() -> void:
	_gate.navigated()
	_gate.ask(MenuCueGate.Cue.BACK)
	_gate.flush()
	_gate.focus_moved()
	assert_int(_gate.flush()).is_equal(MenuCueGate.Cue.NONE)

func test_every_cue_but_none_has_a_sound_in_the_set() -> void:
	var sounds := load("res://resources/audio/sfx/menu/menu_sounds.tres") as MenuSoundSet
	assert_object(sounds.cue(MenuCueGate.Cue.NONE)).is_null()
	for cue: MenuCueGate.Cue in MenuCueGate.Cue.values():
		if cue != MenuCueGate.Cue.NONE:
			assert_object(sounds.cue(cue)).override_failure_message(MenuCueGate.Cue.keys()[cue]).is_not_null()
			assert_str(String(sounds.cue(cue).bus())).is_equal(String(AudioBuses.SFX))
