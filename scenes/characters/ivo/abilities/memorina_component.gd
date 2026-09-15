class_name MemorinaComponent extends Node

## Holding the instrument: whether it is out, and what has been played on it
## so far. See docs/design/02_mecanicas.md section 6.2.
##
## An ability rather than a generic component, because it is gated by a
## possession (Enums.PlayerItem.MEMORINA) and no enemy will ever hold one.
##
## Owns a SongMatcher but no rules about WHEN playing is allowed: whether Ivo
## is standing still enough is the body's business, pushed in through
## try_draw(can_play) and interrupt(), the same way `enabled` carries the item
## gate. This node never reaches for SaveSystem, the player, or the world.

signal drawn(known_songs: Array[Song])
signal sheathed
signal note_played(note: Enums.Note)
## The silent reset of docs/design/02_mecanicas.md section 6.2: what was played
## so far blinks and empties. No popup, no cost, try again immediately. Also
## what an interruption reports, deliberately reusing the same vocabulary
## instead of inventing a second kind of failure.
signal sequence_failed
signal song_played(song: Song)

## Pushed by the owner from the save-game item gate at the moment a draw is
## attempted; this component must never know SaveSystem exists.
@export var enabled: bool = true
## Forgiveness window for pressing C a hair before landing or stopping.
@export var toggle_buffer_max: float = 0.12

var _matcher := SongMatcher.new()
var _is_drawn: bool = false
var _toggle_buffer: float = 0.0

func tick_timers(delta: float) -> void:
	_toggle_buffer = maxf(_toggle_buffer - delta, 0.0)

func buffer_toggle() -> void:
	_toggle_buffer = toggle_buffer_max

func has_buffered_toggle() -> bool:
	return _toggle_buffer > 0.0

func is_drawn() -> bool:
	return _is_drawn

## Takes the instrument out. `can_play` is the body's verdict on standing
## still; `known_songs` is what the player has actually learned, so an
## unlearned sequence reads as noise rather than silently working.
func try_draw(can_play: bool, known_songs: Array[Song]) -> bool:
	if not enabled or _is_drawn or not can_play:
		return false
	_toggle_buffer = 0.0
	_is_drawn = true
	_matcher.set_candidates(known_songs)
	drawn.emit(known_songs)
	return true

## Puts it away on purpose. Silent: choosing to stop is not a failure.
func sheathe() -> void:
	if not _is_drawn:
		return
	_toggle_buffer = 0.0
	_is_drawn = false
	_matcher.reset()
	sheathed.emit()

## Puts it away because something took the choice away - a hit, a ledge, being
## shoved by the wind. A sequence in flight dies the same way a wrong note
## kills it, so the player has no new failure state to learn.
func interrupt() -> void:
	if not _is_drawn:
		return
	# Failure BEFORE sheathe. The HUD hides itself on `sheathed`, so the other
	# order flashed an already-hidden, already-cleared label and the player
	# never saw the reset they were promised.
	if not _matcher.buffer().is_empty():
		sequence_failed.emit()
	sheathe()

func receive_note(note: Enums.Note) -> void:
	if not _is_drawn:
		return
	note_played.emit(note)
	match _matcher.feed(note):
		SongMatcher.Result.MATCHED:
			song_played.emit(_matcher.matched_song())
		SongMatcher.Result.FAILED:
			sequence_failed.emit()
		_:
			pass
