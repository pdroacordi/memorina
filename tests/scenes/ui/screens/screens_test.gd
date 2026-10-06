class_name ScreensTest extends GdUnitTestSuite

## Screens opens the pause menu, holds and releases once, steps back out of the
## quit confirmation before closing, and refuses everything once locked.

const SCREENS := preload("res://scenes/ui/screens/screens.tscn")

var _screens: Screens
var _menu_input: MenuInput
var _pause_menu: PauseMenu
var _requests: Array[String] = []


func before_test() -> void:
	_requests.clear()
	_screens = auto_free(SCREENS.instantiate()) as Screens
	add_child(_screens)
	_menu_input = _screens.get_node("MenuInput") as MenuInput
	_pause_menu = _screens.get_node("PauseMenu") as PauseMenu
	_screens.hold_requested.connect(func() -> void: _requests.append("hold"))
	_screens.release_requested.connect(func() -> void: _requests.append("release"))
	_screens.quit_game_requested.connect(func() -> void: _requests.append("quit"))
	_screens.quit_to_title_requested.connect(func() -> void: _requests.append("title"))

func test_escape_opens_the_pause_menu_held_and_dimmed() -> void:
	_menu_input._input(_escape())
	assert_int(_screens.showing()).is_equal(ScreenRouter.Kind.PAUSE)
	assert_array(_requests).contains_exactly(["hold"])
	assert_bool(_pause_menu.visible).is_true()
	assert_bool((_screens.get_node("Dim") as CanvasItem).visible).is_true()
	assert_str(_focused()).is_equal("Resume")

func test_pause_again_resumes_and_releases_focus() -> void:
	_menu_input.pause_pressed.emit()
	_menu_input.pause_pressed.emit()
	assert_int(_screens.showing()).is_equal(ScreenRouter.Kind.NONE)
	assert_array(_requests).contains_exactly(["hold", "release"])
	assert_bool(_pause_menu.visible).is_false()
	assert_str(_focused()).is_equal("")

func test_resume_closes_the_menu() -> void:
	_menu_input.pause_pressed.emit()
	(_pause_menu.find_child("Resume") as Button).pressed.emit()
	assert_int(_screens.showing()).is_equal(ScreenRouter.Kind.NONE)
	assert_array(_requests).contains_exactly(["hold", "release"])

func test_quit_game_asks_first_with_no_focused() -> void:
	_menu_input.pause_pressed.emit()
	(_pause_menu.find_child("QuitGame") as Button).pressed.emit()
	assert_bool(_pause_menu.is_confirming()).is_true()
	assert_str(_focused()).is_equal("No")
	assert_array(_requests).contains_exactly(["hold"])

func test_back_and_no_return_to_the_menu_on_quit_game() -> void:
	_menu_input.pause_pressed.emit()
	var quit_game := _pause_menu.find_child("QuitGame") as Button
	quit_game.pressed.emit()
	_menu_input.back_pressed.emit()
	assert_bool(_pause_menu.is_confirming()).is_false()
	assert_int(_screens.showing()).is_equal(ScreenRouter.Kind.PAUSE)
	assert_str(_focused()).is_equal("QuitGame")
	quit_game.pressed.emit()
	(_pause_menu.find_child("No") as Button).pressed.emit()
	assert_bool(_pause_menu.is_confirming()).is_false()
	assert_int(_screens.showing()).is_equal(ScreenRouter.Kind.PAUSE)
	assert_array(_requests).contains_exactly(["hold"])

## Esc is the keyboard's back, so it leaves the confirmation before the menu.
func test_pause_on_the_confirmation_returns_to_the_menu() -> void:
	_menu_input.pause_pressed.emit()
	(_pause_menu.find_child("QuitGame") as Button).pressed.emit()
	_menu_input.pause_pressed.emit()
	assert_int(_screens.showing()).is_equal(ScreenRouter.Kind.PAUSE)
	assert_bool(_pause_menu.is_confirming()).is_false()

func test_yes_quits_the_game() -> void:
	_menu_input.pause_pressed.emit()
	(_pause_menu.find_child("QuitGame") as Button).pressed.emit()
	(_pause_menu.find_child("Yes") as Button).pressed.emit()
	assert_array(_requests).contains_exactly(["hold", "quit"])

func test_reopening_starts_on_the_menu_not_the_confirmation() -> void:
	_menu_input.pause_pressed.emit()
	(_pause_menu.find_child("QuitGame") as Button).pressed.emit()
	_screens.close()
	_menu_input.pause_pressed.emit()
	assert_bool(_pause_menu.is_confirming()).is_false()
	assert_str(_focused()).is_equal("Resume")

## Screens without a scene yet (notebook, map) are not opened.
func test_a_screen_that_does_not_exist_yet_stays_shut() -> void:
	_menu_input.notebook_pressed.emit()
	_menu_input.map_pressed.emit()
	assert_int(_screens.showing()).is_equal(ScreenRouter.Kind.NONE)
	assert_array(_requests).is_empty()

func test_lock_closes_releases_and_refuses() -> void:
	_menu_input.pause_pressed.emit()
	_screens.lock()
	assert_int(_screens.showing()).is_equal(ScreenRouter.Kind.NONE)
	assert_array(_requests).contains_exactly(["hold", "release"])
	_menu_input.pause_pressed.emit()
	assert_int(_screens.showing()).is_equal(ScreenRouter.Kind.NONE)
	assert_array(_requests).contains_exactly(["hold", "release"])

## The notebook will hold like the pause; the map never holds (it only blocks Ivo).
func test_pause_and_notebook_hold_and_the_map_does_not() -> void:
	assert_bool(Screens.HOLDING.has(ScreenRouter.Kind.PAUSE)).is_true()
	assert_bool(Screens.HOLDING.has(ScreenRouter.Kind.NOTEBOOK)).is_true()
	assert_bool(Screens.HOLDING.has(ScreenRouter.Kind.MAP)).is_false()

func test_every_label_is_translated() -> void:
	_menu_input.pause_pressed.emit()
	assert_str((_pause_menu.find_child("Title") as Label).text).is_equal(tr("PAUSE_TITLE"))
	assert_str((_pause_menu.find_child("Resume") as Button).text).is_not_equal("PAUSE_RESUME").is_not_empty()
	assert_str((_pause_menu.find_child("Body") as Label).text).is_not_equal("CONFIRM_QUIT_GAME").is_not_empty()

func test_quit_to_title_sits_between_resume_and_quit_game() -> void:
	var names: Array[String] = []
	for entry: Node in _pause_menu.find_child("Entries").get_children():
		names.append(entry.name)
	assert_array(names).contains_exactly(["Resume", "QuitToTitle", "QuitGame"])

func test_quit_to_title_asks_first_and_back_returns_to_it() -> void:
	_menu_input.pause_pressed.emit()
	(_pause_menu.find_child("QuitToTitle") as Button).pressed.emit()
	assert_bool(_pause_menu.is_confirming()).is_true()
	assert_str(_focused()).is_equal("No")
	_menu_input.back_pressed.emit()
	assert_bool(_pause_menu.is_confirming()).is_false()
	assert_int(_screens.showing()).is_equal(ScreenRouter.Kind.PAUSE)
	assert_str(_focused()).is_equal("QuitToTitle")
	assert_array(_requests).contains_exactly(["hold"])

## The world stays held under the Blackout; the swap is asked for once it is black.
func test_yes_blacks_out_still_held_then_asks_for_the_title_once() -> void:
	_menu_input.pause_pressed.emit()
	(_pause_menu.find_child("QuitToTitle") as Button).pressed.emit()
	var yes := _confirm_quit_to_title().find_child("Yes") as Button
	yes.pressed.emit()
	yes.pressed.emit()
	assert_array(_requests).contains_exactly(["hold"])
	await await_millis(800)
	assert_array(_requests).contains_exactly(["hold", "title"])
	assert_float((_screens.get_node("Blackout") as ColorRect).color.a).is_equal(1.0)

func test_no_press_is_obeyed_while_leaving_for_the_title() -> void:
	_menu_input.pause_pressed.emit()
	(_pause_menu.find_child("QuitToTitle") as Button).pressed.emit()
	(_confirm_quit_to_title().find_child("Yes") as Button).pressed.emit()
	_menu_input.pause_pressed.emit()
	_menu_input.back_pressed.emit()
	assert_int(_screens.showing()).is_equal(ScreenRouter.Kind.PAUSE)
	assert_array(_requests).contains_exactly(["hold"])

## Clicks reach Buttons, not MenuInput: the visible No, Resume and Quit game must not release or quit under the Blackout.
func test_buttons_pressed_while_leaving_neither_release_nor_quit() -> void:
	_menu_input.pause_pressed.emit()
	(_pause_menu.find_child("QuitToTitle") as Button).pressed.emit()
	(_confirm_quit_to_title().find_child("Yes") as Button).pressed.emit()
	(_confirm_quit_to_title().find_child("No") as Button).pressed.emit()
	(_pause_menu.find_child("Resume") as Button).pressed.emit()
	(_pause_menu.find_child("QuitGame") as Button).pressed.emit()
	(_pause_menu.find_child("ConfirmQuit").find_child("Yes") as Button).pressed.emit()
	assert_int(_screens.showing()).is_equal(ScreenRouter.Kind.PAUSE)
	assert_array(_requests).contains_exactly(["hold"])
	assert_int((_screens.get_node("Blackout") as Control).mouse_filter).is_equal(Control.MOUSE_FILTER_STOP)

## The Blackout is the pause menu's UI-05 fade: it must run while the time scale is 0.
func test_the_blackout_runs_in_real_time() -> void:
	assert_bool((_screens.get_node("Blackout") as Fade).real_time).is_true()

func _confirm_quit_to_title() -> ConfirmPanel:
	return _pause_menu.find_child("ConfirmQuitToTitle") as ConfirmPanel

func _focused() -> String:
	var owner := get_viewport().gui_get_focus_owner()
	return owner.name if owner != null else ""

func _escape() -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = KEY_ESCAPE
	event.physical_keycode = KEY_ESCAPE
	event.pressed = true
	return event
