class_name PlayerInput
extends CharacterController
## Translates raw hardware input into player intent.
## Continuous state is exposed as read-only properties; discrete actions are
## signals inherited from CharacterController (see that class for the rule).

signal attack_pressed
signal jump_pressed
signal jump_canceled
signal roll_pressed
signal draw_memorina_pressed
signal note_pressed(note: Enums.Note)

## Which action plays which note. A dictionary rather than four branches
## because the mapping is data, and every entry behaves identically.
const NOTE_ACTIONS: Dictionary = {
	&"note_up": Enums.Note.UP,
	&"note_down": Enums.Note.DOWN,
	&"note_left": Enums.Note.LEFT,
	&"note_right": Enums.Note.RIGHT,
}

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
	if event.is_action_pressed("draw_memorina"):
		draw_memorina_pressed.emit()
	# Deliberately unconditional: this node reports what the hardware did and
	# never asks whether the instrument happens to be out. Notes arriving while
	# it is sheathed are dropped by MemorinaComponent, which is the node that
	# actually knows.
	for action: StringName in NOTE_ACTIONS:
		if event.is_action_pressed(action):
			note_pressed.emit(NOTE_ACTIONS[action])

func _get_direction() -> float:
	return Input.get_axis("move_left", "move_right")
