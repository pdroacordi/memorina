class_name FallReach
extends RefCounted
## Which rooms the frame may yield into below a falling Ivo (systems/rooms).


## The union of the `rooms` meeting `strip` (the frame's width under the current room) if they span its whole width;
## else an empty rect, so no void shows beside a narrower room below (bugs/the-fall-lead-shows-the-void-beside-a-narrower-room-below).
static func of(strip: Rect2, rooms: Array[Rect2]) -> Rect2:
	var met: Array[Rect2] = []
	for bounds: Rect2 in rooms:
		if bounds.intersects(strip):
			met.append(bounds)
	if met.is_empty():
		return Rect2()
	met.sort_custom(func(a: Rect2, b: Rect2) -> bool: return a.position.x < b.position.x)
	var covered := strip.position.x
	var reach := met[0]
	for bounds: Rect2 in met:
		if bounds.position.x > covered:
			return Rect2()
		covered = maxf(covered, bounds.end.x)
		reach = reach.merge(bounds)
	return reach if covered >= strip.end.x else Rect2()
