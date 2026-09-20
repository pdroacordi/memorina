class_name MemorinaComponent extends Node

## Holding the instrument: whether it is out, what has been played on it so
## far, and whether it is in the middle of answering. See
## docs/design/02_mecanicas.md section 6.2.
##
## An ability rather than a generic component, because it is gated by a
## possession (Enums.PlayerItem.MEMORINA) and no enemy will ever hold one.
##
## Owns a SongMatcher but no rules about WHEN playing is allowed: whether Ivo
## is standing still enough is the body's business, pushed in through
## try_draw(can_play) and interrupt(), the same way `enabled` carries the item
## gate. Whether a note may sound yet (the previous one still ringing) is the
## voice's business, and Player asks it before calling receive_note(). This
## node never reaches for SaveSystem, the player, the audio or the world.
##
## A completed sequence does not play the song outright: it starts a
## PERFORMANCE, during which the instrument is locked, and the owner reports
## the performance's end with finish_performance(). Only then is the song
## played. A lesson is a performance the owner starts by hand.
##
## A guardian's CALL (docs/design/02_mecanicas.md section 3) borrows the
## instrument: while `call_song` is set, its phrase is the only candidate, and
## playing it back answers the call instead of performing anything - the
## instrument stays out, and the guardian decides what the answer earns.

signal drawn(known_songs: Array[Song])
signal sheathed
## A note that fits a known song so far. It sounds and is drawn.
signal note_played(note: Enums.Note)
## A note that fits nothing. Drawn, never sounded; sequence_failed follows.
signal note_rejected(note: Enums.Note)
## The reset of docs/design/02_mecanicas.md section 6.2: what was played so far
## blinks and empties. No cost, try again immediately. Also what an
## interruption reports, deliberately reusing the same vocabulary instead of
## inventing a second kind of failure.
signal sequence_failed
## The last note of a known song landed. The instrument is now performing and
## drops notes until finish_performance().
signal song_matched(song: Song)
## The performance ran its course; the world may answer now.
signal song_played(song: Song)
## The guardian's phrase was played back whole. No performance follows.
signal call_answered(song: Song)

enum State { SHEATHED, DRAWN, PERFORMING }

## Pushed by the owner from the save-game item gate at the moment a draw is
## attempted; this component must never know SaveSystem exists.
@export var enabled: bool = true
## Forgiveness window for pressing C a hair before landing or stopping.
@export var toggle_buffer_max: float = 0.12

## The phrase a guardian is waiting to hear, or null. While set it replaces
## the known songs as the only candidate; changing it mid-sequence starts the
## sequence over, because the old notes were an answer to nothing.
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

func has_buffered_toggle() -> bool:
	return _toggle_buffer > 0.0

func is_drawn() -> bool:
	return _state != State.SHEATHED

func is_performing() -> bool:
	return _state == State.PERFORMING

func performing_song() -> Song:
	return _performing

## Takes the instrument out. `can_play` is the body's verdict on standing
## still; `known_songs` is what the player has actually learned, so an
## unlearned sequence reads as noise rather than silently working.
func try_draw(can_play: bool, known_songs: Array[Song]) -> bool:
	if not enabled or is_drawn() or not can_play:
		return false
	_toggle_buffer = 0.0
	_state = State.DRAWN
	_known_songs = known_songs
	_matcher.set_candidates(_candidates())
	drawn.emit(known_songs)
	return true

## Puts it away on purpose. Silent: choosing to stop is not a failure. Ignored
## while performing - the song has been played and the world is answering -
## but the toggle is still consumed so it does not fire once the answer ends.
func sheathe() -> void:
	_toggle_buffer = 0.0
	if _state != State.DRAWN:
		return
	_state = State.SHEATHED
	_matcher.reset()
	sheathed.emit()

## Puts it away because something took the choice away - a hit, a ledge, being
## shoved by the wind. A sequence in flight dies the same way a wrong note
## kills it, so the player has no new failure state to learn. A performance
## dies the same way: the last note was still ringing when the hit landed.
func interrupt() -> void:
	if not is_drawn():
		return
	# Failure BEFORE sheathe. The HUD hides itself on `sheathed`, so the other
	# order flashed an already-hidden, already-cleared sheet and the player
	# never saw the reset they were promised.
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

## Locks the instrument while `song` is heard. Whatever was half-played is
## discarded. Public so a lesson can start one without a sequence being
## played; a matched sequence starts one on its own.
func start_performance(song: Song) -> bool:
	if _state != State.DRAWN:
		return false
	_state = State.PERFORMING
	_performing = song
	_matcher.reset()
	return true

## The owner heard the performance out. The song is played and the instrument
## is put away: the answer is the end of the gesture, and the player draws
## again for the next sequence.
func finish_performance() -> void:
	if not is_performing():
		return
	var song := _performing
	_performing = null
	_state = State.DRAWN
	song_played.emit(song)
	sheathe()

## What the matcher listens for: the guardian's phrase alone while a call is
## open, otherwise everything the player has learned.
func _candidates() -> Array[Song]:
	if call_song != null:
		return [call_song]
	return _known_songs
