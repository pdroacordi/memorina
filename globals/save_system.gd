extends Node

const PATH: String = "user://"
const SAVE_FILE_NAME: String = "save.tres"

var player_data : PlayerData

## Session-only memory of enemies defeated since the game last started.
## Deliberately NOT part of PlayerData (the save-file schema): a full
## restart, or loading a save from a fresh launch, naturally resets it, while
## leaving and re-entering a room within the same session does not.
var _defeated_enemies: Dictionary = {}

func _ready() -> void:
	if ResourceLoader.exists(PATH + SAVE_FILE_NAME):
		load_game()
	else:
		new_game()

func new_game() -> void:
	player_data = PlayerData.new()

func save_game() -> void:
	var err := ResourceSaver.save(player_data, PATH + SAVE_FILE_NAME)
	if err != OK:
		push_error("Failed to save game: %s" % error_string(err))

func load_game() -> void:
	var loaded: Resource = ResourceLoader.load(PATH + SAVE_FILE_NAME)
	if loaded == null or not (loaded is PlayerData):
		push_error("Failed to load save file, falling back to a new game: %s" % (PATH + SAVE_FILE_NAME))
		new_game()
		return
	player_data = loaded

func has_skill(skill: Enums.PlayerSkill) -> bool:
	return player_data.unlocked_player_skills[skill]

func has_item(item: Enums.PlayerItem) -> bool:
	return player_data.owned_items[item]

func is_enemy_defeated(save_id: String) -> bool:
	return _defeated_enemies.has(save_id)

func mark_enemy_defeated(save_id: String) -> void:
	_defeated_enemies[save_id] = true
