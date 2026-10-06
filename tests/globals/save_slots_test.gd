class_name SaveSlotsTest extends GdUnitTestSuite

## Slot file names, the play time shown on the title, bench name keys, and slot files on disk (a temporary directory, never user://).

var _dir: String = ""


func before_test() -> void:
	_dir = DirAccess.create_temp("memorina_slots", true).get_current_dir()

func after_test() -> void:
	for file: String in DirAccess.get_files_at(_dir):
		DirAccess.remove_absolute(_dir.path_join(file))
	DirAccess.remove_absolute(_dir)

func test_release_and_debug_slots_never_share_a_file() -> void:
	assert_str(SaveSlots.file_name(1, false)).is_equal("save_1.tres")
	assert_str(SaveSlots.file_name(3, false)).is_equal("save_3.tres")
	assert_str(SaveSlots.file_name(1, true)).is_equal("save_debug_1.tres")
	assert_str(SaveSlots.legacy_file_name(false)).is_equal("save.tres")
	assert_str(SaveSlots.legacy_file_name(true)).is_equal("save_debug.tres")

func test_play_time_is_whole_hours_and_minutes_rounded_down() -> void:
	assert_object(SaveSlots.play_time_parts(0.0)).is_equal(Vector2i(0, 0))
	assert_object(SaveSlots.play_time_parts(59.9)).is_equal(Vector2i(0, 0))
	assert_object(SaveSlots.play_time_parts(3 * 3600 + 7 * 60 + 59.0)).is_equal(Vector2i(3, 7))
	assert_object(SaveSlots.play_time_parts(125 * 3600.0)).is_equal(Vector2i(125, 0))
	assert_object(SaveSlots.play_time_parts(-5.0)).is_equal(Vector2i(0, 0))

func test_the_play_time_format_reads_3h_07m() -> void:
	var parts := SaveSlots.play_time_parts(3 * 3600 + 7 * 60.0)
	assert_str(tr("TITLE_PLAY_TIME") % [parts.x, parts.y]).is_equal("3h 07m")

func test_a_bench_name_key_is_its_id_in_capitals() -> void:
	assert_str(SaveSlots.bench_name_key(&"downtown_bench")).is_equal("BENCH_DOWNTOWN_BENCH")

func test_with_no_disk_every_slot_is_empty_and_nothing_is_written() -> void:
	var slots := SaveSlots.new("", false)
	assert_bool(slots.has_disk()).is_false()
	assert_str(slots.path(1)).is_empty()
	assert_object(slots.read(1)).is_null()
	slots.delete(1)
	slots.adopt_legacy()

func test_an_empty_slot_reads_null() -> void:
	assert_object(SaveSlots.new(_dir, false).read(2)).is_null()

func test_a_written_slot_reads_back_and_erases() -> void:
	var slots := SaveSlots.new(_dir, false)
	var data := PlayerData.new()
	data.bench_id = &"downtown_bench"
	data.play_time = 90.0
	assert_int(ResourceSaver.save(data, slots.path(2))).is_equal(OK)
	var read := slots.read(2)
	assert_str(String(read.bench_id)).is_equal("downtown_bench")
	assert_float(read.play_time).is_equal(90.0)
	assert_object(slots.read(1)).is_null()
	slots.delete(2)
	assert_object(slots.read(2)).is_null()

func test_the_legacy_save_moves_into_an_empty_slot_1() -> void:
	var slots := SaveSlots.new(_dir, true)
	var data := PlayerData.new()
	data.bench_id = &"legacy"
	ResourceSaver.save(data, _dir.path_join("save_debug.tres"))
	slots.adopt_legacy()
	assert_bool(FileAccess.file_exists(_dir.path_join("save_debug.tres"))).is_false()
	assert_str(String(slots.read(1).bench_id)).is_equal("legacy")

func test_the_legacy_save_never_replaces_a_used_slot_1() -> void:
	var slots := SaveSlots.new(_dir, false)
	var legacy := PlayerData.new()
	legacy.bench_id = &"legacy"
	ResourceSaver.save(legacy, _dir.path_join("save.tres"))
	var current := PlayerData.new()
	current.bench_id = &"current"
	ResourceSaver.save(current, slots.path(1))
	slots.adopt_legacy()
	assert_str(String(slots.read(1).bench_id)).is_equal("current")
	assert_bool(FileAccess.file_exists(_dir.path_join("save.tres"))).is_true()

func test_a_release_build_ignores_the_debug_legacy_save() -> void:
	ResourceSaver.save(PlayerData.new(), _dir.path_join("save_debug.tres"))
	var slots := SaveSlots.new(_dir, false)
	slots.adopt_legacy()
	assert_object(slots.read(1)).is_null()

func test_continue_picks_the_most_recently_written_slot() -> void:
	var older := PlayerData.new()
	older.saved_at = 100
	var newer := PlayerData.new()
	newer.saved_at = 200
	var saves: Array[PlayerData] = [older, null, newer]
	assert_int(SaveSlots.latest(saves)).is_equal(3)

## A save from before saved_at existed reads 0; a tie goes to the lower slot.
func test_a_tie_goes_to_the_lower_slot_and_no_save_is_zero() -> void:
	var saves: Array[PlayerData] = [null, PlayerData.new(), PlayerData.new()]
	assert_int(SaveSlots.latest(saves)).is_equal(2)
	var none: Array[PlayerData] = [null, null, null]
	assert_int(SaveSlots.latest(none)).is_equal(0)

func test_a_new_game_takes_the_first_empty_slot() -> void:
	var saves: Array[PlayerData] = [PlayerData.new(), null, null]
	assert_int(SaveSlots.first_empty(saves)).is_equal(2)
	var full: Array[PlayerData] = [PlayerData.new(), PlayerData.new(), PlayerData.new()]
	assert_int(SaveSlots.first_empty(full)).is_equal(0)

## User decision 2026-10-06, "Oldest save": overwriting starts on the least recently played slot.
func test_overwriting_starts_on_the_oldest_save() -> void:
	var saves: Array[PlayerData] = [PlayerData.new(), PlayerData.new(), PlayerData.new()]
	saves[0].saved_at = 300
	saves[1].saved_at = 100
	saves[2].saved_at = 200
	assert_int(SaveSlots.oldest(saves)).is_equal(2)
	saves[0].saved_at = 100
	assert_int(SaveSlots.oldest(saves)).is_equal(1)
	var none: Array[PlayerData] = [null, null, null]
	assert_int(SaveSlots.oldest(none)).is_equal(0)
