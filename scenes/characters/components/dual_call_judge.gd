class_name DualCallJudge extends RefCounted

## Judges one answer against two phrases sung together (the final battle's two tracks, design 02 section 5.3): the first
## note that tells them apart commits the answer to one; a note of the other track after that is mixed
## (architecture/grd-06-final-battle).

enum Result {
	## The note continues the live tracks.
	NOTE,
	## The note narrowed the answer to one track (`track()`).
	COMMITTED,
	## The note is the other track's at this position; the answer resets, the window stays open.
	MIXED,
	## The note is neither track's: the ordinary failure.
	WRONG,
	## The note ends the committed track.
	COMPLETE,
}

const NONE := -1
const TRACK_A := 0
const TRACK_B := 1

var _tracks: Array = []
## Tracks still equal to the answer so far.
var _live: Array[int] = [TRACK_A, TRACK_B]
var _count: int = 0
## False for the revelation: every note after the first is mixed and the answer never completes.
var _solvable: bool = true


func _init(track_a: Array[Enums.Note], track_b: Array[Enums.Note], solvable: bool = true) -> void:
	assert(track_a.size() == track_b.size() and not track_a.is_empty(), "Both tracks have the same length")
	assert(track_a[0] != track_b[0], "The tracks differ at the first note, so it always commits")
	_tracks = [track_a.duplicate(), track_b.duplicate()]
	_solvable = solvable

func feed(note: Enums.Note) -> Result:
	if not _solvable and _count > 0:
		_reset()
		return Result.MIXED
	var next: Array[int] = []
	for track: int in _live:
		if _tracks[track][_count] == note:
			next.append(track)
	if next.is_empty():
		var other := _other_live_track()
		var mixed: bool = other != NONE and _tracks[other][_count] == note
		_reset()
		return Result.MIXED if mixed else Result.WRONG
	var narrowed := next.size() < _live.size()
	_live = next
	_count += 1
	if not _solvable:
		return Result.COMMITTED
	if _count >= (_tracks[TRACK_A] as Array).size():
		return Result.COMPLETE
	return Result.COMMITTED if narrowed and _live.size() == 1 else Result.NOTE

## The committed track, or NONE while the answer has not told them apart.
func track() -> int:
	return _live[0] if _live.size() == 1 else NONE

## Notes in the answer so far.
func count() -> int:
	return _count

func _other_live_track() -> int:
	if _live.size() != 1:
		return NONE
	return TRACK_B if _live[0] == TRACK_A else TRACK_A

func _reset() -> void:
	_count = 0
	_live = [TRACK_A, TRACK_B]
