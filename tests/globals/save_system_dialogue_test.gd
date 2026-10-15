class_name SaveSystemDialogueTest extends GdUnitTestSuite

## Heard and answered are written to the live save, once heard and the latest answer, and each write emits progress_changed.

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

func test_a_dialogue_is_heard_once() -> void:
	assert_bool(SaveSystem.is_dialogue_heard(&"trial_first")).is_false()
	SaveSystem.mark_dialogue_heard(&"trial_first")
	SaveSystem.mark_dialogue_heard(&"trial_first")
	assert_bool(SaveSystem.is_dialogue_heard(&"trial_first")).is_true()
	assert_array(SaveSystem.player_data.dialogues_heard).has_size(1)
	assert_int(_changes).is_equal(1)

func test_an_answer_asked_again_replaces_the_first() -> void:
	assert_str(String(SaveSystem.response_to(&"trial_keep"))).is_empty()
	SaveSystem.record_response(&"trial_keep", &"trial_keep_hold")
	SaveSystem.record_response(&"trial_keep", &"trial_keep_let_go")
	assert_str(String(SaveSystem.response_to(&"trial_keep"))).is_equal("trial_keep_let_go")
	assert_int(SaveSystem.player_data.responses.size()).is_equal(1)
	assert_int(_changes).is_equal(2)

## Live data, like every gain: a death before a bench forgets it.
func test_a_death_forgets_what_was_said_since_the_bench() -> void:
	SaveSystem.mark_dialogue_heard(&"trial_first")
	SaveSystem.record_response(&"trial_keep", &"trial_keep_hold")
	SaveSystem.rewind()
	assert_bool(SaveSystem.is_dialogue_heard(&"trial_first")).is_false()
	assert_str(String(SaveSystem.response_to(&"trial_keep"))).is_empty()
