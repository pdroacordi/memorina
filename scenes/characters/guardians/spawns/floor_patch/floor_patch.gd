class_name FloorPatch
extends SpawnedAttack
## A burning or thorned patch of floor: hurts whoever stands in it for its live time (a continuous Hitbox).

## Px wide and tall, the hit included.
@export var width: float = 48.0
@export var height: float = 14.0


func _hit_size() -> Vector2:
	return Vector2(width, height)

func _drawn_rect() -> Rect2:
	return snapped_rect(Rect2(-width * 0.5, -height, width, height))

func _draw() -> void:
	var rise := height
	if _t < warn:
		rise = height * 0.3
	elif _t >= warn + live:
		rise = height * clampf(1.0 - (_t - warn - live) / maxf(fade, 0.001), 0.0, 1.0)
	var flicker := int(_t * 12.0) % 2
	var x := -width * 0.5
	while x < width * 0.5:
		var tall := rise * (0.6 if int((x + width) / 6.0 + flicker) % 2 == 0 else 1.0)
		draw_rect(snapped_rect(Rect2(x, -tall, 4.0, tall)), dark)
		draw_rect(snapped_rect(Rect2(x, -tall, 2.0, tall * 0.5)), light)
		x += 6.0
