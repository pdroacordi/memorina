class_name AIController
extends CharacterController
## Base controller that updates AI state and exposes its chosen movement direction.

## Side the body should face, -1/0/1; 0 keeps the current facing. Separate from `direction` so a creature can turn without walking.
var facing_direction: float:
	get = _get_facing_direction

var _states := CharacterStateMachine.new()
var _current_direction: float = 0.0


## Called before the owning Character reads direction so state timers advance once per physics frame.
func tick(delta: float) -> void:
	_states.transition_to(_select_state())
	_states.update(delta)

func handle_wall_contact() -> void:
	pass

func _get_direction() -> float:
	return _current_direction

func _get_facing_direction() -> float:
	return direction

## Subclasses choose the registered state active this frame.
func _select_state() -> int:
	return CharacterStateMachine.NONE
