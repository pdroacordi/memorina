class_name DashMotion
extends GuardianMotion
## A low dash along the facing to the arena's edge.

## Px/s; raised when the edge is too far to reach before the strike ends.
@export var speed: float = 520.0
## Scaled s into the strike before the dash.
@export var delay: float = 0.0
## Px the dash stops short of the arena's wall.
@export var margin: float = 48.0


func plan(ctx: MotionContext) -> MotionPath:
	var window := maxf(ctx.duration - delay, 0.0)
	var distance := speed * window
	if ctx.arena.size.x > 0.0:
		var edge := ctx.arena.end.x - margin if ctx.facing > 0 else ctx.arena.position.x + margin
		distance = maxf((edge - ctx.feet.x) * ctx.facing, 0.0)
	var time := minf(distance / maxf(speed, 1.0), window)
	return MotionPath.new(ctx.duration).add(delay, delay + time, Vector2(ctx.facing * distance, 0.0))

func aimed() -> bool:
	return true
