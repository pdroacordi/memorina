class_name TitleTest extends GdUnitTestSuite

## The title's main column: Continue greyed with no save, New game in the first empty slot or the slot screen when
## all are used, and back returning to the entry that opened the slot screen.

const TITLE := preload("res://scenes/ui/title/title.tscn")

var _title: Title
var _menu_input: MenuInput


# Erase and play call SaveSystem; memory only, so no run can touch a real slot.
func before() -> void:
	SaveSystem.use_memory_only()

func before_test() -> void:
	_title = auto_free(TITLE.instantiate()) as Title
	add_child(_title)
	_menu_input = _title.get_node("MenuInput") as MenuInput

func test_the_main_column_is_new_game_continue_quit() -> void:
	var names: Array[String] = []
	for entry: Node in _title.find_child("Entries").get_children():
		names.append(entry.name)
	assert_array(names).contains_exactly(["NewGame", "Continue", "QuitGame"])

## A headless run has no disk, so there is no save to continue.
func test_with_no_save_continue_is_greyed_and_new_game_is_focused() -> void:
	var continue_entry := _entry("Continue")
	assert_bool(continue_entry.disabled).is_true()
	assert_int(continue_entry.focus_mode).is_equal(Control.FOCUS_NONE)
	assert_str(_focused()).is_equal("NewGame")

func test_continue_is_enabled_when_any_slot_is_used() -> void:
	_title.show_saves(_saves([false, true, false]))
	assert_bool(_entry("Continue").disabled).is_false()
	assert_int(_entry("Continue").focus_mode).is_equal(Control.FOCUS_ALL)

func test_continue_opens_the_slot_screen_and_back_returns_to_it() -> void:
	_title.show_saves(_saves([false, true, false]))
	_entry("Continue").pressed.emit()
	assert_bool(_title.is_showing_slots()).is_true()
	assert_bool((_title.find_child("Main") as Control).visible).is_false()
	assert_int(_slot_screen().purpose()).is_equal(SlotScreen.Purpose.LOAD)
	_menu_input.back_pressed.emit()
	assert_bool(_title.is_showing_slots()).is_false()
	assert_str(_focused()).is_equal("Continue")

func test_new_game_with_every_slot_used_opens_the_slot_screen_to_overwrite() -> void:
	_title.show_saves(_saves([true, true, true]))
	_entry("NewGame").pressed.emit()
	assert_bool(_title.is_showing_slots()).is_true()
	assert_int(_slot_screen().purpose()).is_equal(SlotScreen.Purpose.NEW)
	_menu_input.pause_pressed.emit()
	assert_bool(_title.is_showing_slots()).is_false()
	assert_str(_focused()).is_equal("NewGame")

## Title owns the saves: a confirmed erase deletes, re-reads (headless: all empty) and, with nothing left to continue, returns to main.
func test_erasing_the_last_save_returns_to_main_with_continue_greyed() -> void:
	_title.show_saves(_saves([false, true, false]))
	_entry("Continue").pressed.emit()
	(_slot_screen().find_child("Slot2").find_child("Erase") as Button).pressed.emit()
	(_slot_screen().find_child("ConfirmErase").find_child("Yes") as Button).pressed.emit()
	assert_bool(_title.is_showing_slots()).is_false()
	assert_bool(_entry("Continue").disabled).is_true()
	assert_str(_focused()).is_equal("NewGame")

## Clicks reach Buttons directly: once a slot is chosen, no Erase or overwrite may act, and the fade stops the mouse.
func test_buttons_pressed_while_leaving_erase_and_overwrite_nothing() -> void:
	_title.show_saves(_saves([true, true, true]))
	_entry("NewGame").pressed.emit()
	_pick_and_confirm_overwrite(1)
	assert_bool(_title.is_leaving()).is_true()
	assert_int((_title.find_child("Fade") as Control).mouse_filter).is_equal(Control.MOUSE_FILTER_STOP)
	(_slot_screen().find_child("Slot2").find_child("Erase") as Button).pressed.emit()
	(_slot_screen().find_child("ConfirmErase").find_child("Yes") as Button).pressed.emit()
	_pick_and_confirm_overwrite(3)
	_entry("Continue").pressed.emit()
	_menu_input.back_pressed.emit()
	assert_bool(_entry("Continue").disabled).is_false()
	assert_bool(_title.is_showing_slots()).is_true()

func test_every_label_is_translated() -> void:
	assert_str(_entry("NewGame").text).is_equal(tr("TITLE_NEW_GAME"))
	assert_str(_entry("Continue").text).is_equal(tr("TITLE_CONTINUE"))
	assert_str(_entry("QuitGame").text).is_equal(tr("TITLE_QUIT_GAME"))

## The title starts on a running clock and must not inherit ALWAYS from a parent such as the playtest runner.
func test_the_title_is_pausable() -> void:
	assert_int(_title.process_mode).is_equal(Node.PROCESS_MODE_PAUSABLE)

func _saves(used: Array[bool]) -> Array[PlayerData]:
	var saves: Array[PlayerData] = []
	for is_used: bool in used:
		saves.append(PlayerData.new() if is_used else null)
	return saves

func _pick_and_confirm_overwrite(slot: int) -> void:
	(_slot_screen().find_child("Slot%d" % slot).find_child("Card") as Button).pressed.emit()
	(_slot_screen().find_child("ConfirmOverwrite").find_child("Yes") as Button).pressed.emit()

func _entry(entry_name: String) -> Button:
	return _title.find_child(entry_name) as Button

func _slot_screen() -> SlotScreen:
	return _title.find_child("SlotScreen") as SlotScreen

func _focused() -> String:
	var owner := get_viewport().gui_get_focus_owner()
	return owner.name if owner != null else ""
