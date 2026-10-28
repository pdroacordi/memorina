class_name SaveSystemFoundTest extends GdUnitTestSuite

## PIECE_FOUND is live data like heard: recorded once with progress_changed, committed by a bench, forgotten by a death.

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

func test_a_piece_is_found_once() -> void:
	SaveSystem.mark_found(&"woods_hut_letter")
	SaveSystem.mark_found(&"woods_hut_letter")
	assert_bool(SaveSystem.has_found(&"woods_hut_letter")).is_true()
	assert_array(SaveSystem.player_data.found_pieces).has_size(1)
	assert_int(_changes).is_equal(1)
	assert_bool(SaveFact.check(SaveFact.Kind.PIECE_FOUND, 0, SaveSystem.player_data, &"woods_hut_letter")).is_true()
	assert_bool(SaveFact.check(SaveFact.Kind.PIECE_FOUND, 0, SaveSystem.player_data, &"other")).is_false()

func test_a_death_forgets_it_and_a_bench_keeps_it() -> void:
	SaveSystem.mark_found(&"woods_hut_letter")
	SaveSystem.rewind()
	assert_bool(SaveSystem.has_found(&"woods_hut_letter")).is_false()
	SaveSystem.mark_found(&"woods_hut_letter")
	SaveSystem.commit()
	SaveSystem.rewind()
	assert_bool(SaveSystem.has_found(&"woods_hut_letter")).is_true()

func test_an_old_save_loads_with_none_found() -> void:
	assert_array(PlayerData.new().found_pieces).is_empty()
