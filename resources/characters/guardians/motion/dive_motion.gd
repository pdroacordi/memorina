class_name DiveMotion
extends GuardianMotion
## Rises, hangs, then dives in a straight line at Ivo's feet as they were at the strike's start.

## Px of rise above the feet; capped under the arena's top less the body.
@export var height: float = 200.0
## Scaled s into the strike before the rise.
@export var delay: float = 0.0
## Scaled s of the rise, the hang and the dive; scaled down together to fit the strike.
@export var rise_time: float = 0.4
@export var hang: float = 0.3
@export var dive_time: float = 0.3


func plan(ctx: MotionContext) -> MotionPath:
	var window := maxf(ctx.duration - delay, 0.0)
	var total := rise_time + hang + dive_time
	var fit := minf(window / total, 1.0) if total > 0.0 else 0.0
	var rise := minf(height, ctx.headroom())
	var top := Vector2(0.0, -rise)
	var landing := Vector2(ctx.clamp_x(ctx.target.x) - ctx.feet.x, ctx.target.y - ctx.feet.y)
	var t1 := delay + rise_time * fit
	var t2 := t1 + hang * fit
	return MotionPath.new(ctx.duration) \
			.add(delay, t1, top, 0.0, true, true) \
			.add(t1, t2, top, 0.0, true) \
			.add(t2, t2 + dive_time * fit, landing, 0.0, true)

func aimed() -> bool:
	return true
