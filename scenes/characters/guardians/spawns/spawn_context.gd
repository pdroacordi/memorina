class_name SpawnContext
extends RefCounted
## Where a guardian's spawned attacks are placed and aimed from, in world px (SpawnPlacement, SpawnedAttack).

## The guardian's feet as the spawn fires.
var origin: Vector2 = Vector2.ZERO
## -1 or 1.
var facing: int = 1
## Ivo's feet as the spawn fires.
var target: Vector2 = Vector2.ZERO
## The arena's bounds; an empty rect is unbounded.
var arena: Rect2 = Rect2()
## The floor's y under the arena.
var floor_y: float = 0.0


static func make(origin_feet: Vector2, facing_side: int, target_feet: Vector2, bounds: Rect2,
		floor_line: float) -> SpawnContext:
	var ctx := SpawnContext.new()
	ctx.origin = origin_feet
	ctx.facing = facing_side
	ctx.target = target_feet
	ctx.arena = bounds
	ctx.floor_y = floor_line
	return ctx

## `x` kept `margin` inside the arena's walls; unchanged when it is unbounded.
func clamp_x(x: float, margin: float = 0.0) -> float:
	if arena.size.x <= 0.0:
		return x
	return clampf(x, arena.position.x + margin, maxf(arena.end.x - margin, arena.position.x + margin))
