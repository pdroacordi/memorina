class_name PlayerDataTest extends GdUnitTestSuite

## Enum-backed save arrays must remain compatible as enums grow.

func test_a_fresh_save_is_sized_from_the_enums() -> void:
	var data := PlayerData.new()
	assert_int(data.unlocked_player_skills.size()).is_equal(Enums.PlayerSkill.size())
	assert_int(data.owned_items.size()).is_equal(Enums.PlayerItem.size())
	assert_int(data.learned_songs.size()).is_equal(Enums.Song.size())

func test_a_fresh_save_starts_with_nothing_unlocked() -> void:
	var data := PlayerData.new()
	assert_bool(data.owned_items[Enums.PlayerItem.MEMORINA]).is_false()
	assert_bool(data.learned_songs[Enums.Song.FREEZE]).is_false()

## Deserializing an old save replaces `_init()` arrays with shorter serialized arrays.
func test_migrate_grows_arrays_left_short_by_an_old_save() -> void:
	var data := PlayerData.new()
	data.unlocked_player_skills = [true]
	data.owned_items = []
	data.learned_songs = []
	data.migrate()
	assert_int(data.unlocked_player_skills.size()).is_equal(Enums.PlayerSkill.size())
	assert_int(data.owned_items.size()).is_equal(Enums.PlayerItem.size())
	assert_int(data.learned_songs.size()).is_equal(Enums.Song.size())

func test_migrate_keeps_what_the_player_had_already_earned() -> void:
	var data := PlayerData.new()
	data.learned_songs = [false, true]
	data.migrate()
	assert_bool(data.learned_songs[Enums.Song.FREEZE]).is_false()
	assert_bool(data.learned_songs[Enums.Song.BELL_JAR]).is_true()

func test_migrate_fills_the_new_slots_as_not_earned() -> void:
	var data := PlayerData.new()
	data.learned_songs = [true]
	data.migrate()
	for i: int in range(1, Enums.Song.size()):
		assert_bool(data.learned_songs[i]).is_false()

func test_migrate_on_an_up_to_date_save_changes_nothing() -> void:
	var data := PlayerData.new()
	data.learned_songs[Enums.Song.RAIN] = true
	data.migrate()
	assert_int(data.learned_songs.size()).is_equal(Enums.Song.size())
	assert_bool(data.learned_songs[Enums.Song.RAIN]).is_true()

## Old saves omit bench and death-mark keys.
func test_a_save_from_before_benches_loads_with_no_bench_and_no_deaths() -> void:
	var path := "user://test_old_save.tres"
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string("""[gd_resource type="Resource" script_class="PlayerData" load_steps=2 format=3]

[ext_resource type="Script" path="res://globals/player_data.gd" id="1"]

[resource]
script = ExtResource("1")
learned_songs = Array[bool]([true])
""")
	file.close()
	var data := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as PlayerData
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	assert_object(data).is_not_null()
	data.migrate()
	assert_bool(data.learned_songs[Enums.Song.FREEZE]).is_true()
	assert_str(String(data.bench_id)).is_empty()
	assert_str(data.bench_room).is_empty()
	assert_bool(data.deaths.is_empty()).is_true()
	assert_float(data.play_time).is_equal(0.0)
	assert_str(data.region_name_key).is_empty()
	assert_int(data.saved_at).is_equal(0)

## Bench and death data must round-trip through serialization.
func test_the_bench_and_the_deaths_round_trip_through_the_file() -> void:
	var path := "user://test_round_trip.tres"
	var data := PlayerData.new()
	data.bench_id = &"downtown_bench"
	data.bench_room = "uid://room"
	data.deaths["uid://region"] = PackedVector2Array([Vector2(12, -40), Vector2(3, 4)])
	assert_int(ResourceSaver.save(data, path)).is_equal(OK)
	var loaded := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as PlayerData
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	assert_str(String(loaded.bench_id)).is_equal("downtown_bench")
	assert_str(loaded.bench_room).is_equal("uid://room")
	assert_array(Array(loaded.deaths["uid://region"])).is_equal([Vector2(12, -40), Vector2(3, 4)])

## Saves written before guardians existed have no restored_guardians at all.
func test_migrate_adds_the_guardian_flags_an_old_save_lacks() -> void:
	var data := PlayerData.new()
	data.restored_guardians = []
	data.migrate()
	assert_int(data.restored_guardians.size()).is_equal(Enums.Guardian.size())
	assert_bool(data.restored_guardians[Enums.Guardian.FROST]).is_false()

func test_the_play_time_and_the_region_round_trip_through_the_file() -> void:
	var path := "user://test_round_trip_title.tres"
	var data := PlayerData.new()
	data.play_time = 11220.5
	data.region_name_key = "REGION_HOME_VILLAGE"
	assert_int(ResourceSaver.save(data, path)).is_equal(OK)
	var loaded := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as PlayerData
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	assert_float(loaded.play_time).is_equal(11220.5)
	assert_str(loaded.region_name_key).is_equal("REGION_HOME_VILLAGE")
