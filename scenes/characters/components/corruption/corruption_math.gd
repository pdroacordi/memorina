class_name CorruptionMath
extends RefCounted
## The corruption edge's fray from health and a hit's decaying spike; pure, read by CorruptionEdge.


## Fray from `rest` at full health to `hurt` at none, clamped to 0..1.
static func fray(rest: float, hurt: float, hp: int, max_hp: int) -> float:
	var lost := 1.0 - clampf(float(hp) / float(maxi(max_hp, 1)), 0.0, 1.0)
	return clampf(lerpf(rest, hurt, lost), 0.0, 1.0)

## A hit's extra fray: `peak` with `left` of `duration` s to go, falling linearly to 0.
static func spike(peak: float, left: float, duration: float) -> float:
	if duration <= 0.0:
		return 0.0
	return peak * clampf(left / duration, 0.0, 1.0)
