class_name HoldRise
extends RefCounted
## Holding Up raises the swing step by step, pure (flashback 3, systems/story): every `step_seconds` held is one step up,
## letting go recedes at the same pace, `steps` steps finish it, and a full recede left idle `idle_seconds` gives it up.

## Seconds of float slack, so a hold summed from frame deltas lands on its step.
const EPSILON := 0.0001

## Scaled seconds held per step.
var step_seconds: float
## Steps to the top.
var steps: int
## Scaled seconds at the bottom, not holding, before it is given up.
var idle_seconds: float

## Scaled seconds of hold banked, 0..steps * step_seconds.
var _held: float = 0.0
var _idle: float = 0.0
var _finished: bool = false
var _abandoned: bool = false


func _init(step: float = 0.5, step_count: int = 4, idle: float = 1.5) -> void:
	step_seconds = step
	steps = step_count
	idle_seconds = idle

## Advances `delta` scaled seconds with Up `held` or not; nothing changes once finished or abandoned.
func tick(delta: float, held: bool) -> void:
	if _finished or _abandoned:
		return
	if held:
		_idle = 0.0
		_held = minf(_held + delta, step_seconds * steps)
		_finished = _held >= step_seconds * steps - EPSILON
		return
	var spare := delta
	if _held > 0.0:
		var taken := minf(_held, delta)
		_held = 0.0 if _held - taken < EPSILON else _held - taken
		spare -= taken
	if _held == 0.0:
		_idle += spare
		_abandoned = _idle >= idle_seconds - EPSILON

## Steps reached, 0..steps.
func level() -> int:
	return mini(floori((_held + EPSILON) / step_seconds), steps)

func is_finished() -> bool:
	return _finished

func is_abandoned() -> bool:
	return _abandoned
