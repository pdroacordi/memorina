class_name GaleShape extends RefCounted

## Vendaval wind follows design 02 section 7.1: horizontal, one direction, zero in the eye and at the pulse edge.

## Where across the ring from the eye to the edge the wind is strongest, 0..1.
const PEAK_AT := 0.35

## 0..1 at `distance` from the origin, for a gale of `radius` with a still
## `eye`.
static func strength(distance: float, radius: float, eye: float) -> float:
	if radius <= eye or distance <= eye or distance >= radius:
		return 0.0
	var t := (distance - eye) / (radius - eye)
	if t < PEAK_AT:
		return smoothstep(0.0, 1.0, t / PEAK_AT)
	return 1.0 - smoothstep(0.0, 1.0, (t - PEAK_AT) / (1.0 - PEAK_AT))

## The gale's air at `point`, in px/s: horizontal, the way `direction` says
## (+1 right, -1 left), whichever side of `origin` the point is on.
static func wind(origin: Vector2, point: Vector2, radius: float, eye: float, speed: float, direction: float) -> Vector2:
	return Vector2(signf(direction) * speed * strength(point.distance_to(origin), radius, eye), 0.0)
