class_name ForegroundMath
extends RefCounted
## Where a foreground piece draws and how far it fades (architecture/foreground-layer).


## The world point at the middle of the screen for a canvas transform.
static func view_centre(canvas: Transform2D, viewport_size: Vector2) -> Vector2:
	return canvas.affine_inverse() * (viewport_size * 0.5)

## World px a piece moves from its anchor so it crosses the screen `scroll_scale` times as fast as the world.
static func parallax_offset(anchor: Vector2, centre: Vector2, scroll_scale: Vector2) -> Vector2:
	return (scroll_scale - Vector2.ONE) * (anchor - centre)

## Fraction (0..1) of `body` that `area` covers; 0 for a body with no area.
static func coverage(area: Rect2, body: Rect2) -> float:
	var body_area := body.get_area()
	if body_area <= 0.0:
		return 0.0
	return area.intersection(body).get_area() / body_area

## `alpha` moved toward `target` at the rate that crosses from 1 to `faded_alpha` in `fade_time` seconds.
static func fade_toward(alpha: float, target: float, faded_alpha: float, fade_time: float, delta: float) -> float:
	if fade_time <= 0.0:
		return target
	var rate := (1.0 - faded_alpha) / fade_time
	return move_toward(alpha, target, rate * delta)
