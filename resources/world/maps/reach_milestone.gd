class_name ReachMilestone extends Resource

## One gift on the journey and the room where it is earned (design 04 section 2; architecture/room-reachability-audit, TECH-08).

@export var id: StringName
## Where the gift is earned (the guardian's arena); empty when held from the start.
@export var room: StringName
@export var skills: Array[Enums.PlayerSkill] = []
@export var songs: Array[Enums.Song] = []
@export var items: Array[Enums.PlayerItem] = []
@export var restored_guardians: Array[Enums.Guardian] = []
## What the design gives here that the code cannot hold yet (GRD-04, STORY-03), or empty.
@export_multiline var note := ""
