class_name Boomerang
extends SpawnedAttack
## A leaf blade thrown out along the facing and back, at one height above the floor, over its live time.

## Px it flies out at most.
@export var reach: float = 220.0
## Px above the floor it flies.
@export var height: float = 40.0
## Px of the blade, the hit included.
@export var size: Vector2 = Vector2(16.0, 12.0)


func aimed() -> bool:
	return true

func _hit_offset(t: float) -> Vector2:
	var u := clampf((t - warn) / maxf(live, 0.001), 0.0, 1.0)
	return Vector2(facing * reach * sin(PI * u), -height + size.y * 0.5)

func _hit_size() -> Vector2:
	return size

func _drawn_rect() -> Rect2:
	var far := facing * reach
	return snapped_rect(Rect2(minf(0.0, far) - size.x, -height - size.y * 0.5, absf(far) + size.x * 2.0, size.y * 2.0))

func _draw() -> void:
	if _t >= warn + live:
		return
	var centre := _hit_offset(_t) + Vector2(0.0, -size.y * 0.5)
	var spin := int(_t * 24.0) % 2 == 0
	var blade := Vector2(size.x, size.y * 0.5) if spin else Vector2(size.y * 0.5, size.x * 0.75)
	draw_rect(snapped_rect(Rect2(centre - blade * 0.5, blade)), dark)
	draw_rect(snapped_rect(Rect2(centre - Vector2(2.0, 2.0), Vector2(4.0, 4.0))), light)
