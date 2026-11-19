class_name LightColumn
extends SpawnedAttack
## A shaft of light: lit and harmless through its warning, then it burns the floor under it (a continuous Hitbox).

## Px wide and tall, the hit included.
@export var width: float = 32.0
@export var height: float = 320.0


func from_above() -> bool:
	return true

func _hit_size() -> Vector2:
	return Vector2(width, height)

func _drawn_rect() -> Rect2:
	return snapped_rect(Rect2(-width * 0.5, -height, width, height))

func _draw() -> void:
	if _t < warn:
		# Lit first: a thin light core in a dark rim, so it reads on dark stone and in the grey, and its floor marked
		# over the grass.
		draw_rect(snapped_rect(Rect2(-4.0, -height, 8.0, height)), dark)
		draw_rect(snapped_rect(Rect2(-2.0, -height, 4.0, height)), light)
		draw_floor_warning(-width * 0.5, width * 0.5, _t / maxf(warn, 0.001))
		return
	var share := 1.0
	if _t >= warn + live:
		share = clampf(1.0 - (_t - warn - live) / maxf(fade, 0.001), 0.0, 1.0)
	var w := width * share
	draw_rect(snapped_rect(Rect2(-w * 0.5, -height, w, height)), light)
	draw_rect(snapped_rect(Rect2(-w * 0.5, -height, 2.0, height)), dark)
	draw_rect(snapped_rect(Rect2(w * 0.5 - 2.0, -height, 2.0, height)), dark)
