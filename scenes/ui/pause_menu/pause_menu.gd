class_name PauseMenu
extends MenuScreen
## The pause screen. Quitting, to the title or the desktop, asks first: progress since the last bench is lost.

signal resume_requested
signal quit_to_title_requested
signal quit_game_requested

## The entry each confirmation returns focus to.
var _asked_by: Dictionary[ConfirmPanel, Button] = {}

@onready var _box: Control = %Box
@onready var _title: Label = %Title
@onready var _resume: Button = %Resume
@onready var _quit_to_title: Button = %QuitToTitle
@onready var _quit_game: Button = %QuitGame
@onready var _confirm_quit_to_title: ConfirmPanel = %ConfirmQuitToTitle
@onready var _confirm_quit: ConfirmPanel = %ConfirmQuit


func _ready() -> void:
	_title.text = tr("PAUSE_TITLE")
	_resume.text = tr("PAUSE_RESUME")
	_quit_to_title.text = tr("PAUSE_QUIT_TO_TITLE")
	_quit_game.text = tr("PAUSE_QUIT_GAME")
	_asked_by[_confirm_quit_to_title] = _quit_to_title
	_asked_by[_confirm_quit] = _quit_game
	_resume.pressed.connect(resume_requested.emit)
	_quit_to_title.pressed.connect(_ask.bind(_confirm_quit_to_title))
	_quit_game.pressed.connect(_ask.bind(_confirm_quit))
	_confirm_quit_to_title.confirmed.connect(quit_to_title_requested.emit)
	_confirm_quit.confirmed.connect(quit_game_requested.emit)
	for confirm: ConfirmPanel in _asked_by:
		confirm.cancelled.connect(step_back)

func open() -> void:
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

func _ask(confirm: ConfirmPanel) -> void:
	_box.hide()
	confirm.open()

func _show_box(focus: Button) -> void:
	_box.show()
	focus.grab_focus()
