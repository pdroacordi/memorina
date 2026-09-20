class_name AbilityRecallComponent extends Node

## The emergency QTE of docs/design/02_mecanicas.md section 4: under an
## attack that cannot be dodged, the body remembers a skill it had before the
## grief. Armed by the owner with the attack's AbilityRecallStats, told which
## actions the player pressed, and ticked with REAL seconds - the world is
## slowed while it is armed, and the window is measured against the hand, not
## the slowed clock.
##
## A player ability because it is about Enums.PlayerSkill, but it never grants
## one: it reports `recalled` and the owner touches the save, exactly as the
## roll's `enabled` gate keeps SaveSystem out of RollComponent.

## The right action was pressed in time. Carries what it was armed with, so
## the owner learns both the skill and the grace it earns.
signal recalled(stats: AbilityRecallStats)
## The window closed on nothing.
signal missed(stats: AbilityRecallStats)

var _stats: AbilityRecallStats
var _left: float = -1.0

func is_armed() -> bool:
	return _stats != null

func armed_stats() -> AbilityRecallStats:
	return _stats

## Opens the window. Ignored while one is already open, so a guardian that
## repeats its attack mid-recall does not restart the clock.
func arm(stats: AbilityRecallStats) -> bool:
	if is_armed() or stats == null:
		return false
	_stats = stats
	_left = stats.window
	return true

## The player pressed `action`. True when it was the one the prompt asked for.
func notify(action: StringName) -> bool:
	if not is_armed() or action != _stats.action:
		return false
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
