class_name SaveMarkTest extends GdUnitTestSuite

## The quill answers a kept rest and goes away again: invisible until
## SaveSystem.saved, showing after it.

const MARK := preload("res://scenes/ui/save_mark/save_mark.tscn")

func test_the_quill_shows_only_when_a_rest_is_kept() -> void:
	var mark := auto_free(MARK.instantiate()) as SaveMark
	add_child(mark)
	assert_bool(mark.is_showing()).is_false()
	SaveSystem.saved.emit()
	await get_tree().process_frame
	assert_bool(mark.is_showing()).is_true()
