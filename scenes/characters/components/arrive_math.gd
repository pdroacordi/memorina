class_name ArriveMath
extends RefCounted
## How a scripted walk stops on its mark: it brakes when the braking distance plus one step reaches the gap, and the last
## SETTLE_PX or less are closed by a teleport (systems/cutscenes). Pure.

## Px from the target under which a walk has arrived.
const SETTLE_PX := 2.0


## The move axis (-1..1) toward `target` for a body at `x` moving at `velocity` px/s that brakes at `deceleration` px/s²,
## over a `delta` s step; 0 brakes.
static func axis(x: float, target: float, velocity: float, pace: float, deceleration: float, delta: float) -> float:
	var gap := target - x
	if absf(gap) <= SETTLE_PX:
		return 0.0
	var toward := signf(gap)
	if signf(velocity) == toward and braking_distance(velocity, deceleration, delta) >= absf(gap):
		return 0.0
	return toward * clampf(pace, 0.0, 1.0)

## Px a body at `velocity` covers while braking, plus the step it moves before the brake applies.
static func braking_distance(velocity: float, deceleration: float, delta: float) -> float:
	var speed := absf(velocity)
	return speed * speed / (2.0 * maxf(deceleration, 0.001)) + speed * delta

## Whether the walk is over: within SETTLE_PX of the target.
static func arrived(x: float, target: float) -> bool:
	return absf(target - x) <= SETTLE_PX
