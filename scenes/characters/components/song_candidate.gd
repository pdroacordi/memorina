class_name SongCandidate extends RefCounted

## A half-known song offered to the matcher: known notes must match, blank ones take any note (architecture/half-songs).

var song: Song
## One flag per note of `song`; false is a blank.
var known: Array[bool] = []

func _init(candidate_song: Song, known_notes: Array[bool]) -> void:
	assert(known_notes.size() == candidate_song.notes.size(), "A mask needs one flag per note")
	song = candidate_song
	known = known_notes

## The buffer fits: every known position holds the song's note.
func admits(buffer: Array[Enums.Note]) -> bool:
	if buffer.size() > song.notes.size():
		return false
	for i: int in buffer.size():
		if known[i] and buffer[i] != song.notes[i]:
			return false
	return true
