class_name SongMatcher extends RefCounted

## Turns a stream of notes into "still going", "that was a song" or "that was
## nothing". Pure logic: no Node, no Input, no SaveSystem, no clock.
##
## Timing is deliberately absent. The guardian call-and-response needs the same
## matching with a window on top of it (docs/design/02_mecanicas.md section 3),
## so whoever needs timing owns the clock and calls reset() when it expires -
## rather than this class growing two modes.
##
## Which songs are candidates is pushed in, not looked up, for the same reason
## every ability component takes `enabled` instead of reading SaveSystem.

enum Result {
	## The buffer is a prefix of at least one candidate. Keep listening.
	PROGRESS,
	## The buffer exactly equals a candidate. Buffer cleared; matched_song() is valid.
	MATCHED,
	## The buffer is a prefix of nothing. Buffer cleared.
	FAILED
}

var _candidates: Array[Song] = []
var _buffer: Array[Enums.Note] = []
var _matched: Song = null

func set_candidates(songs: Array[Song]) -> void:
	_candidates = songs
	reset()

func feed(note: Enums.Note) -> Result:
	_matched = null
	_buffer.append(note)

	for song: Song in _candidates:
		if _equals(song.notes, _buffer):
			_matched = song
			_buffer.clear()
			return Result.MATCHED

	for song: Song in _candidates:
		if _starts_with(song.notes, _buffer):
			return Result.PROGRESS

	_buffer.clear()
	return Result.FAILED

## The song the last feed() matched, or null. Only meaningful immediately
## after feed() returned MATCHED.
func matched_song() -> Song:
	return _matched

## A copy, so a caller cannot edit the matcher's state out from under it.
func buffer() -> Array[Enums.Note]:
	return _buffer.duplicate()

func reset() -> void:
	_buffer.clear()
	_matched = null

func _equals(notes: Array[Enums.Note], other: Array[Enums.Note]) -> bool:
	if notes.size() != other.size():
		return false
	return _starts_with(notes, other)

func _starts_with(notes: Array[Enums.Note], prefix: Array[Enums.Note]) -> bool:
	if prefix.size() > notes.size():
		return false
	for i: int in prefix.size():
		if notes[i] != prefix[i]:
			return false
	return true
