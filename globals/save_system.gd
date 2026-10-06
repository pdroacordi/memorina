extends Node

## Emitted when a guardian is restored so its region can update memory.
signal guardian_restored(guardian: Enums.Guardian)
## Emitted when a rest commit succeeds, including in-memory playtest saves.
signal saved
## A song, skill, item or guardian fact changed; the notebook recomputes its entries from the save.
signal progress_changed

const PATH: String = "user://"

## Current session state; benches commit it and death restores the last commit.
var player_data: PlayerData:
	get:
		return _ledger.live

## Null until a session begins.
var _ledger: SaveLedger
## Where commits are written. Empty keeps the save in memory (playtests).
var _path: String = ""
var _slots: SaveSlots
## `Time.get_ticks_msec()` at the last commit or session start; play time counts from it.
var _counted_msec: int = 0

## Decides memory-only before touching user://, so the suite, the smoke test and the playtest runner never read, move or write a save.
func _ready() -> void:
	var session := BootPolicy.decide(DisplayServer.get_name() == "headless", OS.is_debug_build(),
			OS.get_cmdline_args(), OS.get_cmdline_user_args())
	var memory_only := session == BootPolicy.Session.MEMORY
	_slots = SaveSlots.new("" if memory_only else PATH, OS.is_debug_build())
	_slots.adopt_legacy()
	match session:
		BootPolicy.Session.MEMORY:
			begin("", true)
		BootPolicy.Session.SLOT_1:
			begin_slot(1, false)
		BootPolicy.Session.SLOT_1_FRESH:
			begin_slot(1, true)

func has_session() -> bool:
	return _ledger != null

## No slot is read, written or deleted from now on. The playtest runner calls it before `begin("", true)`.
func use_memory_only() -> void:
	_slots = SaveSlots.new("", OS.is_debug_build())
	_path = ""

## Empty when there is no disk.
func slot_path(slot: int) -> String:
	return _slots.path(slot)

## The slot's save, or null when it is empty.
func read_slot(slot: int) -> PlayerData:
	return _slots.read(slot)

## Every slot's save in slot order; null for an empty slot.
func read_slots() -> Array[PlayerData]:
	var saves: Array[PlayerData] = []
	for slot: int in range(1, SaveSlots.COUNT + 1):
		saves.append(read_slot(slot))
	return saves

func delete_slot(slot: int) -> void:
	_slots.delete(slot)

## A new game writes nothing until its first rest, so a slot left before any bench stays empty.
func begin_slot(slot: int, fresh: bool) -> void:
	begin(slot_path(slot), fresh)

## Starts a session on the save at `path` (empty: in memory only), from the
## file unless `fresh` or there is none to read.
func begin(path: String, fresh: bool) -> void:
	_path = path
	var start: PlayerData = null
	if not fresh and not path.is_empty() and FileAccess.file_exists(path):
		start = SaveSlots.load_data(path)
	_ledger = SaveLedger.new(start if start != null else _new_game())
	_counted_msec = Time.get_ticks_msec()

## Commits the current world state and respawn point.
func rest_at(bench: StringName, room_key: String, region_name_key: String) -> void:
	player_data.bench_id = bench
	player_data.bench_room = room_key
	player_data.region_name_key = region_name_key
	if _write(_ledger.commit(_take_elapsed())):
		saved.emit()

## Ivo died at `point` (local to the region `region_key` names). The mark is
## written onto the last bench's save, and the live save goes back to it.
func record_death(region_key: String, point: Vector2) -> void:
	_write(_ledger.record_death(region_key, point, _take_elapsed()))

## A death with nowhere to leave its mark (outside any region): the live save
## goes back to the last bench, and nothing is written.
func rewind() -> void:
	_ledger.rewind(_take_elapsed())

## Commits the live save as if rested on, without changing the bench. Setup
## for a playtest, whose death should rewind to its own start.
func commit() -> void:
	_write(_ledger.commit(_take_elapsed()))

func bench_id() -> StringName:
	return player_data.bench_id

func bench_room() -> String:
	return player_data.bench_room

func deaths_in(region_key: String) -> PackedVector2Array:
	return player_data.deaths.get(region_key, PackedVector2Array())

## Region deaths clear on guardian restoration and return on death before the next bench.
func clear_deaths(region_key: String) -> void:
	player_data.deaths.erase(region_key)

## The room's seen cells as `MapGrid` bytes; empty when nothing of it was seen.
func map_seen(room_key: String) -> PackedByteArray:
	return player_data.map_seen.get(room_key, PackedByteArray())

## Live only, like every gain: a bench commits it and a death forgets it.
func set_map_seen(room_key: String, bytes: PackedByteArray) -> void:
	player_data.map_seen[room_key] = bytes

## Debug fresh saves grant the sword and instrument for guardian encounters.
func _new_game() -> PlayerData:
	var data := PlayerData.new()
	if OS.is_debug_build():
		data.owned_items[Enums.PlayerItem.SWORD] = true
		data.owned_items[Enums.PlayerItem.MEMORINA] = true
	return data

## Real seconds since the last count, menus included; restarts the count.
func _take_elapsed() -> float:
	var now := Time.get_ticks_msec()
	var elapsed := (now - _counted_msec) / 1000.0
	_counted_msec = now
	return elapsed

## Whether the save landed: true in memory, or once the file is written. The
## quill must never say "kept" over a failed write.
func _write(data: PlayerData) -> bool:
	if _path.is_empty():
		return true
	data.saved_at = int(Time.get_unix_time_from_system())
	var err := ResourceSaver.save(data, _path)
	if err != OK:
		push_error("Failed to save game: %s" % error_string(err))
	return err == OK

func has_skill(skill: Enums.PlayerSkill) -> bool:
	return player_data.unlocked_player_skills[skill]

## Skills are grant-only and are not saved until a bench commit.
func unlock_skill(skill: Enums.PlayerSkill) -> void:
	player_data.unlocked_player_skills[skill] = true
	progress_changed.emit()

func has_item(item: Enums.PlayerItem) -> bool:
	return player_data.owned_items[item]

func has_song(song: Enums.Song) -> bool:
	return player_data.learned_songs[song]

## Guardian restoration teaches a song without saving; death before a bench rewinds it.
func learn_song(song: Enums.Song) -> void:
	player_data.learned_songs[song] = true
	progress_changed.emit()

## Items, unlike skills, can be taken away again - hence the explicit value
## rather than a grant-only setter. Same no-autosave rule as learn_song().
func set_item_owned(item: Enums.PlayerItem, owned: bool) -> void:
	player_data.owned_items[item] = owned
	progress_changed.emit()

func is_guardian_restored(guardian: Enums.Guardian) -> bool:
	return player_data.restored_guardians[guardian]

## Guardian restoration persists only at a bench; an earlier death rewinds it.
func restore_guardian(guardian: Enums.Guardian) -> void:
	player_data.restored_guardians[guardian] = true
	guardian_restored.emit(guardian)
	progress_changed.emit()

func is_guardian_met(guardian: Enums.Guardian) -> bool:
	return player_data.met_guardians[guardian] or player_data.restored_guardians[guardian]

## The fight began; live only, like every gain.
func meet_guardian(guardian: Enums.Guardian) -> void:
	player_data.met_guardians[guardian] = true
	progress_changed.emit()

func is_notebook_read(id: StringName) -> bool:
	return player_data.notebook_read.has(id)

## Not a gain: emits nothing, and a death keeps it (SaveLedger.rewind).
func mark_notebook_read(id: StringName) -> void:
	if not is_notebook_read(id):
		player_data.notebook_read.append(id)

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
