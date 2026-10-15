class_name GuitarPhrase
extends RefCounted
## The guitar's rules, pure (systems/story): before the gap a right note plays, a wrong one only sounds, and at the gap
## every press is a muted thump. The phrase can never be finished: `played() <= gap_index < notes.size()`.

enum Press { PLAYED, MISSED, DEAD }

var _notes: Array[Enums.Note] = []
var _gap: int = 0
var _played: int = 0
var _dead: int = 0


func _init(attempt: GuitarAttempt) -> void:
	_notes.assign(attempt.melody.notes)
	_gap = clampi(attempt.gap_index, 0, _notes.size() - 1)

func press(note: Enums.Note) -> Press:
	if _played >= _gap:
		_dead += 1
		return Press.DEAD
	if note != _notes[_played]:
		return Press.MISSED
	_played += 1
	return Press.PLAYED

## Notes played right so far.
func played() -> int:
	return _played

func at_gap() -> bool:
	return _played >= _gap

func dead_presses() -> int:
	return _dead

func gap_index() -> int:
	return _gap
