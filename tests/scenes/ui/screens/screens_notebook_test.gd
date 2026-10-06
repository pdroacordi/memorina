class_name ScreensNotebookTest extends GdUnitTestSuite

## E opens the notebook held and dimmed; left and right turn its pages; E, Esc and B play it shut before it releases.

const SCREENS := preload("res://scenes/ui/screens/screens.tscn")

var _screens: Screens
var _menu_input: MenuInput
var _notebook: Notebook
var _requests: Array[String] = []


func before_test() -> void:
	SaveSystem.begin("", true)
	_requests.clear()
	_screens = auto_free(SCREENS.instantiate()) as Screens
	add_child(_screens)
	_menu_input = _screens.get_node("MenuInput") as MenuInput
	_notebook = _screens.get_node("Notebook") as Notebook
	_notebook.frame_seconds = 0.0
	_screens.hold_requested.connect(func() -> void: _requests.append("hold"))
	_screens.release_requested.connect(func() -> void: _requests.append("release"))

func after_test() -> void:
	SaveSystem.begin("", true)

func _settle() -> void:
	for i: int in 4:
		await await_idle_frame()

func test_the_notebook_opens_held_and_dimmed() -> void:
	_menu_input.notebook_pressed.emit()
	assert_int(_screens.showing()).is_equal(ScreenRouter.Kind.NOTEBOOK)
	assert_array(_requests).contains_exactly(["hold"])
	assert_bool((_screens.get_node("Dim") as CanvasItem).visible).is_true()

func test_each_closing_press_plays_the_book_shut_before_the_release() -> void:
	for press: Callable in [_menu_input.notebook_pressed.emit, _menu_input.pause_pressed.emit, _menu_input.back_pressed.emit]:
		_requests.clear()
		_menu_input.notebook_pressed.emit()
		await _settle()
		press.call()
		assert_int(_screens.showing()).is_equal(ScreenRouter.Kind.NOTEBOOK)
		assert_array(_requests).contains_exactly(["hold"])
		await _settle()
		assert_int(_screens.showing()).is_equal(ScreenRouter.Kind.NONE)
		assert_array(_requests).contains_exactly(["hold", "release"])

## Esc closes the notebook; it does not open the pause over it.
func test_pause_on_the_notebook_does_not_open_the_pause() -> void:
	_menu_input.notebook_pressed.emit()
	await _settle()
	_menu_input.pause_pressed.emit()
	await _settle()
	assert_int(_screens.showing()).is_equal(ScreenRouter.Kind.NONE)

func test_right_turns_to_the_next_section_only_while_open() -> void:
	_menu_input.page_pressed.emit(1)
	assert_int(_notebook.phase()).is_equal(Notebook.Phase.SHUT)
	_menu_input.notebook_pressed.emit()
	await _settle()
	var from := _notebook.section()
	_menu_input.page_pressed.emit(1)
	await _settle()
	assert_int(_notebook.section()).is_equal(from + 1)

func test_a_death_shuts_it_at_once() -> void:
	_menu_input.notebook_pressed.emit()
	_screens.lock()
	assert_int(_screens.showing()).is_equal(ScreenRouter.Kind.NONE)
	assert_int(_notebook.phase()).is_equal(Notebook.Phase.SHUT)
	assert_array(_requests).contains_exactly(["hold", "release"])
