class_name PlayerInput
extends Node
## Translates raw hardware input into player intent.
## Continuous state is exposed as read-only properties; discrete actions are signals.

signal jump_pressed
signal jump_canceled

var direction: float:
	get: return Input.get_axis("move_left", "move_right")

var look_direction: float:
	get: return Input.get_axis("look_up", "look_down")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		jump_pressed.emit()
	elif event.is_action_released("jump"):
		jump_canceled.emit()
