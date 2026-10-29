class_name PhraseEcho extends RefCounted

## Judges notes against a short phrase a teacher sang; the song matcher is not consulted (systems/teaching-creatures).

enum Result {
	## The note continues the phrase.
	RIGHT,
	## The note ends the phrase.
	COMPLETE,
	## The note breaks the phrase; progress resets.
	WRONG,
	## The phrase is already complete.
	IGNORED,
}

var _phrase: Array[Enums.Note] = []
var _count: int = 0


func _init(phrase: Array[Enums.Note]) -> void:
	assert(not phrase.is_empty(), "A phrase has at least one note")
	_phrase = phrase.duplicate()

func feed(note: Enums.Note) -> Result:
	if is_complete():
		return Result.IGNORED
	if _phrase[_count] != note:
		_count = 0
		return Result.WRONG
	_count += 1
	return Result.COMPLETE if is_complete() else Result.RIGHT

## Notes matched so far.
func count() -> int:
	return _count

func is_complete() -> bool:
	return _count >= _phrase.size()

func reset() -> void:
	_count = 0
