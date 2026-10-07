class_name NotebookToastTest extends GdUnitTestSuite

## The quill fades in for a new entry and back out on its own.

const TOAST := preload("res://scenes/ui/notebook_toast/notebook_toast.tscn")

var _toast: NotebookToast


func before_test() -> void:
	_toast = auto_free(TOAST.instantiate()) as NotebookToast
	_toast.fade_in = 0.01
	# Longer than a headless frame (measured up to 0.14 s), so the shown check lands inside it.
	_toast.hold = 1.0
	_toast.fade_out = 0.01
	add_child(_toast)

func test_it_starts_hidden() -> void:
	assert_bool(_toast.is_showing()).is_false()

func test_a_hint_shows_then_fades() -> void:
	_toast.show_hint([&"song_freeze"])
	await get_tree().process_frame
	assert_bool(_toast.is_showing()).is_true()
	await await_millis(1500)
	assert_bool(_toast.is_showing()).is_false()
