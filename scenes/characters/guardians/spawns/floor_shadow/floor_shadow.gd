class_name FloorShadow
extends SpawnedAttack
## The shadow of a body coming down from above: marks its landing spot through `warn` and never hurts; the body does.

## Px wide, the body's.
@export var width: float = 96.0


## Only the body that casts it hurts.
func is_live(_t_at: float) -> bool:
	return false

func _drawn_rect() -> Rect2:
	return snapped_rect(Rect2(-width * 0.5 - 2.0, -WARN_RISE - 2.0, width + 4.0, WARN_RISE + 6.0))

func _draw() -> void:
	if _t >= warn + fade:
		return
	var grow := clampf(_t / maxf(warn, 0.001), 0.0, 1.0)
	if _t >= warn:
		grow = clampf(1.0 - (_t - warn) / maxf(fade, 0.001), 0.0, 1.0)
	# A shadow that darkens and widens as the body falls, then the light line over the grass.
	var half := width * (0.35 + 0.15 * grow)
	draw_rect(snapped_rect(Rect2(-half, -4.0, half * 2.0, 4.0)), dark)
	draw_rect(snapped_rect(Rect2(-half * 0.7, -6.0, half * 1.4, 2.0)), dark)
	draw_floor_warning(-width * 0.5, width * 0.5, grow)
