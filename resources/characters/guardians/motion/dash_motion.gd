class_name DashMotion
extends GuardianMotion
## A low dash along the facing, after an optional backstep: to the arena's edge, or a set distance past Ivo (short of
## him when the wall leaves no room past him).

## Px/s; raised when the end is too far to reach before the strike ends.
@export var speed: float = 520.0
## Scaled s into the strike before the dash.
@export var delay: float = 0.0
## Px the dash stops short of the arena's wall.
@export var margin: float = 48.0
## Px stepped back against the facing before the dash; 0 for none.
@export var backstep: float = 0.0
## Scaled s the backstep takes; cut to `delay`.
@export var backstep_time: float = 0.2
## Px past Ivo the dash stops; with no room before the wall's margin it stops this short of him. 0 runs to the wall.
@export var past: float = 0.0


func plan(ctx: MotionContext) -> MotionPath:
	var path := MotionPath.new(ctx.duration)
	var start := 0.0
	var step_time := minf(backstep_time, delay)
	# A backstep needs time before the dash; with none it would be a jump in place.
	if backstep > 0.0 and step_time > 0.0:
		start = ctx.clamp_step(ctx.feet.x, ctx.feet.x - ctx.facing * backstep) - ctx.feet.x
		path.add(0.0, step_time, Vector2(start, 0.0), 0.0, false, true)
	var window := maxf(ctx.duration - delay, 0.0)
	var distance := speed * window
	if past > 0.0:
		distance = maxf((ctx.target.x + ctx.facing * past - ctx.feet.x - start) * ctx.facing, 0.0)
	if ctx.arena.size.x > 0.0:
		var edge := ctx.arena.end.x - margin if ctx.facing > 0 else ctx.arena.position.x + margin
		var to_edge := maxf((edge - ctx.feet.x - start) * ctx.facing, 0.0)
		if past <= 0.0:
			distance = to_edge
		elif distance > to_edge:
			# No room past Ivo before the wall: it stops `past` short of him rather than on him.
			distance = maxf((ctx.target.x - ctx.facing * past - ctx.feet.x - start) * ctx.facing, 0.0)
	var time := minf(distance / maxf(speed, 1.0), window)
	return path.add(delay, delay + time, Vector2(start + ctx.facing * distance, 0.0))

## Px/s the planned dash runs; above `speed` only when its end cannot be reached in time.
func planned_speed(ctx: MotionContext) -> float:
	var path := plan(ctx)
	var run := absf(path.end_offset().x - path.at(delay).x)
	return run / maxf(path.end_time() - delay, 0.0001)

func aimed() -> bool:
	return true
