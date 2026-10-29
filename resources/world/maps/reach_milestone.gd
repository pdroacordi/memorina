class_name ReachMilestone extends Resource

## One gift on the journey and the room where it is earned (design 04 section 2; architecture/room-reachability-audit, TECH-08).

@export var id: StringName
## Where the gift is earned (the guardian's arena); empty when held from the start.
@export var room: StringName
@export var skills: Array[Enums.PlayerSkill] = []
@export var songs: Array[Enums.Song] = []
## Halves taught here: a teacher's first, a songbook's second (architecture/half-songs); both halves learn the song.
@export var first_halves: Array[Enums.Song] = []
@export var second_halves: Array[Enums.Song] = []
@export var items: Array[Enums.PlayerItem] = []
@export var restored_guardians: Array[Enums.Guardian] = []
## Talks heard here: the opening's, which open the east gate (systems/story).
@export var dialogues: Array[StringName] = []
## What the design gives here that the code cannot hold yet (GRD-04, STORY-03), or empty.
@export_multiline var note := ""

## A milestone that only teaches halves; it rides along with the milestone a kit grows by.
func is_half() -> bool:
	return not (first_halves.is_empty() and second_halves.is_empty()) and skills.is_empty() and songs.is_empty() \
		and items.is_empty() and restored_guardians.is_empty() and dialogues.is_empty()
