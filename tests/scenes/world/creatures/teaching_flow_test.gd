class_name TeachingFlowTest extends GdUnitTestSuite

## The teacher's clock and states, with no scene (systems/teaching-creatures).

var _lesson: CreatureLesson
var _flow: TeachingFlow
var _events: Array[String] = []


func before_test() -> void:
	_lesson = CreatureLesson.new()
	_lesson.song = load("res://resources/songs/bell_jar.tres") as Song
	_flow = TeachingFlow.new(_lesson)
	_events.clear()
	_flow.sing_requested.connect(func(interval: float, lead_in: float, duet: bool) -> void:
		_events.append("sing %s %s %s" % [interval, lead_in, duet]))
	_flow.sing_stopped.connect(func() -> void: _events.append("stop"))
	_flow.balloon_shown.connect(func(lit_as_sung: bool) -> void: _events.append("show %s" % lit_as_sung))
	_flow.revealed.connect(func(index: int) -> void: _events.append("reveal %d" % index))
	_flow.lit.connect(func(count: int) -> void: _events.append("lit %d" % count))
	_flow.shaken.connect(func() -> void: _events.append("shake"))
	_flow.balloon_closed.connect(func(linger: float) -> void: _events.append("close %s" % linger))
	_flow.learn_requested.connect(func() -> void: _events.append("learn"))
	_flow.flourished.connect(func() -> void: _events.append("flourish"))

func _teachable_near() -> void:
	_flow.set_teachable(true)
	_flow.set_near(true)
	_flow.tick(0.016)

## Sings the phrase out: each note sounds, then it ends.
func _sing_out() -> void:
	for i: int in 3:
		_flow.note_sung(i)
	_flow.phrase_sung()

func test_approach_sings_after_the_lead_in() -> void:
	_teachable_near()
	assert_array(_events).is_equal(["show false", "sing 0.55 0.4 false"])
	assert_int(_flow.state()).is_equal(TeachingFlow.State.SINGING)
	_events.clear()
	_sing_out()
	assert_array(_events).is_equal(["reveal 0", "reveal 1", "reveal 2"])
	assert_int(_flow.state()).is_equal(TeachingFlow.State.LISTENING)

func test_going_away_stops_and_closes() -> void:
	_teachable_near()
	_events.clear()
	_flow.set_near(false)
	assert_array(_events).is_equal(["stop", "close 0.0"])
	assert_int(_flow.state()).is_equal(TeachingFlow.State.AWAY)
	_flow.tick(1.0)
	assert_array(_events).has_size(2)

func test_it_repeats_after_four_seconds_without_an_echo() -> void:
	_teachable_near()
	_sing_out()
	_events.clear()
	_flow.tick(3.9)
	assert_array(_events).is_empty()
	_flow.tick(0.2)
	assert_array(_events).is_equal(["show false", "sing 0.55 0.0 false"])

func test_no_repeat_mid_echo() -> void:
	_teachable_near()
	_sing_out()
	_flow.note_echoed()
	_events.clear()
	_flow.tick(10.0)
	assert_array(_events).is_empty()

func test_a_right_note_mid_phrase_cuts_and_lights() -> void:
	_teachable_near()
	_flow.note_sung(0)
	_events.clear()
	_flow.note_echoed()
	assert_array(_events).is_equal(["stop", "lit 1"])
	assert_int(_flow.state()).is_equal(TeachingFlow.State.LISTENING)

func test_a_wrong_note_shakes_then_sings_slower_after_the_reset() -> void:
	_teachable_near()
	_sing_out()
	_flow.note_echoed()
	_events.clear()
	_flow.echo_failed()
	assert_array(_events).is_equal(["shake", "lit 0"])
	_flow.tick(10.0)
	assert_array(_events).has_size(2)
	_flow.echo_reset()
	assert_array(_events.slice(2)).is_equal(["show false", "sing 0.75 0.0 false"])

func test_a_plain_echo_asks_to_learn_then_flourishes() -> void:
	_teachable_near()
	_sing_out()
	for i: int in 3:
		_flow.note_echoed()
	_events.clear()
	_flow.echoed(false)
	assert_array(_events).is_equal(["stop", "lit 3", "learn"])
	_flow.set_teachable(false)
	_flow.learned(true)
	assert_array(_events.slice(3)).is_equal(["flourish", "close 1.2"])
	assert_int(_flow.state()).is_equal(TeachingFlow.State.FLOURISH)
	_flow.tick(1.3)
	assert_int(_flow.state()).is_equal(TeachingFlow.State.TAUGHT_QUIET)

func test_a_completing_echo_duets_then_asks() -> void:
	_teachable_near()
	_sing_out()
	_events.clear()
	_flow.echoed(true)
	assert_array(_events).is_equal(["stop", "lit 3", "sing 0.55 0.5 true"])
	assert_int(_flow.state()).is_equal(TeachingFlow.State.DUET)
	_events.clear()
	_flow.phrase_sung()
	assert_array(_events).is_equal(["close 0.0", "learn"])
	_flow.set_teachable(false)
	_flow.learned(true)
	assert_int(_flow.state()).is_equal(TeachingFlow.State.TAUGHT_QUIET)

## An interrupted duet teaches nothing.
func test_leaving_mid_duet_asks_nothing() -> void:
	_teachable_near()
	_sing_out()
	_flow.echoed(true)
	_events.clear()
	_flow.set_near(false)
	_flow.phrase_sung()
	assert_array(_events).is_equal(["stop", "close 0.0"])

func test_a_refusal_sings_again() -> void:
	_teachable_near()
	_sing_out()
	_flow.echoed(false)
	_events.clear()
	_flow.learned(false)
	assert_array(_events).is_equal(["show false", "sing 0.55 0.0 false"])
	assert_int(_flow.state()).is_equal(TeachingFlow.State.SINGING)

func test_taught_sings_only_on_a_draw() -> void:
	_flow.set_teachable(false)
	_flow.set_near(true)
	_flow.tick(10.0)
	assert_array(_events).is_empty()
	_flow.drawn()
	assert_array(_events).is_equal(["show true", "sing 0.55 0.4 false"])
	_events.clear()
	_sing_out()
	assert_array(_events).is_equal(["reveal 0", "reveal 1", "reveal 2", "close 2.0"])
	assert_int(_flow.state()).is_equal(TeachingFlow.State.TAUGHT_QUIET)

func test_a_draw_out_of_reach_sings_nothing() -> void:
	_flow.set_teachable(false)
	_flow.set_near(false)
	_flow.drawn()
	assert_array(_events).is_empty()

func test_busy_is_silent() -> void:
	_flow.set_teachable(true)
	_flow.set_near(true)
	_flow.set_busy(true)
	_flow.tick(1.0)
	assert_array(_events).is_empty()
	_flow.set_busy(false)
	_flow.tick(0.016)
	assert_array(_events).is_equal(["show false", "sing 0.55 0.4 false"])
	_events.clear()
	_flow.set_busy(true)
	assert_array(_events).is_equal(["stop", "close 0.0"])

## A death rewinds the half: the teacher teaches again.
func test_becoming_teachable_again_returns_to_teaching() -> void:
	_flow.set_teachable(false)
	_flow.set_near(true)
	_flow.set_teachable(true)
	_flow.tick(0.016)
	assert_int(_flow.state()).is_equal(TeachingFlow.State.SINGING)

## A sheathe mid-echo: the balloon unlights and the repeat clock starts over.
func test_a_cleared_echo_unlights_and_repeats() -> void:
	_teachable_near()
	_sing_out()
	_flow.note_echoed()
	_flow.note_echoed()
	_events.clear()
	_flow.echo_cleared()
	assert_array(_events).is_equal(["lit 0"])
	_flow.tick(3.9)
	assert_array(_events).has_size(1)
	_flow.tick(0.2)
	assert_array(_events.slice(1)).is_equal(["show false", "sing 0.55 0.0 false"])

## After a mistake the count is already zero: a clear changes nothing and the retry still comes.
func test_a_clear_after_a_mistake_keeps_the_retry() -> void:
	_teachable_near()
	_sing_out()
	_flow.note_echoed()
	_flow.echo_failed()
	_events.clear()
	_flow.echo_cleared()
	assert_array(_events).is_empty()
	_flow.echo_reset()
	assert_array(_events).is_equal(["show false", "sing 0.75 0.0 false"])

