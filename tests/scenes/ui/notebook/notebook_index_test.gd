class_name NotebookIndexTest extends GdUnitTestSuite

## Presence, unread and newness are derived from the save alone.

const CATALOG := preload("res://resources/ui/notebook/notebook_catalog.tres")


func _data() -> PlayerData:
	return PlayerData.new()

func test_a_fresh_save_has_no_entry() -> void:
	assert_array(NotebookIndex.present(CATALOG, _data())).is_empty()

func test_present_follows_each_save_fact_in_catalog_order() -> void:
	var data := _data()
	data.learned_songs[Enums.Song.ROOT] = true
	data.learned_songs[Enums.Song.FREEZE] = true
	data.unlocked_player_skills[Enums.PlayerSkill.ROLL] = true
	data.owned_items[Enums.PlayerItem.MEMORINA] = true
	data.met_guardians[Enums.Guardian.FROST] = true
	assert_array(NotebookIndex.present(CATALOG, data)).contains_exactly(
			[&"lore_roll", &"song_freeze", &"song_root", &"item_memorina", &"guardian_frost"])

## Wall climb is taught by no guardian yet, so it has no diary entry.
func test_a_skill_without_an_entry_adds_nothing() -> void:
	var data := _data()
	data.unlocked_player_skills[Enums.PlayerSkill.WALL_CLIMB] = true
	assert_array(NotebookIndex.present(CATALOG, data)).is_empty()

func test_read_entries_are_not_unread() -> void:
	var data := _data()
	data.learned_songs[Enums.Song.FREEZE] = true
	data.learned_songs[Enums.Song.GALE] = true
	data.notebook_read.append(&"song_freeze")
	assert_array(NotebookIndex.unread(CATALOG, data)).contains_exactly([&"song_gale"])

func test_added_is_what_after_has_and_before_lacks() -> void:
	var before: Array[StringName] = [&"a", &"b"]
	var after: Array[StringName] = [&"a", &"c", &"b", &"d"]
	assert_array(NotebookIndex.added(before, after)).contains_exactly([&"c", &"d"])

func test_a_section_is_unread_while_one_of_its_entries_is() -> void:
	var data := _data()
	data.learned_songs[Enums.Song.FREEZE] = true
	assert_bool(NotebookIndex.section_unread(CATALOG, data, NotebookEntry.Section.SONGS)).is_true()
	assert_bool(NotebookIndex.section_unread(CATALOG, data, NotebookEntry.Section.LORE)).is_false()
	data.notebook_read.append(&"song_freeze")
	assert_bool(NotebookIndex.section_unread(CATALOG, data, NotebookEntry.Section.SONGS)).is_false()

## "Newest unread, else last": the last found this session wins over catalog order.
func test_newest_unread_is_the_last_found_still_unread() -> void:
	var data := _data()
	data.learned_songs[Enums.Song.FREEZE] = true
	data.unlocked_player_skills[Enums.PlayerSkill.ROLL] = true
	var recent: Array[StringName] = [&"song_freeze", &"lore_roll"]
	assert_str(String(NotebookIndex.newest_unread(CATALOG, data, recent))).is_equal("lore_roll")
	data.notebook_read.append(&"lore_roll")
	assert_str(String(NotebookIndex.newest_unread(CATALOG, data, recent))).is_equal("song_freeze")

func test_newest_unread_falls_back_to_the_last_in_catalog_order() -> void:
	var data := _data()
	data.unlocked_player_skills[Enums.PlayerSkill.ROLL] = true
	data.owned_items[Enums.PlayerItem.SWORD] = true
	assert_str(String(NotebookIndex.newest_unread(CATALOG, data, []))).is_equal("item_sword")

func test_nothing_unread_has_no_newest() -> void:
	assert_str(String(NotebookIndex.newest_unread(CATALOG, _data(), []))).is_empty()
