class_name PlayerData extends Resource

@export var unlocked_player_skills: Array[bool]
@export var owned_items: Array[bool]
@export var learned_songs: Array[bool]
@export var restored_guardians: Array[bool]
## Puzzles whose first resolution left a permanent shortcut in the world
## (docs/design/02_mecanicas.md section 6.1): a lever locked, a lift that now
## runs by itself. Keyed by the puzzle's authored id. A song's own effect is
## never here - the grey always takes that back.
@export var resolved_shortcuts: Array[StringName] = []
## The bench Ivo last rested on (its authored id) and the room it stands in
## (SceneKey.of the room), where he comes back after a death or a load. Empty
## until the first rest: he comes back where the world places him.
@export var bench_id: StringName = &""
@export var bench_room: String = ""
## Where Ivo has died, per region (SceneKey.of the region), in region-local
## points. Raw facts, never clustered here: how deaths become marks is
## RegionMemory's tuning, and it can change without migrating a save.
@export var deaths: Dictionary[String, PackedVector2Array] = {}

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
	_grow(restored_guardians, Enums.Guardian.size())

func _grow(flags: Array[bool], size: int) -> void:
	if flags.size() < size:
		flags.resize(size)
