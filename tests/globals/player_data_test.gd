class_name PlayerDataTest extends GdUnitTestSuite

## PlayerData is the save-file schema. These tests exist because the enums it
## indexes are append-only and grow over time: a save written by an older
## build must keep working.

func test_a_fresh_save_is_sized_from_the_enums() -> void:
	var data := PlayerData.new()
	assert_int(data.unlocked_player_skills.size()).is_equal(Enums.PlayerSkill.size())
	assert_int(data.owned_items.size()).is_equal(Enums.PlayerItem.size())
	assert_int(data.learned_songs.size()).is_equal(Enums.Song.size())

func test_a_fresh_save_starts_with_nothing_unlocked() -> void:
	var data := PlayerData.new()
	assert_bool(data.owned_items[Enums.PlayerItem.MEMORINA]).is_false()
	assert_bool(data.learned_songs[Enums.Song.FREEZE]).is_false()

## This is the whole point of migrate(): deserialising an old save overwrites
## _init()'s correctly sized arrays with the file's shorter ones.
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
	assert_bool(data.learned_songs[Enums.Song.BLIZZARD]).is_true()

func test_migrate_fills_the_new_slots_as_not_earned() -> void:
	var data := PlayerData.new()
	data.learned_songs = [true]
	data.migrate()
	for i: int in range(1, Enums.Song.size()):
		assert_bool(data.learned_songs[i]).is_false()

func test_migrate_on_an_up_to_date_save_changes_nothing() -> void:
	var data := PlayerData.new()
	data.learned_songs[Enums.Song.HATCH] = true
	data.migrate()
	assert_int(data.learned_songs.size()).is_equal(Enums.Song.size())
	assert_bool(data.learned_songs[Enums.Song.HATCH]).is_true()

## Saves written before guardians existed have no restored_guardians at all.
func test_migrate_adds_the_guardian_flags_an_old_save_lacks() -> void:
	var data := PlayerData.new()
	data.restored_guardians = []
	data.migrate()
	assert_int(data.restored_guardians.size()).is_equal(Enums.Guardian.size())
	assert_bool(data.restored_guardians[Enums.Guardian.FROST]).is_false()
