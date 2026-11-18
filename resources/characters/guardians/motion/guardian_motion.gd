class_name GuardianMotion
extends Resource
## A move's reposition, planned at the strike's start into a MotionPath that finishes inside the strike: speed varies,
## time does not (architecture/grd-12-guardian-fight-engine, option 5).


## The path for this strike; the base stands still.
func plan(ctx: MotionContext) -> MotionPath:
	return MotionPath.new(ctx.duration)

## Whether the path ends on or through Ivo, so its box must touch him at every distance it is thrown from
## (combat_reach_test).
func aimed() -> bool:
	return false

## Whether the body passes through the world above its take-off floor while the path holds it.
func passes_through() -> bool:
	return false
