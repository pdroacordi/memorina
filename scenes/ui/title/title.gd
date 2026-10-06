class_name Title
extends Control
## The title: New game, Continue and Quit game, and the slot screen behind them. It owns the saves list and every SaveSystem call.

## Loaded at swap time: the game exports this scene, so a PackedScene export would be a cycle.
@export_file("*.tscn") var game_scene: String = ""

var _saves: Array[PlayerData] = []
## The main entry the slot screen returns focus to.
var _opened_by: Button
## Set once a slot is chosen; every later press, key or click, is ignored.
var _leaving: bool = false

@onready var _main: Control = %Main
@onready var _new_game: Button = %NewGame
@onready var _continue: Button = %Continue
@onready var _quit_game: Button = %QuitGame
@onready var _slot_screen: SlotScreen = %SlotScreen
@onready var _fade: Fade = %Fade
@onready var _menu_input: MenuInput = $MenuInput


func _ready() -> void:
	_new_game.text = tr("TITLE_NEW_GAME")
	_continue.text = tr("TITLE_CONTINUE")
	_quit_game.text = tr("TITLE_QUIT_GAME")
	_new_game.pressed.connect(_on_new_game)
	_continue.pressed.connect(_open_slots.bind(SlotScreen.Purpose.LOAD, _continue))
	_quit_game.pressed.connect(_quit)
	_slot_screen.chosen.connect(_on_chosen)
	_slot_screen.erase_confirmed.connect(_on_erase_confirmed)
	_slot_screen.overwrite_confirmed.connect(_on_overwrite_confirmed)
	# Esc is `pause` and B is `ui_cancel`; on the title both only step back.
	_menu_input.pause_pressed.connect(_step_back)
	_menu_input.back_pressed.connect(_step_back)
	_slot_screen.close()
	show_saves(SaveSystem.read_slots())
	_focus_main()
	_fade.to_clear()

## Takes the slots' saves in slot order (null is empty); Continue is greyed when there is none.
func show_saves(saves: Array[PlayerData]) -> void:
	_saves = saves
	var any := SaveSlots.latest(saves) > 0
	_continue.disabled = not any
	_continue.focus_mode = Control.FOCUS_ALL if any else Control.FOCUS_NONE

func is_showing_slots() -> bool:
	return _slot_screen.visible

func is_leaving() -> bool:
	return _leaving

func _on_new_game() -> void:
	var slot := SaveSlots.first_empty(_saves)
	if slot > 0:
		_play(slot, true)
	else:
		_open_slots(SlotScreen.Purpose.NEW, _new_game)

func _open_slots(purpose: SlotScreen.Purpose, opener: Button) -> void:
	if _leaving:
		return
	_opened_by = opener
	_main.hide()
	_slot_screen.open(purpose, _saves)

func _on_chosen(slot: int) -> void:
	_play(slot, _saves[slot - 1] == null)

func _on_erase_confirmed(slot: int) -> void:
	if _leaving:
		return
	SaveSystem.delete_slot(slot)
	show_saves(SaveSystem.read_slots())
	if _slot_screen.purpose() == SlotScreen.Purpose.LOAD and SaveSlots.latest(_saves) == 0:
		_show_main()
	else:
		_slot_screen.show_saves(_saves, slot)

## The old save is deleted at Yes: the question says it will be erased.
func _on_overwrite_confirmed(slot: int) -> void:
	if _leaving:
		return
	SaveSystem.delete_slot(slot)
	_play(slot, true)

func _show_main() -> void:
	_slot_screen.close()
	_main.show()
	if _opened_by != null and not _opened_by.disabled:
		_opened_by.grab_focus()
	else:
		_focus_main()

func _focus_main() -> void:
	if _continue.disabled:
		_new_game.grab_focus()
	else:
		_continue.grab_focus()

func _step_back() -> void:
	if _leaving or not _slot_screen.visible:
		return
	if not _slot_screen.step_back():
		_show_main()

func _play(slot: int, fresh: bool) -> void:
	if _leaving:
		return
	_leaving = true
	# The fade covers everything, so stopping the mouse on it keeps clicks off the buttons under it.
	_fade.mouse_filter = Control.MOUSE_FILTER_STOP
	get_viewport().gui_release_focus()
	SaveSystem.begin_slot(slot, fresh)
	await _fade.to_black()
	_swap_to_game.call_deferred()

func _swap_to_game() -> void:
	SceneSwap.replace(self, load(game_scene) as PackedScene)

## Nothing is unsaved at the title, so it quits without asking.
func _quit() -> void:
	if not _leaving:
		get_tree().quit()
