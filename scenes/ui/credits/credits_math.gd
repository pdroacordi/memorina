class_name CreditsMath
extends RefCounted
## The credits roll's timing, in art px and scaled seconds (architecture/story-07-epilogue, "The credits").


## Art px the column rolls, from its top at the view's bottom edge until its last row stands centred in the view.
static func travel(content_height: float, view_height: float, last_height: float) -> float:
	return maxf(content_height + (view_height - last_height) * 0.5, 0.0)

## Whole art px rolled `t` scaled seconds in at `speed` art px/s, held at `travel` once reached.
static func offset(t: float, speed: float, rolled: float) -> int:
	return int(minf(floorf(maxf(t, 0.0) * maxf(speed, 0.0)), floorf(rolled)))

## Scaled seconds from the roll's start to the end of the logo's hold.
static func duration(content_height: float, view_height: float, last_height: float, speed: float, hold: float) -> float:
	var rolled := travel(content_height, view_height, last_height)
	return (rolled / speed if speed > 0.0 else 0.0) + maxf(hold, 0.0)

## 0..1: a row whose centre is `y` art px below the view's top fades over `band` px at the top and bottom edges.
static func edge_alpha(y: float, view_height: float, band: float) -> float:
	if band <= 0.0:
		return 1.0 if y >= 0.0 and y <= view_height else 0.0
	return clampf(minf(y, view_height - y) / band, 0.0, 1.0)
