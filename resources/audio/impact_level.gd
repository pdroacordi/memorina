class_name ImpactLevel
extends RefCounted
## The level of an impact sound (a landing, a splash) by the speed of the impact.

## dB at the slowest heard speed; full speed and over is 0 dB.
const QUIETEST := -12.0


## dB offset for an impact at `speed` px/s, QUIETEST at `min_speed` rising linearly to 0 at `full_speed`.
static func db(speed: float, min_speed: float, full_speed: float) -> float:
	if full_speed <= min_speed:
		return 0.0
	return lerpf(QUIETEST, 0.0, clampf((speed - min_speed) / (full_speed - min_speed), 0.0, 1.0))
