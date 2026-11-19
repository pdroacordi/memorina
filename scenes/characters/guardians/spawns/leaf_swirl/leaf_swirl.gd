class_name LeafSwirl
extends SpawnedAttack
## Leaves gathering where a body will reform: marks the spot through `warn` and never hurts; the body does.

## Px wide and tall, the body's.
@export var width: float = 48.0
@export var height: float = 156.0
## Leaves in the swirl.
@export var leaf_count: int = 18
## Turns per scaled second.
@export var spin: float = 1.5


## Only the body that reforms hurts.
func is_live(_t_at: float) -> bool:
	return false

func _drawn_rect() -> Rect2:
	return snapped_rect(Rect2(-width * 0.5 - 4.0, -maxf(height, WARN_RISE) - 4.0, width + 8.0,
			maxf(height, WARN_RISE) + 8.0))

func _draw() -> void:
	if _t >= warn + fade:
		return
	var grow := clampf(_t / maxf(warn, 0.001), 0.0, 1.0)
	if _t >= warn:
		grow = clampf(1.0 - (_t - warn) / maxf(fade, 0.001), 0.0, 1.0)
	# The leaves spiral in as the reforming nears: a wide loose swirl first, the body's width at the end.
	var spread := width * (1.0 - 0.5 * grow) * 0.5
	for i: int in leaf_count:
		var lane := fposmod(float(i) * 0.618, 1.0)
		var angle := TAU * (lane + _t * spin)
		var x := snappedf(cos(angle) * spread, 2.0)
		var y := snappedf(-height * (0.1 + 0.85 * fposmod(lane + _t * 0.4, 1.0)), 2.0)
		var leaf := Rect2(Vector2(x - 2.0, y - 1.0), Vector2(4.0, 2.0 + 2.0 * float(i % 2)))
		draw_rect(leaf.grow(1.0), dark)
		draw_rect(leaf, light)
	draw_floor_warning(-width * 0.5, width * 0.5, grow)
