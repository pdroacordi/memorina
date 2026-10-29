class_name SaveSystemSeedsTest extends GdUnitTestSuite

## Caches taken, offers bought and rumours are live data: each recorded once with progress_changed, forgotten together by a death.

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

func test_each_writer_emits_once_and_a_repeat_is_silent() -> void:
	SaveSystem.take_cache(&"threshold_ravine_cache")
	SaveSystem.take_cache(&"threshold_ravine_cache")
	SaveSystem.buy_offer(&"map_threshold")
	SaveSystem.buy_offer(&"map_threshold")
	SaveSystem.add_rumour(&"woods_hut_letter")
	SaveSystem.add_rumour(&"woods_hut_letter")
	assert_int(_changes).is_equal(3)
	assert_bool(SaveSystem.has_cache(&"threshold_ravine_cache")).is_true()
	assert_array(SaveSystem.player_data.caches_taken).has_size(1)
	assert_array(SaveSystem.player_data.offers_bought).contains_exactly([&"map_threshold"])
	assert_array(SaveSystem.player_data.rumours).contains_exactly([&"woods_hut_letter"])

func test_a_death_forgets_all_three_and_a_bench_keeps_them() -> void:
	SaveSystem.take_cache(&"threshold_ravine_cache")
	SaveSystem.buy_offer(&"map_threshold")
	SaveSystem.add_rumour(&"woods_hut_letter")
	SaveSystem.rewind()
	assert_array(SaveSystem.player_data.caches_taken).is_empty()
	assert_array(SaveSystem.player_data.offers_bought).is_empty()
	assert_array(SaveSystem.player_data.rumours).is_empty()
	SaveSystem.take_cache(&"threshold_ravine_cache")
	SaveSystem.buy_offer(&"map_threshold")
	SaveSystem.commit()
	SaveSystem.rewind()
	assert_bool(SaveSystem.has_cache(&"threshold_ravine_cache")).is_true()
	assert_array(SaveSystem.player_data.offers_bought).contains_exactly([&"map_threshold"])
