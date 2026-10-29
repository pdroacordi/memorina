class_name SwoopPath
extends RefCounted
## A dive from a start point down through a target point and back up to the start's mirror across the target, at the
## start's height: x runs at a constant rate, y on a parabola; pure.

## Shortest swoop, s.
const MIN_DURATION := 0.1

var start: Vector2
var target: Vector2
## Twice the start-to-target distance over the speed, s.
var duration: float


## `speed` in px/s.
func _init(from: Vector2, through: Vector2, speed: float) -> void:
	start = from
	target = through
	duration = maxf(2.0 * from.distance_to(through) / maxf(speed, 1.0), MIN_DURATION)

## The start mirrored across the target, at the start's height.
func end() -> Vector2:
	return Vector2(2.0 * target.x - start.x, start.y)

## Position at `t` s, clamped to the path's ends.
func point_at(t: float) -> Vector2:
	var u := clampf(t / duration, 0.0, 1.0)
	var bend := 2.0 * u - 1.0
	return Vector2(lerpf(start.x, end().x, u), start.y + (target.y - start.y) * (1.0 - bend * bend))

## Velocity at `t` s, px/s; zero outside the path.
func velocity_at(t: float) -> Vector2:
	if t < 0.0 or t > duration:
		return Vector2.ZERO
	var u := t / duration
	return Vector2((end().x - start.x) / duration, (target.y - start.y) * 4.0 * (1.0 - 2.0 * u) / duration)

func is_done(t: float) -> bool:
	return t >= duration
