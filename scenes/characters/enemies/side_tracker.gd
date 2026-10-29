class_name SideTracker
extends RefCounted
## The side a target is on, committed only outside TURN_BAND so a target near overhead does not flip it;
## pure (docs/knowledge/bugs/the-brute-walks-under-ivo-when-he-jumps-from-where-it-parks.md).

## Horizontal dead band, px.
const TURN_BAND := 10.0

## -1 or 1.
var side: float = 1.0


## Takes the target's horizontal offset, px, and returns the committed side.
func update(dx: float) -> float:
	if absf(dx) > TURN_BAND:
		side = signf(dx)
	return side
