class_name EnemyReach
extends RefCounted
## Whether a target is inside a move's facing-relative reach box; pure.


## `reach` is authored facing east, px from `origin`; its edges count as inside.
static func holds(reach: Rect2, facing: float, origin: Vector2, target: Vector2) -> bool:
	var box := mirrored(reach, facing)
	var local := target - origin
	return local.x >= box.position.x and local.x <= box.end.x \
			and local.y >= box.position.y and local.y <= box.end.y

## `reach` turned to `facing` (-1 mirrors it across the origin's vertical).
static func mirrored(reach: Rect2, facing: float) -> Rect2:
	if facing >= 0.0:
		return reach
	return Rect2(-reach.end.x, reach.position.y, reach.size.x, reach.size.y)
