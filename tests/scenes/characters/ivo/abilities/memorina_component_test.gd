class_name MemorinaComponentTest extends GdUnitTestSuite

## The component is driven entirely through pushed-in values (enabled,
## can_play, known_songs), so it tests without a body, a save file or a world.

const UP := Enums.Note.UP
const DOWN := Enums.Note.DOWN
const LEFT := Enums.Note.LEFT
const RIGHT := Enums.Note.RIGHT

var _memorina: MemorinaComponent
var _freeze: Song

func before_test() -> void:
	_freeze = Song.new()
	_freeze.id = Enums.Song.FREEZE
	_freeze.notes = [UP, RIGHT, LEFT, DOWN, DOWN, DOWN]
	_memorina = auto_free(MemorinaComponent.new())

func _known() -> Array[Song]:
	return [_freeze]

func _draw() -> void:
	_memorina.try_draw(true, _known())

func _play_freeze() -> void:
	for note: Enums.Note in _freeze.notes:
		_memorina.receive_note(note)

func test_it_starts_sheathed() -> void:
	assert_bool(_memorina.is_drawn()).is_false()

func test_drawing_while_still_succeeds() -> void:
	assert_bool(_memorina.try_draw(true, _known())).is_true()
	assert_bool(_memorina.is_drawn()).is_true()

## The stillness rule of docs/design/02_mecanicas.md section 6.2, pushed in by
## the body rather than checked here.
func test_it_cannot_be_drawn_while_moving() -> void:
	assert_bool(_memorina.try_draw(false, _known())).is_false()
	assert_bool(_memorina.is_drawn()).is_false()

## The item gate, pushed in the same way the roll's skill gate is.
func test_it_cannot_be_drawn_without_the_instrument() -> void:
	_memorina.enabled = false
	assert_bool(_memorina.try_draw(true, _known())).is_false()

func test_drawing_announces_what_the_player_knows() -> void:
	var monitor := monitor_signals(_memorina)
	_draw()
	await assert_signal(monitor).is_emitted("drawn", [_known()])

func test_notes_are_ignored_while_sheathed() -> void:
	var monitor := monitor_signals(_memorina)
	_memorina.receive_note(UP)
	await assert_signal(monitor).is_not_emitted("note_played")

## The last note does not play the song yet: it starts the performance, and
## the song is played only once the owner has heard it out.
func test_a_complete_sequence_starts_a_performance() -> void:
	_draw()
	var monitor := monitor_signals(_memorina)
	_play_freeze()
	await assert_signal(monitor).is_emitted("song_matched", [_freeze])
	await assert_signal(monitor).is_not_emitted("song_played")
	assert_bool(_memorina.is_performing()).is_true()
	assert_object(_memorina.performing_song()).is_same(_freeze)

## The answer ends the gesture: the song is played and the instrument is put
## away, in that order (the HUD clears on the first and hides on the second).
func test_finishing_the_performance_plays_the_song_then_sheathes() -> void:
	_draw()
	_play_freeze()
	var order: Array[String] = []
	_memorina.song_played.connect(func(_song: Song) -> void: order.append("played"))
	_memorina.sheathed.connect(func() -> void: order.append("sheathed"))
	_memorina.finish_performance()
	assert_array(order).is_equal(["played", "sheathed"])
	assert_bool(_memorina.is_performing()).is_false()
	assert_bool(_memorina.is_drawn()).is_false()

func test_finishing_when_nothing_is_performing_does_nothing() -> void:
	_draw()
	var monitor := monitor_signals(_memorina)
	_memorina.finish_performance()
	await assert_signal(monitor).is_not_emitted("song_played")

func test_notes_are_ignored_while_performing() -> void:
	_draw()
	_play_freeze()
	var monitor := monitor_signals(_memorina)
	_memorina.receive_note(UP)
	await assert_signal(monitor).is_not_emitted("note_played")

## The world is answering; putting the instrument away has to wait. The
## toggle is still consumed so it cannot fire once the answer ends.
func test_sheathing_while_performing_is_ignored() -> void:
	_draw()
	_play_freeze()
	_memorina.buffer_toggle()
	var monitor := monitor_signals(_memorina)
	_memorina.sheathe()
	await assert_signal(monitor).is_not_emitted("sheathed")
	assert_bool(_memorina.is_performing()).is_true()
	assert_bool(_memorina.has_buffered_toggle()).is_false()

## A hit while the last note still rings: the performance dies the way a wrong
## note does, in the same order the HUD relies on.
func test_an_interruption_while_performing_fails_then_sheathes() -> void:
	_draw()
	_play_freeze()
	var order: Array[String] = []
	_memorina.sequence_failed.connect(func() -> void: order.append("failed"))
	_memorina.sheathed.connect(func() -> void: order.append("sheathed"))
	_memorina.interrupt()
	assert_array(order).is_equal(["failed", "sheathed"])
	assert_bool(_memorina.is_drawn()).is_false()
	assert_bool(_memorina.is_performing()).is_false()

## A lesson starts a performance by hand, and whatever was half-played is gone.
func test_a_performance_can_be_started_by_hand_while_drawn() -> void:
	_draw()
	_memorina.receive_note(UP)
	assert_bool(_memorina.start_performance(_freeze)).is_true()
	_memorina.finish_performance()
	_draw()
	var monitor := monitor_signals(_memorina)
	_memorina.receive_note(RIGHT)
	await assert_signal(monitor).is_emitted("sequence_failed")

func test_a_performance_cannot_be_started_while_sheathed() -> void:
	assert_bool(_memorina.start_performance(_freeze)).is_false()
	assert_bool(_memorina.is_performing()).is_false()

func test_every_note_is_announced_for_the_hud() -> void:
	_draw()
	var monitor := monitor_signals(_memorina)
	_memorina.receive_note(UP)
	await assert_signal(monitor).is_emitted("note_played", [UP])

## The wrong note is announced as rejected rather than played, so it can be
## drawn without being sounded.
func test_a_wrong_note_is_rejected_and_fails_the_sequence() -> void:
	_draw()
	_memorina.receive_note(UP)
	var monitor := monitor_signals(_memorina)
	_memorina.receive_note(DOWN)
	await assert_signal(monitor).is_emitted("note_rejected", [DOWN])
	await assert_signal(monitor).is_emitted("sequence_failed")
	await assert_signal(monitor).is_not_emitted("note_played")
	await assert_signal(monitor).is_not_emitted("song_played")

## Failing must not put the instrument away - the design says try again
## immediately, with no penalty.
func test_a_failure_leaves_the_instrument_out() -> void:
	_draw()
	_memorina.receive_note(RIGHT)
	assert_bool(_memorina.is_drawn()).is_true()

func test_a_song_the_player_has_not_learned_is_just_noise() -> void:
	var empty: Array[Song] = []
	_memorina.try_draw(true, empty)
	var monitor := monitor_signals(_memorina)
	_memorina.receive_note(UP)
	await assert_signal(monitor).is_emitted("sequence_failed")

## Putting it away on purpose is a choice, not a failure.
func test_sheathing_on_purpose_is_silent() -> void:
	_draw()
	_memorina.receive_note(UP)
	var monitor := monitor_signals(_memorina)
	_memorina.sheathe()
	await assert_signal(monitor).is_emitted("sheathed")
	await assert_signal(monitor).is_not_emitted("sequence_failed")

## Being interrupted mid-sequence reuses the wrong-note vocabulary rather than
## introducing a second kind of failure.
func test_an_interruption_mid_sequence_reports_a_failure() -> void:
	_draw()
	_memorina.receive_note(UP)
	var monitor := monitor_signals(_memorina)
	_memorina.interrupt()
	await assert_signal(monitor).is_emitted("sheathed")
	await assert_signal(monitor).is_emitted("sequence_failed")
	assert_bool(_memorina.is_drawn()).is_false()

## Order matters, not just presence: the HUD hides itself on `sheathed`, so a
## failure emitted afterwards would flash an already-hidden label and the player
## would never see the reset.
func test_an_interruption_reports_the_failure_before_it_sheathes() -> void:
	_draw()
	_memorina.receive_note(UP)
	var order: Array[String] = []
	_memorina.sequence_failed.connect(func() -> void: order.append("failed"))
	_memorina.sheathed.connect(func() -> void: order.append("sheathed"))
	_memorina.interrupt()
	assert_array(order).is_equal(["failed", "sheathed"])

## Nothing was being played, so nothing was lost.
func test_an_interruption_before_any_note_is_silent() -> void:
	_draw()
	var monitor := monitor_signals(_memorina)
	_memorina.interrupt()
	await assert_signal(monitor).is_not_emitted("sequence_failed")

func test_interrupting_while_sheathed_does_nothing() -> void:
	var monitor := monitor_signals(_memorina)
	_memorina.interrupt()
	await assert_signal(monitor).is_not_emitted("sheathed")

## Drawing again must start from silence, not resume a dead sequence.
func test_redrawing_starts_from_an_empty_sequence() -> void:
	_draw()
	_memorina.receive_note(UP)
	_memorina.interrupt()
	_draw()
	var monitor := monitor_signals(_memorina)
	_play_freeze()
	await assert_signal(monitor).is_emitted("song_matched", [_freeze])

func test_the_toggle_buffer_expires() -> void:
	_memorina.buffer_toggle()
	assert_bool(_memorina.has_buffered_toggle()).is_true()
	_memorina.tick_timers(_memorina.toggle_buffer_max + 0.01)
	assert_bool(_memorina.has_buffered_toggle()).is_false()

func test_drawing_consumes_the_buffered_toggle() -> void:
	_memorina.buffer_toggle()
	_draw()
	assert_bool(_memorina.has_buffered_toggle()).is_false()

#############################################
##  A   G U A R D I A N ' S   C A L L      ##
#############################################

func _sprout() -> Song:
	var song := Song.new()
	song.id = Enums.Song.SPROUT
	song.notes = [DOWN, DOWN, UP, LEFT, RIGHT, UP]
	return song

## Answering the call is not a performance: the instrument stays out and the
## world does not answer - the guardian does.
func test_playing_the_call_back_answers_it_instead_of_performing() -> void:
	var sprout := _sprout()
	_memorina.call_song = sprout
	_draw()
	var monitor := monitor_signals(_memorina)
	for note: Enums.Note in sprout.notes:
		_memorina.receive_note(note)
	await assert_signal(monitor).is_emitted("call_answered", [sprout])
	await assert_signal(monitor).is_not_emitted("song_matched")
	assert_bool(_memorina.is_performing()).is_false()
	assert_bool(_memorina.is_drawn()).is_true()

## While a guardian calls, only its phrase counts - a known song is noise.
func test_known_songs_are_not_candidates_during_a_call() -> void:
	_memorina.call_song = _sprout()
	_draw()
	var monitor := monitor_signals(_memorina)
	_memorina.receive_note(UP)
	await assert_signal(monitor).is_emitted("sequence_failed")

## The call can open while the instrument is already out.
func test_a_call_opened_while_drawn_replaces_the_candidates() -> void:
	_draw()
	_memorina.receive_note(UP)
	var sprout := _sprout()
	_memorina.call_song = sprout
	var monitor := monitor_signals(_memorina)
	for note: Enums.Note in sprout.notes:
		_memorina.receive_note(note)
	await assert_signal(monitor).is_emitted("call_answered", [sprout])

## Once the call closes, the player's own songs are candidates again.
func test_closing_the_call_restores_the_known_songs() -> void:
	_memorina.call_song = _sprout()
	_draw()
	_memorina.call_song = null
	var monitor := monitor_signals(_memorina)
	_play_freeze()
	await assert_signal(monitor).is_emitted("song_matched", [_freeze])
