class_name PauseMenu
extends MenuScreen
## The pause screen. Quitting asks first: progress since the last bench is lost.

signal resume_requested
signal quit_game_requested

@onready var _box: Control = %Box
@onready var _title: Label = %Title
@onready var _resume: Button = %Resume
@onready var _quit_game: Button = %QuitGame
@onready var _confirm_quit: ConfirmPanel = %ConfirmQuit


func _ready() -> void:
	_title.text = tr("PAUSE_TITLE")
	_resume.text = tr("PAUSE_RESUME")
	_quit_game.text = tr("PAUSE_QUIT_GAME")
	_resume.pressed.connect(resume_requested.emit)
	_quit_game.pressed.connect(_ask_quit)
	_confirm_quit.confirmed.connect(quit_game_requested.emit)
	_confirm_quit.cancelled.connect(step_back)

func open() -> void:
	show()
	_show_box(_resume)

func close() -> void:
	_confirm_quit.close()
	hide()

func step_back() -> bool:
	if not is_confirming():
		return false
	_confirm_quit.close()
	_show_box(_quit_game)
	return true

func is_confirming() -> bool:
	return _confirm_quit.visible

func _ask_quit() -> void:
	_box.hide()
	_confirm_quit.open()

func _show_box(focus: Button) -> void:
	_box.show()
	focus.grab_focus()
