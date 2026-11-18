class_name BlinkMotion
extends GuardianMotion
## Vanishes and reappears behind Ivo; takes the other side when the arena would leave it within `min_gap` of him.

## Scaled s into the strike of the blink.
@export var at: float = 0.3
## Px behind Ivo it reappears.
@export var behind: float = 64.0
## Px from Ivo under which the clamped spot is refused.
@export var min_gap: float = 32.0
## Scaled s either side of the blink in which it cannot be hit or hurt.
@export var fade: float = 0.1


func plan(ctx: MotionContext) -> MotionPath:
	var side := ctx.side_of_target()
	var x := ctx.clamp_x(ctx.target.x + side * behind)
	if absf(x - ctx.target.x) < min_gap:
		x = ctx.clamp_x(ctx.target.x - side * behind)
	return MotionPath.new(ctx.duration).blink(at, Vector2(x - ctx.feet.x, 0.0), fade)

func aimed() -> bool:
	return true
