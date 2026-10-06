class_name SaveSystemNotebookTest extends GdUnitTestSuite

## Every gain the notebook derives an entry from emits progress_changed; reading one does not.

var _changes: int = 0


func before_test() -> void:
	SaveSystem.begin("", true)
	_changes = 0
	SaveSystem.progress_changed.connect(_count)

func after_test() -> void:
	SaveSystem.progress_changed.disconnect(_count)
	SaveSystem.begin("", true)

func _count() -> void:
	_changes += 1

func test_each_gain_emits_progress_changed() -> void:
	SaveSystem.learn_song(Enums.Song.FREEZE)
	SaveSystem.unlock_skill(Enums.PlayerSkill.ROLL)
	SaveSystem.set_item_owned(Enums.PlayerItem.SWORD, true)
	SaveSystem.restore_guardian(Enums.Guardian.FROST)
	SaveSystem.meet_guardian(Enums.Guardian.BLOOM)
	assert_int(_changes).is_equal(5)

func test_reading_an_entry_emits_nothing_and_is_kept_once() -> void:
	SaveSystem.mark_notebook_read(&"song_freeze")
	SaveSystem.mark_notebook_read(&"song_freeze")
	assert_int(_changes).is_equal(0)
	assert_bool(SaveSystem.is_notebook_read(&"song_freeze")).is_true()
	assert_array(SaveSystem.player_data.notebook_read).has_size(1)

func test_a_restored_guardian_counts_as_met() -> void:
	assert_bool(SaveSystem.is_guardian_met(Enums.Guardian.FROST)).is_false()
	SaveSystem.restore_guardian(Enums.Guardian.FROST)
	assert_bool(SaveSystem.is_guardian_met(Enums.Guardian.FROST)).is_true()
