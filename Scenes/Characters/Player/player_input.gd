extends Node
class_name PlayerInput

signal direction_changed(direction: float)
signal jump_pressed
signal jump_canceled

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		jump_pressed.emit()
	elif event.is_action_released("jump"):
		jump_canceled.emit()

func _physics_process(delta: float) -> void:
	direction_changed.emit(Input.get_axis("move_left", "move_right"))
