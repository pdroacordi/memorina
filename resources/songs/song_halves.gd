class_name SongHalves
extends RefCounted
## How the two halves of a song combine in the save (architecture/half-songs).

enum State {
	UNKNOWN,
	FIRST_HALF,
	SECOND_HALF,
	## Learned whole, or from both halves.
	LEARNED,
	BY_EAR,
	## Learned by ear, and the guessed half was found later.
	BY_EAR_CONFIRMED,
}

## Notes in each half.
const HALF_LENGTH := 3


static func state(data: PlayerData, song: int) -> State:
	var guessed: int = data.guessed_halves[song]
	if data.learned_songs[song]:
		if guessed == Enums.SongHalf.NONE:
			return State.LEARNED
		return State.BY_EAR_CONFIRMED if knows(data, song, guessed) else State.BY_EAR
	if data.song_first_halves[song]:
		return State.FIRST_HALF
	if data.song_second_halves[song]:
		return State.SECOND_HALF
	return State.UNKNOWN


static func knows(data: PlayerData, song: int, half: Enums.SongHalf) -> bool:
	match half:
		Enums.SongHalf.FIRST:
			return data.song_first_halves[song]
		Enums.SongHalf.SECOND:
			return data.song_second_halves[song]
	return false


## The half a half-known song lacks; NONE unless exactly one half is known and the song is unlearned.
static func missing(data: PlayerData, song: int) -> Enums.SongHalf:
	match state(data, song):
		State.FIRST_HALF:
			return Enums.SongHalf.SECOND
		State.SECOND_HALF:
			return Enums.SongHalf.FIRST
	return Enums.SongHalf.NONE


## Which of the six notes the player knows: all of them once the song is learned.
static func known_mask(data: PlayerData, song: int) -> Array[bool]:
	if data.learned_songs[song]:
		return _mask(true, true)
	return _mask(data.song_first_halves[song], data.song_second_halves[song])


## Which of the six notes Ivo guessed; all false for a song not learned by ear.
static func guessed_mask(data: PlayerData, song: int) -> Array[bool]:
	var guessed: int = data.guessed_halves[song]
	return _mask(guessed == Enums.SongHalf.FIRST, guessed == Enums.SongHalf.SECOND)


## The song's title as the save knows it: Ivo's name until the half he guessed is found.
static func title_key(data: PlayerData, song: Song) -> String:
	return song.ear_title_key if state(data, song.id) == State.BY_EAR else song.title_key


## Records a half; both halves learn the song. Returns whether anything changed.
static func teach(data: PlayerData, song: int, half: Enums.SongHalf) -> bool:
	assert(half != Enums.SongHalf.NONE, "A half is FIRST or SECOND")
	if knows(data, song, half):
		return false
	if half == Enums.SongHalf.FIRST:
		data.song_first_halves[song] = true
	else:
		data.song_second_halves[song] = true
	if data.song_first_halves[song] and data.song_second_halves[song]:
		data.learned_songs[song] = true
	return true


## Learns a half-known song by ear and records the half Ivo supplied. Returns whether anything changed.
static func guess(data: PlayerData, song: int) -> bool:
	var half := missing(data, song)
	if half == Enums.SongHalf.NONE:
		return false
	data.learned_songs[song] = true
	data.guessed_halves[song] = half
	return true


static func _mask(first: bool, second: bool) -> Array[bool]:
	var mask: Array[bool] = []
	for i: int in Song.NOTE_COUNT:
		mask.append(first if i < HALF_LENGTH else second)
	return mask
