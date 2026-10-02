extends Node

## Emitted when a guardian is restored so its region can update memory.
signal guardian_restored(guardian: Enums.Guardian)
## Emitted when a rest commit succeeds, including in-memory playtest saves.
signal saved

const PATH: String = "user://"
const SAVE_FILE_NAME: String = "save.tres"
## Debug builds use a persistent separate save; `-- --new-game` starts fresh. Playtests use memory only.
const DEBUG_SAVE_FILE_NAME: String = "save_debug.tres"
const NEW_GAME_ARG: String = "--new-game"

## Current session state; benches commit it and death restores the last commit.
var player_data: PlayerData:
	get:
		return _ledger.live

var _ledger: SaveLedger
## Where commits are written. Empty keeps the save in memory (playtests).
var _path: String = ""

func _ready() -> void:
	# Nobody plays headless: the test suite, the smoke test and the tools run
	# that way, and none of them may read - or one day write - a player's save.
	if DisplayServer.get_name() == "headless":
		begin("", true)
	elif OS.is_debug_build():
		begin(PATH + DEBUG_SAVE_FILE_NAME, NEW_GAME_ARG in OS.get_cmdline_user_args())
	else:
		begin(PATH + SAVE_FILE_NAME, false)

## Starts a session on the save at `path` (empty: in memory only), from the
## file unless `fresh` or there is none to read.
func begin(path: String, fresh: bool) -> void:
	_path = path
	var start: PlayerData = null
	if not fresh and not path.is_empty() and ResourceLoader.exists(path):
		start = _read(path)
	_ledger = SaveLedger.new(start if start != null else _new_game())

## Commits the current world state and respawn point.
func rest_at(bench: StringName, room_key: String) -> void:
	player_data.bench_id = bench
	player_data.bench_room = room_key
	if _write(_ledger.commit()):
		saved.emit()

## Ivo died at `point` (local to the region `region_key` names). The mark is
## written onto the last bench's save, and the live save goes back to it.
func record_death(region_key: String, point: Vector2) -> void:
	_write(_ledger.record_death(region_key, point))

## A death with nowhere to leave its mark (outside any region): the live save
## goes back to the last bench, and nothing is written.
func rewind() -> void:
	_ledger.rewind()

## Commits the live save as if rested on, without changing the bench. Setup
## for a playtest, whose death should rewind to its own start.
func commit() -> void:
	_write(_ledger.commit())

func bench_id() -> StringName:
	return player_data.bench_id

func bench_room() -> String:
	return player_data.bench_room

func deaths_in(region_key: String) -> PackedVector2Array:
	return player_data.deaths.get(region_key, PackedVector2Array())

## Region deaths clear on guardian restoration and return on death before the next bench.
func clear_deaths(region_key: String) -> void:
	player_data.deaths.erase(region_key)

## Debug fresh saves grant the sword and instrument for guardian encounters.
func _new_game() -> PlayerData:
	var data := PlayerData.new()
	if OS.is_debug_build():
		data.owned_items[Enums.PlayerItem.SWORD] = true
		data.owned_items[Enums.PlayerItem.MEMORINA] = true
	return data

# CACHE_MODE_IGNORE: the file is rewritten by every rest, and a cached copy
# would hand back the save as it was first read.
func _read(path: String) -> PlayerData:
	var loaded := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as PlayerData
	if loaded == null:
		push_error("Failed to load save file, falling back to a new game: %s" % path)
		return null
	loaded.migrate()
	return loaded

## Whether the save landed: true in memory, or once the file is written. The
## quill must never say "kept" over a failed write.
func _write(data: PlayerData) -> bool:
	if _path.is_empty():
		return true
	var err := ResourceSaver.save(data, _path)
	if err != OK:
		push_error("Failed to save game: %s" % error_string(err))
	return err == OK

func has_skill(skill: Enums.PlayerSkill) -> bool:
	return player_data.unlocked_player_skills[skill]

## Skills are grant-only and are not saved until a bench commit.
func unlock_skill(skill: Enums.PlayerSkill) -> void:
	player_data.unlocked_player_skills[skill] = true

func has_item(item: Enums.PlayerItem) -> bool:
	return player_data.owned_items[item]

func has_song(song: Enums.Song) -> bool:
	return player_data.learned_songs[song]

## Guardian restoration teaches a song without saving; death before a bench rewinds it.
func learn_song(song: Enums.Song) -> void:
	player_data.learned_songs[song] = true

## Items, unlike skills, can be taken away again - hence the explicit value
## rather than a grant-only setter. Same no-autosave rule as learn_song().
func set_item_owned(item: Enums.PlayerItem, owned: bool) -> void:
	player_data.owned_items[item] = owned

func is_guardian_restored(guardian: Enums.Guardian) -> bool:
	return player_data.restored_guardians[guardian]

## Guardian restoration persists only at a bench; an earlier death rewinds it.
func restore_guardian(guardian: Enums.Guardian) -> void:
	player_data.restored_guardians[guardian] = true
	guardian_restored.emit(guardian)

func is_shortcut_resolved(shortcut_id: StringName) -> bool:
	return shortcut_id in player_data.resolved_shortcuts

## Permanent, like a restored guardian. Same no-autosave rule as learn_song().
func resolve_shortcut(shortcut_id: StringName) -> void:
	assert(shortcut_id != &"", "A shortcut needs an authored id")
	if not is_shortcut_resolved(shortcut_id):
		player_data.resolved_shortcuts.append(shortcut_id)

## Enemies stay down until the next rest or death - never on disk.
func is_enemy_defeated(save_id: String) -> bool:
	return _ledger.defeated.has(save_id)

func mark_enemy_defeated(save_id: String) -> void:
	_ledger.defeated[save_id] = true
