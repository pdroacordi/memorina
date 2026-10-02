class_name AbilityRecallComponent extends Node

## Handles the emergency recall QTE in docs/design/02_mecanicas.md section 4 using real seconds while time is slowed.
## The owner supplies grounded state and stats; completion is reported by `recalled`, leaving save changes to the owner.

## The required action was pressed in time; carries the recalled stats for the owner.
signal recalled(stats: AbilityRecallStats)
## A chain press landed; reports remaining presses and the real-time window.
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

## Opens a window using the body's current grounded state; ignores re-arming while a window is already open.
func arm(stats: AbilityRecallStats, grounded: bool = false) -> bool:
	if is_armed() or stats == null:
		return false
	_stats = stats
	_left = stats.window
	_steps_left = maxi(stats.grounded_steps, 1) if grounded else 1
	return true

## Reports whether `action` counted; an airborne-only final step does not count while grounded.
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

## Drops an open window without a verdict; returns true if one was open.
func cancel() -> bool:
	if not is_armed():
		return false
	_disarm()
	return true

func _disarm() -> void:
	_stats = null
	_left = -1.0
	_steps_left = 0
