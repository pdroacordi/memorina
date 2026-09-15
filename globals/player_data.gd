class_name PlayerData extends Resource

@export var unlocked_player_skills: Array[bool]
@export var owned_items: Array[bool]
@export var learned_songs: Array[bool]

func _init() -> void:
	migrate()

## Grows every flag array to its enum's current size, preserving whatever is
## already there. _init() sizes a fresh PlayerData, but a save file written by
## an older build deserialises its own shorter arrays OVER those defaults, so
## every load must run this again or indexing by a newly appended enum member
## goes out of bounds. Only ever grows: enums are append-only, so a stored
## array is never longer than its enum.
func migrate() -> void:
	_grow(unlocked_player_skills, Enums.PlayerSkill.size())
	_grow(owned_items, Enums.PlayerItem.size())
	_grow(learned_songs, Enums.Song.size())

func _grow(flags: Array[bool], size: int) -> void:
	if flags.size() < size:
		flags.resize(size)
