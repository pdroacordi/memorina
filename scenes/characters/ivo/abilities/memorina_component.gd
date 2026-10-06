class_name MemorinaComponent extends Node

## Instrument sequence and performance state (docs/design/02_mecanicas.md sections 3 and 6.2).

signal drawn(known_songs: Array[Song])
signal sheathed
## A note that continues a known song.
signal note_played(note: Enums.Note)
## A rejected note; sequence_failed follows.
signal note_rejected(note: Enums.Note)
## Sequence reset or interruption (docs/design/02_mecanicas.md section 6.2).
signal sequence_failed
## The last note matched; notes are ignored until finish_performance().
signal song_matched(song: Song)
## The performance finished.
signal song_played(song: Song)
## The guardian's phrase was answered without a performance (docs/design/02_mecanicas.md section 3).
signal call_answered(song: Song)

enum State { SHEATHED, DRAWN, PERFORMING }

## Set by the owner from the saved item gate.
@export var enabled: bool = true
## Toggle input buffer in seconds.
@export var toggle_buffer_max: float = 0.12

## Guardian phrase to match, or null; changing it resets the active sequence.
var call_song: Song = null:
	set(value):
		if value == call_song:
			return
		call_song = value
		if _state == State.DRAWN:
			_matcher.set_candidates(_candidates())

var _matcher := SongMatcher.new()
var _state := State.SHEATHED
var _performing: Song = null
var _known_songs: Array[Song] = []
var _toggle_buffer: float = 0.0

func tick_timers(delta: float) -> void:
	_toggle_buffer = maxf(_toggle_buffer - delta, 0.0)

func buffer_toggle() -> void:
	_toggle_buffer = toggle_buffer_max

func clear_buffer() -> void:
	_toggle_buffer = 0.0

func has_buffered_toggle() -> bool:
	return _toggle_buffer > 0.0

func is_drawn() -> bool:
	return _state != State.SHEATHED

func is_performing() -> bool:
	return _state == State.PERFORMING

func performing_song() -> Song:
	return _performing

## Draws the instrument when the body allows play and installs learned songs.
func try_draw(can_play: bool, known_songs: Array[Song]) -> bool:
	if not enabled or is_drawn() or not can_play:
		return false
	_toggle_buffer = 0.0
	_state = State.DRAWN
	_known_songs = known_songs
	_matcher.set_candidates(_candidates())
	drawn.emit(known_songs)
	return true

## Sheathes intentionally; consumes the toggle while a performance is active.
func sheathe() -> void:
	_toggle_buffer = 0.0
	if _state != State.DRAWN:
		return
	_state = State.SHEATHED
	_matcher.reset()
	sheathed.emit()

## Interrupts the sequence or performance when control is taken away.
func interrupt() -> void:
	if not is_drawn():
		return
	# Emit failure before sheathed hides the HUD.
	if is_performing() or not _matcher.buffer().is_empty():
		sequence_failed.emit()
	_performing = null
	_state = State.DRAWN
	sheathe()

func receive_note(note: Enums.Note) -> void:
	if _state != State.DRAWN:
		return
	match _matcher.feed(note):
		SongMatcher.Result.MATCHED:
			note_played.emit(note)
			var song := _matcher.matched_song()
			if song == call_song:
				call_answered.emit(song)
				return
			start_performance(song)
			song_matched.emit(song)
		SongMatcher.Result.FAILED:
			note_rejected.emit(note)
			sequence_failed.emit()
		_:
			note_played.emit(note)

## Starts a performance; lessons may call this without matching a sequence.
func start_performance(song: Song) -> bool:
	if _state != State.DRAWN:
		return false
	_state = State.PERFORMING
	_performing = song
	_matcher.reset()
	return true

## Completes the performance and sheaths the instrument.
func finish_performance() -> void:
	if not is_performing():
		return
	var song := _performing
	_performing = null
	_state = State.DRAWN
	song_played.emit(song)
	sheathe()

## Returns the guardian phrase or the learned songs as matcher candidates.
func _candidates() -> Array[Song]:
	if call_song != null:
		return [call_song]
	return _known_songs
