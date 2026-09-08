class_name PlayerData extends Resource

@export var unlocked_player_skills: Array[bool]

func _init() -> void:
	unlocked_player_skills.resize(Enums.PLAYER_SKILLS.size())
