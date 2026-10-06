class_name Screens
extends Control
## Opens and closes the menu screens on MenuInput's presses and asks the world, through signals, to hold for them.

signal hold_requested
signal release_requested
## Ivo hears no input while a blocking screen is open; the world still runs.
signal block_requested
signal unblock_requested
## The Blackout is drawn; the world stays held until it is swapped out.
signal quit_to_title_requested
signal quit_game_requested

## Screens that stop everything behind them while open; the map does not.
const HOLDING: Array[ScreenRouter.Kind] = [ScreenRouter.Kind.PAUSE, ScreenRouter.Kind.NOTEBOOK]
## Screens that only stop Ivo from acting.
const BLOCKING: Array[ScreenRouter.Kind] = [ScreenRouter.Kind.MAP]

var _open: ScreenRouter.Kind = ScreenRouter.Kind.NONE
var _locked: bool = false
## Set once the Blackout starts; every press after it is refused.
var _leaving: bool = false
var _screens: Dictionary[ScreenRouter.Kind, MenuScreen] = {}

@onready var _menu_input: MenuInput = $MenuInput
@onready var _dim: ColorRect = $Dim
@onready var _pause_menu: PauseMenu = $PauseMenu
@onready var _map: MapScreen = $MapScreen
@onready var _notebook: Notebook = $Notebook
@onready var _blackout: Fade = $Blackout


func _ready() -> void:
	_screens[ScreenRouter.Kind.PAUSE] = _pause_menu
	_screens[ScreenRouter.Kind.MAP] = _map
	_screens[ScreenRouter.Kind.NOTEBOOK] = _notebook
	_map.menu_input = _menu_input
	_menu_input.pause_pressed.connect(_on_press.bind(ScreenRouter.Press.PAUSE))
	_menu_input.notebook_pressed.connect(_on_press.bind(ScreenRouter.Press.NOTEBOOK))
	_menu_input.map_pressed.connect(_on_press.bind(ScreenRouter.Press.MAP))
	_menu_input.back_pressed.connect(_on_press.bind(ScreenRouter.Press.BACK))
	_menu_input.zoom_pressed.connect(_on_zoom)
	_menu_input.page_pressed.connect(_on_page)
	_notebook.close_requested.connect(_unless_leaving.bind(close))
	_pause_menu.resume_requested.connect(_unless_leaving.bind(close))
	_pause_menu.quit_to_title_requested.connect(_leave_for_title)
	_pause_menu.quit_game_requested.connect(_unless_leaving.bind(quit_game_requested.emit))
	_dim.hide()
	for screen: MenuScreen in _screens.values():
		screen.close()

func showing() -> ScreenRouter.Kind:
	return _open

## Closes everything and refuses to open again until the world is rebuilt (a death).
func lock() -> void:
	close()
	_locked = true

func close() -> void:
	_apply(ScreenRouter.Kind.NONE)

## Ivo, whom the map centres on and asks before it opens. Game sets it.
func set_map_subject(ivo: Player) -> void:
	_map.subject = ivo

## The notebook opens on the newest unread entry this watcher announced. Game sets it.
func set_notebook_watcher(watcher: NotebookWatcher) -> void:
	_notebook.watcher = watcher

## Any hit Ivo takes closes the map.
func close_map() -> void:
	if _open == ScreenRouter.Kind.MAP:
		close()

func _on_press(press: ScreenRouter.Press) -> void:
	if _leaving:
		get_viewport().set_input_as_handled()
		return
	var next := ScreenRouter.decide(_open, press, get_tree().paused, _locked)
	if next == _open:
		return
	if next != ScreenRouter.Kind.NONE and not (_screens.has(next) and _screens[next].can_open()):
		return
	# Consumed, so the pad's back (also roll) that resumes the game does not also roll.
	get_viewport().set_input_as_handled()
	if next == ScreenRouter.Kind.NONE and _screens[_open].step_back():
		return
	_apply(next)

## Z and X (pad A and X) are also jump and attack: consumed only while the map is open.
func _on_zoom(direction: int) -> void:
	if _leaving or _open != ScreenRouter.Kind.MAP:
		return
	get_viewport().set_input_as_handled()
	_map.zoom(direction)

## Left and right turn the notebook's pages; consumed only while it is open.
func _on_page(direction: int) -> void:
	if _leaving or _open != ScreenRouter.Kind.NOTEBOOK:
		return
	get_viewport().set_input_as_handled()
	_notebook.turn(direction)

## Stays held under a real-time Blackout, so nothing moves while the screen goes dark.
func _leave_for_title() -> void:
	if _leaving:
		return
	_leaving = true
	_locked = true
	# The Blackout covers the menu, so stopping the mouse on it keeps clicks off the buttons under it.
	_blackout.mouse_filter = Control.MOUSE_FILTER_STOP
	get_viewport().gui_release_focus()
	await _blackout.to_black()
	quit_to_title_requested.emit()

func _unless_leaving(action: Callable) -> void:
	if not _leaving:
		action.call()

## Releases only what this node held; a performance may freeze the world instead.
func _apply(next: ScreenRouter.Kind) -> void:
	if next == _open:
		return
	var was := _open
	_open = next
	if was != ScreenRouter.Kind.NONE:
		_screens[was].close()
		get_viewport().gui_release_focus()
	if HOLDING.has(was) and not HOLDING.has(next):
		release_requested.emit()
	if HOLDING.has(next) and not HOLDING.has(was):
		hold_requested.emit()
	if BLOCKING.has(was) and not BLOCKING.has(next):
		unblock_requested.emit()
	if BLOCKING.has(next) and not BLOCKING.has(was):
		block_requested.emit()
	_dim.visible = HOLDING.has(next)
	if next != ScreenRouter.Kind.NONE:
		_screens[next].open()
