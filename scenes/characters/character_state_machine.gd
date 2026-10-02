class_name CharacterStateMachine
extends RefCounted
## Maps owner-defined integer states to handlers; the owner drives updates each physics frame.

## Observers can react to state changes without owner-specific callbacks.
signal state_changed(from: int, to: int)

const NONE: int = -1

var current: int = NONE
var _handlers: Dictionary = {}


func add_state(id: int, handler: Callable) -> void:
	if _handlers.has(id):
		push_error("CharacterStateMachine: state %d already registered" % id)
		return
	_handlers[id] = handler

func has_state(id: int) -> bool:
	return _handlers.has(id)

func transition_to(id: int) -> void:
	if id == current:
		return
	if not has_state(id):
		push_error("CharacterStateMachine: cannot transition to unregistered state %d" % id)
		return

	var previous: int = current
	current = id
	state_changed.emit(previous, id)

func update(delta: float) -> void:
	if current == NONE:
		return
	_handlers[current].call(delta)
