class_name SongMatcher extends RefCounted

## Matches note sequences without owning timing or candidate lookup (docs/design/02_mecanicas.md section 3).

enum Result {
	## The buffer matches a candidate prefix; keep listening.
	PROGRESS,
	## The buffer matches a complete candidate; `matched_song()` is valid.
	MATCHED,
	## The buffer matches no candidate prefix.
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

## Return a copy so callers cannot mutate matcher state.
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
