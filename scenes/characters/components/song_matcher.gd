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
var _partials: Array[SongCandidate] = []
var _buffer: Array[Enums.Note] = []
var _matched: Song = null
var _by_ear := false

## `partials` are half-known songs: their blanks take any note and only the last note decides.
func set_candidates(songs: Array[Song], partials: Array[SongCandidate] = []) -> void:
	_candidates = songs
	_partials = partials
	reset()

func feed(note: Enums.Note) -> Result:
	_matched = null
	_by_ear = false
	_buffer.append(note)

	for song: Song in _candidates:
		if _equals(song.notes, _buffer):
			_matched = song
			_buffer.clear()
			return Result.MATCHED

	for partial: SongCandidate in _partials:
		if _equals(partial.song.notes, _buffer):
			_matched = partial.song
			_by_ear = true
			_buffer.clear()
			return Result.MATCHED

	for song: Song in _candidates:
		if _starts_with(song.notes, _buffer):
			return Result.PROGRESS

	for partial: SongCandidate in _partials:
		if _buffer.size() < partial.song.notes.size() and partial.admits(_buffer):
			return Result.PROGRESS

	_buffer.clear()
	return Result.FAILED

## The song the last feed() matched, or null. Only meaningful immediately
## after feed() returned MATCHED.
func matched_song() -> Song:
	return _matched

## The last match completed a half-known song's blanks.
func matched_by_ear() -> bool:
	return _by_ear

## Return a copy so callers cannot mutate matcher state.
func buffer() -> Array[Enums.Note]:
	return _buffer.duplicate()

func reset() -> void:
	_buffer.clear()
	_matched = null
	_by_ear = false

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
