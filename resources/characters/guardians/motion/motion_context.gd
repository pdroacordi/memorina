class_name MotionContext
extends RefCounted
## What a GuardianMotion plans against: the guardian's feet and facing, Ivo's feet and the arena, in world px.

## The guardian's feet at the strike's start.
var feet: Vector2 = Vector2.ZERO
## -1 or 1.
var facing: int = 1
## Ivo's feet at the strike's start.
var target: Vector2 = Vector2.ZERO
## The arena's bounds; an empty rect is unbounded.
var arena: Rect2 = Rect2()
## Px a landing keeps from each arena wall.
var margin: float = 0.0
## Px/s².
var gravity: float = 980.0
## Px from the feet to the top of the body.
var body_height: float = 0.0
## The strike's length, s: every plan finishes inside it.
var duration: float = 1.0


## `x` kept `margin` inside the arena's walls; unchanged when the arena is unbounded.
## A floor step from `from` to `x`, held inside the margins but never reversed: from inside a margin it stays put.
func clamp_step(from: float, x: float) -> float:
	var clamped := clamp_x(x)
	if signf(clamped - from) != signf(x - from):
		return from
	return clamped

func clamp_x(x: float) -> float:
	if arena.size.x <= 0.0:
		return x
	var low := arena.position.x + margin
	var high := arena.end.x - margin
	if low > high:
		return arena.get_center().x
	return clampf(x, low, high)

## The tallest rise, px above the feet, that keeps the body under the arena's top; INF when unbounded.
func headroom() -> float:
	if arena.size.y <= 0.0:
		return INF
	return maxf(feet.y - arena.position.y - body_height, 0.0)

## The side Ivo stands on, -1 or 1; the facing when he is straight above or below.
func side_of_target() -> int:
	var dx := target.x - feet.x
	if is_zero_approx(dx):
		return facing
	return 1 if dx > 0.0 else -1
