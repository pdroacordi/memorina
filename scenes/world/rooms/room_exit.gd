class_name RoomExit
extends RefCounted
## When Ivo has left a room: sideways or down once his body is out; up only once it is SEAM_MARGIN past the edge or he stands (systems/rooms).

## Px past a top edge before a body still in the air has left: a hop from a floor under a seam stays in its room.
const SEAM_MARGIN := 64.0


## Whether `body` has left `bounds`; `on_floor` is whether it stands.
static func has_left(bounds: Rect2, body: Rect2, on_floor: bool) -> bool:
	if bounds.intersects(body):
		return false
	if body.end.x <= bounds.position.x or body.position.x >= bounds.end.x:
		return true
	# Down needs no margin: the hysteresis is the up margin, and a fall must swap before the landing is due.
	if on_floor or body.position.y >= bounds.end.y:
		return true
	return bounds.position.y - body.end.y >= SEAM_MARGIN

## Whether `body`, in no room, is out of the world: no room in `near` lies in its centre's column below its head.
## A body above an open top falls back into that room.
static func is_lost(body: Rect2, near: Array[Rect2]) -> bool:
	var x := body.get_center().x
	for bounds: Rect2 in near:
		if x >= bounds.position.x and x < bounds.end.x and bounds.end.y > body.position.y:
			return false
	return true
