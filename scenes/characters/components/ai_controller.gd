class_name AIController
extends CharacterController
## Generic base for any AI-driven character. Owns the mechanics that are true
## of AI regardless of what the AI actually is: a CharacterStateMachine
## driven once per frame via tick(), and an internally-selected `direction`.
## What the states ARE, and how one is chosen, is entirely up to subclasses
## (see EnemyAI for the common-enemy baseline). Never instantiated directly.

var _states := CharacterStateMachine.new()
var _current_direction: float = 0.0


## Called once per physics frame by the owning Character, BEFORE `direction`
## is read — state timers must only advance once per frame, so they live
## here rather than in a `_physics_process` override (which would run out of
## order relative to the owner's, per the parent-before-children rule in
## CLAUDE.md).
func tick(delta: float) -> void:
	_states.transition_to(_select_state())
	_states.update(delta)

## No-op by default; a subclass whose wander-style state should react to
## hitting a wall overrides this (see EnemyAI).
func handle_wall_contact() -> void:
	pass

func _get_direction() -> float:
	return _current_direction

## Must be overridden: picks which registered state should be active this
## frame. Base default (CharacterStateMachine.NONE) is only ever reachable
## if AIController is used unsubclassed, which it shouldn't be.
func _select_state() -> int:
	return CharacterStateMachine.NONE
