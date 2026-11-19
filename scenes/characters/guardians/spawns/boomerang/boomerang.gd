class_name Boomerang
extends SpawnedAttack
## A leaf blade thrown out along the facing and back over its live time: out at `height`, back at `return_height`,
## dropping between the two while it turns.

## Share of the live time, either side of the turn, over which the blade drops to its return height.
const DROP := 0.1

## Px it flies out at most.
@export var reach: float = 220.0
## Px past Ivo it turns; 0 always flies out `reach`.
@export var past: float = 0.0
## Px it flies out at least when it turns past Ivo.
@export var min_reach: float = 64.0
## Px it keeps inside the arena's wall when it turns past Ivo, unless that is under half of `past` beyond him.
@export var wall_margin: float = 8.0
## Px above the floor of the blade's centre on the way out.
@export var height: float = 40.0
## Px above the floor of the blade's centre on the way back; negative keeps `height`.
@export var return_height: float = -1.0
## Px of the blade, the hit included.
@export var size: Vector2 = Vector2(16.0, 12.0)


func aimed() -> bool:
	return true

## Px from its root at which it turns: `past` beyond Ivo as it was thrown, held inside `reach` and the arena.
func turn_reach() -> float:
	if is_zero_approx(past):
		return reach
	var ahead := (context.target.x - position.x) * facing + past
	var turn := clampf(ahead, min_reach, reach)
	if context.arena.size.x > 0.0:
		var edge := context.arena.end.x - wall_margin if facing > 0 else context.arena.position.x + wall_margin
		# Never turning on top of a pinned Ivo: at least half of `past` beyond him, into the wall if need be.
		var wall := maxf((edge - position.x) * facing, ahead - past * 0.5)
		turn = clampf(turn, 0.0, maxf(wall, 0.0))
	return turn

## Px above the floor of the blade's centre `u` (0..1) through its flight.
func height_at(u: float) -> float:
	var back := height if return_height < 0.0 else return_height
	return lerpf(height, back, smoothstep(0.5 - DROP, 0.5 + DROP, u))

func _hit_offset(t: float) -> Vector2:
	var u := clampf((t - warn) / maxf(live, 0.001), 0.0, 1.0)
	return Vector2(facing * turn_reach() * sin(PI * u), -height_at(u) + size.y * 0.5)

func _hit_size() -> Vector2:
	return size

func _drawn_rect() -> Rect2:
	var far := facing * turn_reach()
	var top := maxf(height, return_height) + size.y * 0.5
	var bottom := minf(height, height if return_height < 0.0 else return_height) - size.y * 0.5
	return snapped_rect(Rect2(minf(0.0, far) - size.x, -top - size.y * 0.5, absf(far) + size.x * 2.0,
			top - bottom + size.y))

func _draw() -> void:
	if _t >= warn + live:
		return
	var centre := _hit_offset(_t) + Vector2(0.0, -size.y * 0.5)
	var spin := int(_t * 24.0) % 2 == 0
	var blade := Vector2(size.x, size.y * 0.5) if spin else Vector2(size.y * 0.5, size.x * 0.75)
	# A light blade in a dark rim, so it reads against the grey sky and the ground alike.
	draw_rect(snapped_rect(Rect2(centre - blade * 0.5, blade).grow(2.0)), dark)
	draw_rect(snapped_rect(Rect2(centre - blade * 0.5, blade)), light)
