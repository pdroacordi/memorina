class_name SaveSystemSceneTest extends GdUnitTestSuite

## SCENE_SEEN is live data like heard: recorded once with progress_changed, committed by a bench, forgotten by a death.

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

func test_a_scene_is_seen_once() -> void:
	SaveSystem.mark_scene_seen(&"daughter_to_bed")
	SaveSystem.mark_scene_seen(&"daughter_to_bed")
	assert_bool(SaveSystem.is_scene_seen(&"daughter_to_bed")).is_true()
	assert_array(SaveSystem.player_data.scenes_seen).has_size(1)
	assert_int(_changes).is_equal(1)
	assert_bool(SaveFact.check(SaveFact.Kind.SCENE_SEEN, 0, SaveSystem.player_data, &"daughter_to_bed")).is_true()
	assert_bool(SaveFact.check(SaveFact.Kind.SCENE_SEEN, 0, SaveSystem.player_data, &"other")).is_false()

func test_a_death_forgets_it_and_a_bench_keeps_it() -> void:
	SaveSystem.mark_scene_seen(&"daughter_to_bed")
	SaveSystem.rewind()
	assert_bool(SaveSystem.is_scene_seen(&"daughter_to_bed")).is_false()
	SaveSystem.mark_scene_seen(&"daughter_to_bed")
	SaveSystem.commit()
	SaveSystem.rewind()
	assert_bool(SaveSystem.is_scene_seen(&"daughter_to_bed")).is_true()

func test_an_old_save_loads_with_none_seen() -> void:
	assert_array(PlayerData.new().scenes_seen).is_empty()
