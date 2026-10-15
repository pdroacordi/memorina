class_name DialogueBox
extends Control
## The bottom box a talk is shown in: name plate, portrait slot, typed text, and the choices of a question. It never
## reads the save; the director tells it what to show (systems/dialogue).

## The press after a line is fully typed.
signal advanced
signal chosen(index: int)

## Rows of a plain line's text.
const TEXT_ROWS := 3
## Rows of a question's text, above its choices.
const QUESTION_ROWS := 1
const MAX_CHOICES := 3
## Pack px of plate on each side of the name.
const PLATE_PAD := 6.0
## Widest name plate, in pack px.
const PLATE_MAX_WIDTH := 120.0
## Pack px the box moves up to open at the top: its panel from y 106 to y 20, under the life notes and the quill
## (HUD y 8 to 40).
const TOP_SHIFT := -86.0
## The plate's y in the box, in pack px: over the panel's top edge at the bottom, under its lower edge at the top,
## so it stays on screen and on the inner side.
const PLATE_Y_BOTTOM := 99.0
const PLATE_Y_TOP := 165.0

## Characters typed per real second.
@export var chars_per_second: float = 40.0
## Real seconds a stuttered word's first letter hangs before the word starts again (StutterText).
@export var stutter_hold: float = 0.22
## Real seconds between the letter vanishing and the word typing.
@export var stutter_gap: float = 0.08

var _typing: Tween
## Choice text keys waiting for the question to finish typing; empty for none.
var _pending_choices: PackedStringArray = PackedStringArray()
var _choosing: bool = false
var _choice_focus: int = 0
## Where the shown line's marked words start (StutterText).
var _stutters: PackedInt32Array = PackedInt32Array()

@onready var _box: Control = %Box
@onready var _plate: NinePatchRect = %Plate
@onready var _name: Label = %Name
@onready var _portrait: TextureRect = %Portrait
@onready var _text: Label = %Text
@onready var _continue: Button = %ContinueArea
@onready var _choice_buttons: Array[Button] = [%Choice0, %Choice1, %Choice2]
@onready var _next: KeyGlyph = %Next


func _ready() -> void:
	_text.visible_characters_behavior = TextServer.VC_CHARS_AFTER_SHAPING
	_continue.pressed.connect(_on_continue_pressed)
	_link(_continue, _continue, _continue)
	for i: int in _choice_buttons.size():
		_choice_buttons[i].pressed.connect(_on_choice_pressed.bind(i))
		_choice_buttons[i].focus_entered.connect(func() -> void: _choice_focus = i)
	_next.show_action(&"jump")
	hide()

# Closing the pause or the notebook releases GUI focus; the box takes it back.
func _notification(what: int) -> void:
	if what == NOTIFICATION_UNPAUSED:
		_focus_current()

## Opens the box at the top or the bottom of the screen; held until placed again.
func place(side: DialogueBoxSide.Side) -> void:
	var top := side == DialogueBoxSide.Side.TOP
	_box.position.y = TOP_SHIFT if top else 0.0
	_plate.position.y = PLATE_Y_TOP if top else PLATE_Y_BOTTOM

func show_line(speaker: Speaker, text_key: String) -> void:
	show()
	_end_choices()
	_pending_choices = PackedStringArray()
	_show_speaker(speaker)
	var parsed := StutterText.parse(tr(text_key))
	_text.text = parsed["text"]
	_stutters = parsed["starts"]
	_next.hide()
	_continue.show()
	_type()
	_focus_current()

## A question's choices, shown once it is typed. A `silent` ask (a gesture) clears the plate, portrait and text, open or
## not, and shows its choices at once.
func show_choices(keys: PackedStringArray, silent: bool = false) -> void:
	assert(keys.size() <= MAX_CHOICES, "A question offers at most %d choices" % MAX_CHOICES)
	if silent or not visible:
		show()
		if _typing != null:
			_typing.kill()
			_typing = null
		_end_choices()
		_show_speaker(null)
		_text.text = ""
		_stutters = PackedInt32Array()
		_next.hide()
	_pending_choices = keys
	if not is_typing():
		_reveal_choices()

func close() -> void:
	if _typing != null:
		_typing.kill()
		_typing = null
	_pending_choices = PackedStringArray()
	_end_choices()
	var focused := get_viewport().gui_get_focus_owner()
	# A hidden focused Button would still take the next ui_accept.
	if focused != null and is_ancestor_of(focused):
		focused.release_focus()
	hide()

func is_typing() -> bool:
	return _typing != null and _typing.is_valid() and _typing.is_running()

func is_choosing() -> bool:
	return _choosing

func text_label() -> Label:
	return _text

func name_label() -> Label:
	return _name

func choice_button(index: int) -> Button:
	return _choice_buttons[index]

## The plate width in pack px that `text` needs; the plate never grows past PLATE_MAX_WIDTH (dialogue_text_fit_test).
func plate_width(text: String) -> float:
	return _name.get_theme_font(&"font").get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1,
			_name.get_theme_font_size(&"font_size")).x + PLATE_PAD * 2.0

func _show_speaker(speaker: Speaker) -> void:
	_portrait.texture = speaker.portrait if speaker != null else null
	var named := speaker != null and not speaker.name_key.is_empty()
	_plate.visible = named
	if named:
		_name.text = tr(speaker.name_key)
		_plate.size.x = minf(plate_width(_name.text), PLATE_MAX_WIDTH)

func _type() -> void:
	if _typing != null:
		_typing.kill()
	_text.visible_characters = 0
	var total := _text.text.length()
	# Real time under the recall's slow motion; bound to the box, so a pause or hold stops it.
	_typing = create_tween().set_ignore_time_scale(true)
	var at := 0
	for start: int in _stutters:
		if start >= total:
			continue
		_type_to(at, start + 1)
		_typing.tween_interval(stutter_hold)
		_typing.tween_callback(_text.set.bind(&"visible_characters", start))
		_typing.tween_interval(stutter_gap)
		at = start
	_type_to(at, total)
	_typing.finished.connect(_on_typed)

func _type_to(from: int, to: int) -> void:
	var seconds := (to - from) / chars_per_second if chars_per_second > 0.0 else 0.0
	_typing.tween_property(_text, "visible_characters", to, seconds)

func _complete_typing() -> void:
	# A killed tween never emits finished (gotchas/a-killed-tween-never-emits-finished).
	_typing.kill()
	_text.visible_characters = -1
	_on_typed()

func _on_typed() -> void:
	_typing = null
	if _pending_choices.is_empty():
		_next.show()
	else:
		_reveal_choices()

func _reveal_choices() -> void:
	_continue.hide()
	_next.hide()
	_choosing = true
	var shown: Array[Button] = []
	for i: int in _choice_buttons.size():
		var button := _choice_buttons[i]
		button.visible = i < _pending_choices.size()
		if button.visible:
			button.text = tr(_pending_choices[i])
			shown.append(button)
	_pending_choices = PackedStringArray()
	for i: int in shown.size():
		_link(shown[i], shown[maxi(i - 1, 0)], shown[mini(i + 1, shown.size() - 1)])
	_choice_focus = 0
	_focus_current()

func _end_choices() -> void:
	_choosing = false
	for button: Button in _choice_buttons:
		button.hide()

func _focus_current() -> void:
	if not visible:
		return
	if _choosing:
		_choice_buttons[_choice_focus].grab_focus()
	else:
		_continue.grab_focus()

## Explicit neighbours, itself at either end and on both sides, so focus never leaves the box.
func _link(button: Button, above: Button, below: Button) -> void:
	var own := button.get_path_to(button)
	button.focus_neighbor_left = own
	button.focus_neighbor_right = own
	button.focus_neighbor_top = button.get_path_to(above)
	button.focus_neighbor_bottom = button.get_path_to(below)
	button.focus_previous = button.focus_neighbor_top
	button.focus_next = button.focus_neighbor_bottom

## The first press completes the line; the next one advances.
func _on_continue_pressed() -> void:
	if is_typing():
		_complete_typing()
	elif _pending_choices.is_empty():
		advanced.emit()

func _on_choice_pressed(index: int) -> void:
	if not _choosing:
		return
	_end_choices()
	_continue.show()
	_continue.grab_focus()
	chosen.emit(index)
