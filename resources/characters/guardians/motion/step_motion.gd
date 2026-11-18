class_name StepMotion
extends GuardianMotion
## A backstep or a hop along the floor.

## Px along the facing; negative steps back.
@export var distance: float = -64.0
## Px of hop at the step's middle; 0 keeps the feet on the floor.
@export var height: float = 0.0
## Scaled s into the strike before the step.
@export var delay: float = 0.0
## Scaled s the step takes; cut to the strike's end.
@export var time: float = 0.3


func plan(ctx: MotionContext) -> MotionPath:
	var x := ctx.clamp_x(ctx.feet.x + ctx.facing * distance) - ctx.feet.x
	var rise := minf(height, ctx.headroom())
	return MotionPath.new(ctx.duration).add(delay, delay + time, Vector2(x, 0.0), rise, rise > 0.0, rise <= 0.0)
