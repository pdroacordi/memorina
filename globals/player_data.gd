class_name PlayerData extends Resource

@export var unlocked_player_skills: Array[bool]
@export var owned_items: Array[bool]
@export var learned_songs: Array[bool]
@export var restored_guardians: Array[bool]
## Resolved puzzle shortcuts keyed by authored id (docs/design/02_mecanicas.md, section 6.1); song effects are not stored here.
@export var resolved_shortcuts: Array[StringName] = []
## Last rested bench id and room key; empty until the first rest.
@export var bench_id: StringName = &""
@export var bench_room: String = ""
## Region-local death points keyed by region scene key; clustering is handled by `RegionMemory`.
@export var deaths: Dictionary[String, PackedVector2Array] = {}

func _init() -> void:
	migrate()

## Grows flag arrays after loading older saves; enums are append-only, so migration only grows arrays.
func migrate() -> void:
	_grow(unlocked_player_skills, Enums.PlayerSkill.size())
	_grow(owned_items, Enums.PlayerItem.size())
	_grow(learned_songs, Enums.Song.size())
	_grow(restored_guardians, Enums.Guardian.size())

func _grow(flags: Array[bool], size: int) -> void:
	if flags.size() < size:
		flags.resize(size)
