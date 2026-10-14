class_name ReachPuzzle extends Resource

## The songs one placed mover or gate needs before the kit check counts its floor or opens it (architecture/room-reachability-audit, TECH-08).

## The room's id, its scene file name.
@export var room: StringName
## The entity's `id` param in the room text.
@export var id: StringName
## Every song the puzzle needs, the whole puzzle's (a plate's weight, the song that frees it).
@export var songs: Array[Enums.Song] = []
## Never empty: the design section or room header that says what the puzzle needs.
@export var reason := ""

func need() -> PackedInt32Array:
	var packed := PackedInt32Array()
	for which: Enums.Song in songs:
		packed.append(ReachKit.song(which))
	return packed
