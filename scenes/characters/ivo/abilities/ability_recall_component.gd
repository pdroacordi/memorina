class_name AbilityRecallComponent extends Node

## The emergency QTE of docs/design/02_mecanicas.md section 4: under an
## attack that cannot be dodged, the body remembers a skill it had before the
## grief. Armed by the owner with the attack's AbilityRecallStats, told which
## actions the player pressed, and ticked with REAL seconds - the world is
## slowed while it is armed, and the window is measured against the hand, not
## the slowed clock.
##
## A memory can take more than one press. A double jump is jump and then jump
## AGAIN: asked for with both feet planted it is two steps, and the moment
## teaches the whole move instead of waiting for someone else to put Ivo in
## the air. Caught already airborne it is the one press that is left to give.
## Whether the feet are planted is the BODY's judgement, pushed in through
## arm() and notify(), the same way `enabled` carries the item gate.
##
## A player ability because it is about Enums.PlayerSkill, but it never grants
## one: it reports `recalled` and the owner touches the save, exactly as the
## roll's `enabled` gate keeps SaveSystem out of RollComponent.

## The right action was pressed in time. Carries what it was armed with, so
## the owner learns both the skill and the grace it earns.
signal recalled(stats: AbilityRecallStats)
## A press landed and the memory is not complete: `remaining` presses to go,
## with `seconds` of real time now on the clock.
signal step_taken(remaining: int, seconds: float)
## The window closed on nothing.
signal missed(stats: AbilityRecallStats)

var _stats: AbilityRecallStats
var _left: float = -1.0
## Presses still wanted; 0 when unarmed.
var _steps_left: int = 0

func is_armed() -> bool:
	return _stats != null

func armed_stats() -> AbilityRecallStats:
	return _stats

## Presses the open moment still wants, 0 when there is no moment.
func steps_left() -> int:
	return _steps_left

## Opens the window. `grounded` is the body's own answer at this instant: with
## the feet planted the memory may ask for its full chain, in the air only the
## press that is left. Ignored while one is already open, so a guardian that
## repeats its attack mid-recall does not restart the clock.
func arm(stats: AbilityRecallStats, grounded: bool = false) -> bool:
	if is_armed() or stats == null:
		return false
	_stats = stats
	_left = stats.window
	_steps_left = maxi(stats.grounded_steps, 1) if grounded else 1
	return true

## The player pressed `action`, with `airborne` saying where the body was when
## they did. True when the press counted - for the last step of a move that
## can only be performed off the ground, a press with the feet down does not,
## and is left to the ordinary jump that will put Ivo in the air.
func notify(action: StringName, airborne: bool = true) -> bool:
	if not is_armed() or action != _stats.action:
		return false
	if _steps_left <= 1 and _stats.airborne_finish and not airborne:
		return false
	_steps_left -= 1
	if _steps_left > 0:
		if _stats.step_window > 0.0:
			_left = _stats.step_window
		step_taken.emit(_steps_left, _left)
		return true
	var stats := _stats
	_disarm()
	recalled.emit(stats)
	return true

## `real_delta` is wall-clock seconds, already corrected for the time scale.
func tick(real_delta: float) -> void:
	if not is_armed():
		return
	_left -= real_delta
	if _left > 0.0:
		return
	var stats := _stats
	_disarm()
	missed.emit(stats)

## Drops an open window without a verdict, for an owner that can no longer
## answer (it died). True when there was one to drop.
func cancel() -> bool:
	if not is_armed():
		return false
	_disarm()
	return true

func _disarm() -> void:
	_stats = null
	_left = -1.0
	_steps_left = 0
