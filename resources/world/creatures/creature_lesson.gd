class_name CreatureLesson extends Resource

## What one teaching creature sings and its timing (systems/teaching-creatures).

@export var song: Song
## Seconds between sung notes.
@export var note_interval: float = 0.55
## Seconds between notes when it sings again after a mistake.
@export var retry_interval: float = 0.75
## Seconds from a phrase's end to the next while Ivo plays no echo note.
@export var repeat_after: float = 4.0
## Seconds of silence before the first phrase on approach.
@export var lead_in: float = 0.4
## Seconds the lit balloon stays after the flourish.
@export var flourish_linger: float = 1.2
## Seconds the balloon stays after a taught phrase sung on a draw.
@export var after_linger: float = 2.0
## Where Ivo's feet must be to be in reach, in px from the teacher's feet.
@export var reach: Rect2 = Rect2(-128.0, -96.0, 256.0, 192.0)


## The first half's notes; the song holds them, never this Resource.
func phrase() -> Array[Enums.Note]:
	return song.notes.slice(0, SongHalves.HALF_LENGTH)

## Whether Ivo's feet at `ivo_feet` are in reach of a teacher standing at `feet`; edges count.
func reaches(feet: Vector2, ivo_feet: Vector2) -> bool:
	var offset := ivo_feet - feet
	return offset.x >= reach.position.x and offset.x <= reach.end.x \
		and offset.y >= reach.position.y and offset.y <= reach.end.y

## Problems with this lesson, empty when it can teach.
func problems() -> PackedStringArray:
	var found := PackedStringArray()
	if song == null:
		found.append("%s has no song" % resource_path)
	elif not song.learned_in_halves:
		found.append("%s teaches song %d, which is not learned in halves" % [resource_path, song.id])
	return found

## Debug-only integrity check.
func validate() -> void:
	var found := problems()
	assert(found.is_empty(), "; ".join(found))
