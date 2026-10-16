class_name PauseMenu
extends MenuScreen
## The pause screen. Quitting, to the title or the desktop, asks first: progress since the last bench is lost.

signal resume_requested
## "Skip scene": the cutscene lands its end state (systems/cutscenes).
signal skip_scene_requested
signal quit_to_title_requested
signal quit_game_requested

## Px the box grows by while "Skip scene" shows: one entry and its gap, in art px.
const SKIP_ROOM := 20.0
## Art px between the panel's bottom and the intent line.
const INTENT_GAP := 6.0

## Asked as the menu opens: whether "Skip scene" shows. Game sets it to CutsceneDirector.can_skip.
var can_skip: Callable = func() -> bool: return false
## Asked as the menu opens: the current intent's text key, empty for none (systems/notices). Game sets it to
## NoticeWatcher.intent_key.
var intent: Callable = func() -> String: return ""
## The entry each confirmation returns focus to.
var _asked_by: Dictionary[ConfirmPanel, Button] = {}

@onready var _box: Control = %Box
@onready var _title: Label = %Title
@onready var _resume: Button = %Resume
@onready var _skip_scene: Button = %SkipScene
@onready var _panel: Control = %Panel
@onready var _entries: Control = %Entries
@onready var _intent: Label = %Intent
@onready var _quit_to_title: Button = %QuitToTitle
@onready var _quit_game: Button = %QuitGame
@onready var _confirm_quit_to_title: ConfirmPanel = %ConfirmQuitToTitle
@onready var _confirm_quit: ConfirmPanel = %ConfirmQuit


func _ready() -> void:
	_title.text = tr("PAUSE_TITLE")
	_resume.text = tr("PAUSE_RESUME")
	_skip_scene.text = tr("PAUSE_SKIP_SCENE")
	_quit_to_title.text = tr("PAUSE_QUIT_TO_TITLE")
	_quit_game.text = tr("PAUSE_QUIT_GAME")
	_asked_by[_confirm_quit_to_title] = _quit_to_title
	_asked_by[_confirm_quit] = _quit_game
	_resume.pressed.connect(resume_requested.emit)
	_skip_scene.pressed.connect(skip_scene_requested.emit)
	_quit_to_title.pressed.connect(_ask.bind(_confirm_quit_to_title))
	_quit_game.pressed.connect(_ask.bind(_confirm_quit))
	_confirm_quit_to_title.confirmed.connect(quit_to_title_requested.emit)
	_confirm_quit.confirmed.connect(quit_game_requested.emit)
	for confirm: ConfirmPanel in _asked_by:
		confirm.cancelled.connect(step_back)

func open() -> void:
	var skip := bool(can_skip.call())
	if skip != _skip_scene.visible:
		var grow := SKIP_ROOM if skip else -SKIP_ROOM
		_panel.offset_bottom += grow
		_entries.offset_bottom += grow
		_skip_scene.visible = skip
	_show_intent(str(intent.call()))
	show()
	_show_box(_resume)

func close() -> void:
	for confirm: ConfirmPanel in _asked_by:
		confirm.close()
	hide()

func step_back() -> bool:
	for confirm: ConfirmPanel in _asked_by:
		if confirm.visible:
			confirm.close()
			_show_box(_asked_by[confirm])
			return true
	return false

func is_confirming() -> bool:
	return _asked_by.keys().any(func(confirm: ConfirmPanel) -> bool: return confirm.visible)

## The intent line shown, translated; empty when none.
func shown_intent() -> String:
	return _intent.text if _intent.visible else ""

func _ask(confirm: ConfirmPanel) -> void:
	_box.hide()
	confirm.open()

## The intent line sits under the panel, whose height follows "Skip scene".
func _show_intent(key: String) -> void:
	_intent.visible = not key.is_empty()
	_intent.text = tr(key) if _intent.visible else ""
	var height := _intent.offset_bottom - _intent.offset_top
	_intent.offset_top = _panel.offset_bottom + INTENT_GAP
	_intent.offset_bottom = _intent.offset_top + height

func _show_box(focus: Button) -> void:
	_box.show()
	focus.grab_focus()
