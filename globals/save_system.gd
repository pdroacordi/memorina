extends Node

## A guardian was restored. The regions listen for this: the place a guardian
## kept remembers with it, and nothing else can know whether the arena's room
## is even loaded when it happens.
signal guardian_restored(guardian: Enums.Guardian)

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

## A fresh save owns nothing. Debug builds start with the sword and the
## instrument so a guardian can be fought from a clean launch; nothing in the
## world grants either yet (the mentor will hand over the Memorina).
func new_game() -> void:
	player_data = PlayerData.new()
	if OS.is_debug_build():
		set_item_owned(Enums.PlayerItem.SWORD, true)
		set_item_owned(Enums.PlayerItem.MEMORINA, true)

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
	player_data.migrate()

func has_skill(skill: Enums.PlayerSkill) -> bool:
	return player_data.unlocked_player_skills[skill]

## A skill, once remembered, is never forgotten - grant-only, unlike items.
## Same no-autosave rule as learn_song().
func unlock_skill(skill: Enums.PlayerSkill) -> void:
	player_data.unlocked_player_skills[skill] = true

func has_item(item: Enums.PlayerItem) -> bool:
	return player_data.owned_items[item]

func has_song(song: Enums.Song) -> bool:
	return player_data.learned_songs[song]

## Restoring a guardian teaches a song. Deliberately does not save: benches are
## the only save point, so an unsaved death rewinds the lesson along with
## everything else that happened after the last bench.
func learn_song(song: Enums.Song) -> void:
	player_data.learned_songs[song] = true

## Items, unlike skills, can be taken away again - hence the explicit value
## rather than a grant-only setter. Same no-autosave rule as learn_song().
func set_item_owned(item: Enums.PlayerItem, owned: bool) -> void:
	player_data.owned_items[item] = owned

func is_guardian_restored(guardian: Enums.Guardian) -> bool:
	return player_data.restored_guardians[guardian]

## Permanent: a restored guardian stays lucid, and its region's memory stays at
## 1.0, on every later visit. Same no-autosave rule as learn_song().
func restore_guardian(guardian: Enums.Guardian) -> void:
	player_data.restored_guardians[guardian] = true
	guardian_restored.emit(guardian)

func is_enemy_defeated(save_id: String) -> bool:
	return _defeated_enemies.has(save_id)

func mark_enemy_defeated(save_id: String) -> void:
	_defeated_enemies[save_id] = true
