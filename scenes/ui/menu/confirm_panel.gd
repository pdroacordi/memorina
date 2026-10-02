class_name ConfirmPanel
extends Control
## A Yes/No question in the wood style. No takes the focus, so a repeated press never confirms.

signal confirmed
signal cancelled

## Translation key of the question.
@export var body_key: String = ""

@onready var _body: Label = %Body
@onready var _yes: Button = %Yes
@onready var _no: Button = %No


func _ready() -> void:
	_body.text = tr(body_key)
	_yes.text = tr("CONFIRM_YES")
	_no.text = tr("CONFIRM_NO")
	_yes.pressed.connect(confirmed.emit)
	_no.pressed.connect(cancelled.emit)

func open() -> void:
	show()
	_no.grab_focus()

func close() -> void:
	hide()
