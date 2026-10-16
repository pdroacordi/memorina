class_name ScriptedController
extends CharacterController
## Intent a cutscene gives a body (Ivo or a StoryActor): walk to an x at a pace and stop on it (ArriveMath).

var _target_x: float = 0.0
var _pace: float = 1.0
var _walking: bool = false
var _axis: float = 0.0


func walk_to(x: float, pace: float) -> void:
	_target_x = x
	_pace = pace
	_walking = true

func stop() -> void:
	_walking = false
	_axis = 0.0

func is_walking() -> bool:
	return _walking

func target_x() -> float:
	return _target_x

## 0..1 of the body's move speed.
func pace() -> float:
	return _pace

## Called by the body before it moves, from its own x and velocity; true on the step it arrives, when the body
## teleports onto `target_x()` (the last ArriveMath.SETTLE_PX or less).
func steer(x: float, velocity_x: float, deceleration: float, delta: float) -> bool:
	if not _walking:
		_axis = 0.0
		return false
	if ArriveMath.arrived(x, _target_x):
		stop()
		return true
	_axis = ArriveMath.axis(x, _target_x, velocity_x, _pace, deceleration, delta)
	return false

func _get_direction() -> float:
	return _axis
