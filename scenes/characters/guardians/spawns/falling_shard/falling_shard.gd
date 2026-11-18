class_name FallingShard
extends SpawnedAttack
## An icicle: a glint over the spot it was aimed at, then the fall onto the floor.

## Px above the floor it falls from.
@export var drop: float = 260.0
## Px/s of the fall.
@export var fall_speed: float = 720.0
## Px of the shard, the hit included.
@export var size: Vector2 = Vector2(10.0, 22.0)


func aimed() -> bool:
	return true

func from_above() -> bool:
	return true

func _hit_offset(t: float) -> Vector2:
	return Vector2(0.0, minf(-drop + fall_speed * maxf(t - warn, 0.0), 0.0))

func _hit_size() -> Vector2:
	return size

func _drawn_rect() -> Rect2:
	return snapped_rect(Rect2(-size.x, -drop - size.y - 4.0, size.x * 2.0, drop + size.y + 4.0))

func _draw() -> void:
	if _t < warn:
		# The glint where it hangs, and its shadow on the floor.
		var bright := int(_t * 16.0) % 2 == 0
		draw_rect(snapped_rect(Rect2(-2.0, -drop - size.y - 4.0, 4.0, 4.0)), light if bright else dark)
		draw_rect(snapped_rect(Rect2(-size.x * 0.5, -2.0, size.x, 2.0)), dark)
		return
	if _t >= warn + live:
		var left := clampf(1.0 - (_t - warn - live) / maxf(fade, 0.001), 0.0, 1.0)
		draw_rect(snapped_rect(Rect2(-size.x * 0.5, -4.0 * left, size.x, 4.0 * left)), light)
		return
	var tip := _hit_offset(_t)
	draw_rect(snapped_rect(Rect2(tip.x - size.x * 0.5, tip.y - size.y, size.x, size.y)), dark)
	draw_rect(snapped_rect(Rect2(tip.x - 2.0, tip.y - size.y, 4.0, size.y - 2.0)), light)
