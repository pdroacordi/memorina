class_name MenuInput
extends Node
## Reads the screen toggles and menu presses; one of the three InputEvent readers with PlayerInput and InputDevice.

signal pause_pressed
signal notebook_pressed
signal map_pressed
## +1 zooms in, -1 zooms out.
signal zoom_pressed(direction: int)
signal back_pressed
## +1 is the next page (right), -1 the previous (left).
signal page_pressed(direction: int)
## While capturing: a key (physical keycode) or pad button was pressed for a binding (systems/settings).
signal bind_pressed(device: KeyBindings.Device, code: int)
## While capturing: `pause` (Esc, Start) gave the capture up.
signal capture_cancelled

## Map pan intent, -1..1 per axis.
var pan: Vector2:
	get: return Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

## While true only `bind_pressed` and `capture_cancelled` are emitted, and every key and pad event is consumed.
var capturing: bool = false:
	set(value):
		if capturing and not value:
			# A direction held through the capture is not a new page edge.
			_left_held = Input.is_action_pressed("ui_left")
			_right_held = Input.is_action_pressed("ui_right")
		capturing = value

## Whether left or right was held as of the last event about it; a stick reports pressed on every motion.
var _left_held: bool = false
var _right_held: bool = false


## At most one signal per event, toggles before back: Esc is both `pause` and `ui_cancel`.
func _input(event: InputEvent) -> void:
	if capturing:
		_capture(event)
		return
	var page := _page_edge(event)
	if event.is_action_pressed("pause"):
		pause_pressed.emit()
	elif event.is_action_pressed("notebook"):
		notebook_pressed.emit()
	elif event.is_action_pressed("map"):
		map_pressed.emit()
	elif event.is_action_pressed("map_zoom_in"):
		zoom_pressed.emit(1)
	elif event.is_action_pressed("map_zoom_out"):
		zoom_pressed.emit(-1)
	elif event.is_action_pressed("ui_cancel"):
		back_pressed.emit()
	elif page != 0:
		page_pressed.emit(page)

## -1 or +1 on the press edge of ui_left or ui_right, else 0; see docs/knowledge/gotchas/a-stick-is-pressed-on-every-motion-event.md.
func _page_edge(event: InputEvent) -> int:
	var edge := 0
	if event.is_action("ui_left"):
		var held := event.is_action_pressed("ui_left", true)
		if held and not _left_held:
			edge = -1
		_left_held = held
	if event.is_action("ui_right"):
		var held := event.is_action_pressed("ui_right", true)
		if held and not _right_held:
			edge = 1
		_right_held = held
	return edge

## Consumed first: a handler may end the capture, and the press must still reach nothing else.
func _capture(event: InputEvent) -> void:
	if not (event is InputEventKey or event is InputEventJoypadButton or event is InputEventJoypadMotion):
		return
	if is_inside_tree():
		get_viewport().set_input_as_handled()
	if event.is_action_pressed("pause"):
		capture_cancelled.emit()
	elif event is InputEventKey and event.is_pressed() and not event.is_echo():
		bind_pressed.emit(KeyBindings.Device.KEYBOARD, KeyBindings.code_of(event, KeyBindings.Device.KEYBOARD))
	elif event is InputEventJoypadButton and event.is_pressed():
		bind_pressed.emit(KeyBindings.Device.PAD, (event as InputEventJoypadButton).button_index)
