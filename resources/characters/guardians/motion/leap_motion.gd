class_name LeapMotion
extends GuardianMotion
## A leap in an arc: to the arena's far side, onto Ivo's spot or past him.

enum Target { FAR_SIDE, IVO_SPOT, PAST_IVO }

@export var target: Target = Target.IVO_SPOT
## Px of apex above the feet; capped under the arena's top less the body.
@export var height: float = 120.0
## Scaled s into the strike before take-off.
@export var delay: float = 0.0
## Scaled s in the air; cut to the strike's end.
@export var air_time: float = 0.6
## Px past Ivo a PAST_IVO leap lands; also the hop of a FAR_SIDE leap with no arena.
@export var past: float = 96.0
## Passes through the world above the take-off floor (an arena ceiling).
@export var through_ceiling: bool = false


func plan(ctx: MotionContext) -> MotionPath:
	var x := ctx.clamp_x(_landing_x(ctx)) - ctx.feet.x
	var air := minf(air_time, maxf(ctx.duration - delay, 0.0))
	var rise := minf(height, ctx.headroom())
	return MotionPath.new(ctx.duration).add(delay, delay + air, Vector2(x, 0.0), rise, true)

func aimed() -> bool:
	return target != Target.FAR_SIDE

func passes_through() -> bool:
	return through_ceiling

func _landing_x(ctx: MotionContext) -> float:
	match target:
		Target.FAR_SIDE:
			if ctx.arena.size.x <= 0.0:
				return ctx.feet.x + ctx.facing * past
			var low := ctx.clamp_x(ctx.arena.position.x)
			var high := ctx.clamp_x(ctx.arena.end.x)
			return low if absf(ctx.target.x - low) > absf(ctx.target.x - high) else high
		Target.PAST_IVO:
			return ctx.target.x + ctx.side_of_target() * past
	return ctx.target.x
