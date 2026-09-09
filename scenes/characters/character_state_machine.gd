class_name CharacterStateMachine
extends RefCounted
## Selects which behaviour runs on a given frame and dispatches to it. A plain
## RefCounted, not a Node — it has no exports and no place in the scene tree,
## and its owner drives it explicitly each physics frame. States are integers
## (the owner supplies its own enum) mapped to Callables, so the same machine
## serves motion states for one character and, later, behaviour phases for
## another.

## WHY: lets animation, audio or telemetry react to a transition without the
## owner having to notify each of them by hand.
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
