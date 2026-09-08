extends Node

const PATH: String = "user://"
const SAVE_FILE_NAME: String = "save.tres"

var player_data : PlayerData

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
	player_data = ResourceLoader.load(PATH + SAVE_FILE_NAME)
