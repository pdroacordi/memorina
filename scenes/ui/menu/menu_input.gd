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

## Map pan intent, -1..1 per axis.
var pan: Vector2:
	get: return Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

## Whether left or right was held as of the last event about it; a stick reports pressed on every motion.
var _left_held: bool = false
var _right_held: bool = false


## At most one signal per event, toggles before back: Esc is both `pause` and `ui_cancel`.
func _input(event: InputEvent) -> void:
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
