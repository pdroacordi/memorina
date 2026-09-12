class_name PlayerInput
extends CharacterController
## Translates raw hardware input into player intent.
## Continuous state is exposed as read-only properties; discrete actions are
## signals inherited from CharacterController (see that class for the rule).

signal attack_pressed
signal jump_pressed
signal jump_canceled
signal roll_pressed

# Camera-peek intent, deliberately player-only: enemies have no camera, so
# this stays an inline getter on PlayerInput rather than moving to the base.
var look_direction: float:
	get: return Input.get_axis("look_up", "look_down")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		jump_pressed.emit()
	elif event.is_action_released("jump"):
		jump_canceled.emit()
	if event.is_action_pressed("roll"):
		roll_pressed.emit()
	if event.is_action_pressed("attack"):
		attack_pressed.emit()

func _get_direction() -> float:
	return Input.get_axis("move_left", "move_right")
