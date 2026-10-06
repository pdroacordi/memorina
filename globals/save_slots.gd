class_name SaveSlots
extends RefCounted
## The save slot files in one directory, and the pure naming rules the title reads them by; see docs/knowledge/architecture/save-slots-and-the-boot-swap.md.

const COUNT := 3
const BENCH_KEY_PREFIX := "BENCH_"

## Where the slot files live. Empty means no disk: reads answer empty and writes do nothing.
var dir: String = ""
## Debug builds use their own files, so they never overwrite a release save.
var debug: bool = false


func _init(slot_dir: String, debug_build: bool) -> void:
	dir = slot_dir
	debug = debug_build

## Slots count from 1.
static func file_name(slot: int, debug_build: bool) -> String:
	assert(slot >= 1 and slot <= COUNT, "Slot %d is outside 1..%d" % [slot, COUNT])
	return "save_debug_%d.tres" % slot if debug_build else "save_%d.tres" % slot

## The single save file used before slots existed.
static func legacy_file_name(debug_build: bool) -> String:
	return "save_debug.tres" if debug_build else "save.tres"

## Whole hours and the minutes left over, rounded down.
static func play_time_parts(seconds: float) -> Vector2i:
	var minutes := floori(maxf(seconds, 0.0) / 60.0)
	return Vector2i(floori(minutes / 60.0), minutes % 60)

## Translation key of a bench's name; room_files_test checks every bench has one.
static func bench_name_key(bench_id: StringName) -> String:
	return BENCH_KEY_PREFIX + String(bench_id).to_upper()

## The most recently written used slot, from 1; 0 when every slot is empty. A tie goes to the lower slot.
static func latest(saves: Array[PlayerData]) -> int:
	var best := 0
	for i: int in saves.size():
		if saves[i] != null and (best == 0 or saves[i].saved_at > saves[best - 1].saved_at):
			best = i + 1
	return best

## The least recently written used slot, from 1; 0 when every slot is empty. A tie goes to the lower slot.
static func oldest(saves: Array[PlayerData]) -> int:
	var best := 0
	for i: int in saves.size():
		if saves[i] != null and (best == 0 or saves[i].saved_at < saves[best - 1].saved_at):
			best = i + 1
	return best

## The first empty slot, from 1; 0 when every slot is used.
static func first_empty(saves: Array[PlayerData]) -> int:
	for i: int in saves.size():
		if saves[i] == null:
			return i + 1
	return 0

## CACHE_MODE_IGNORE: a rest rewrites the file, and a cached copy would be the save as first read.
static func load_data(path: String) -> PlayerData:
	var loaded := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as PlayerData
	if loaded == null:
		push_error("Failed to load save file: %s" % path)
		return null
	loaded.migrate()
	return loaded

func has_disk() -> bool:
	return not dir.is_empty()

## Empty when there is no disk.
func path(slot: int) -> String:
	return dir.path_join(file_name(slot, debug)) if has_disk() else ""

## The slot's save, or null when the slot is empty.
func read(slot: int) -> PlayerData:
	var slot_path := path(slot)
	if slot_path.is_empty() or not FileAccess.file_exists(slot_path):
		return null
	return load_data(slot_path)

func delete(slot: int) -> void:
	var slot_path := path(slot)
	if not slot_path.is_empty() and FileAccess.file_exists(slot_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(slot_path))

## Moves the pre-slot save into slot 1 once, if slot 1 is empty.
func adopt_legacy() -> void:
	if not has_disk():
		return
	var legacy := dir.path_join(legacy_file_name(debug))
	var first := path(1)
	if FileAccess.file_exists(legacy) and not FileAccess.file_exists(first):
		DirAccess.rename_absolute(ProjectSettings.globalize_path(legacy), ProjectSettings.globalize_path(first))
