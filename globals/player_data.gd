class_name PlayerData extends Resource

@export var unlocked_player_skills: Array[bool]
@export var owned_items: Array[bool]

func _init() -> void:
	unlocked_player_skills.resize(Enums.PlayerSkill.size())
	owned_items.resize(Enums.PlayerItem.size())
