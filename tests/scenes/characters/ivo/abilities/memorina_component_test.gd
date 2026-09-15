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
	_freeze.notes = [UP, LEFT, DOWN]
	_memorina = auto_free(MemorinaComponent.new())

func _known() -> Array[Song]:
	return [_freeze]

func _draw() -> void:
	_memorina.try_draw(true, _known())

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

func test_a_complete_sequence_plays_the_song() -> void:
	_draw()
	var monitor := monitor_signals(_memorina)
	_memorina.receive_note(UP)
	_memorina.receive_note(LEFT)
	_memorina.receive_note(DOWN)
	await assert_signal(monitor).is_emitted("song_played", [_freeze])

func test_every_note_is_announced_for_the_hud() -> void:
	_draw()
	var monitor := monitor_signals(_memorina)
	_memorina.receive_note(UP)
	await assert_signal(monitor).is_emitted("note_played", [UP])

func test_a_wrong_note_fails_silently() -> void:
	_draw()
	var monitor := monitor_signals(_memorina)
	_memorina.receive_note(UP)
	_memorina.receive_note(RIGHT)
	await assert_signal(monitor).is_emitted("sequence_failed")
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
	_memorina.receive_note(UP)
	_memorina.receive_note(LEFT)
	_memorina.receive_note(DOWN)
	await assert_signal(monitor).is_emitted("song_played", [_freeze])

func test_the_toggle_buffer_expires() -> void:
	_memorina.buffer_toggle()
	assert_bool(_memorina.has_buffered_toggle()).is_true()
	_memorina.tick_timers(_memorina.toggle_buffer_max + 0.01)
	assert_bool(_memorina.has_buffered_toggle()).is_false()

func test_drawing_consumes_the_buffered_toggle() -> void:
	_memorina.buffer_toggle()
	_draw()
	assert_bool(_memorina.has_buffered_toggle()).is_false()
