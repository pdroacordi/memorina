class_name HelixSteer extends RefCounted

## Turns held input into a direction along a helix stair (architecture/walkable-helix-stair, Revision): Up or the hand
## side climbs, Down or the other side descends. Ivo stays at the stair's front, so the run never changes direction.

## |axis.y| from which the vertical wins a diagonal.
const VERTICAL := 0.5


## 1 up the stair, -1 down, 0 still, for `axis` (x right, y down) on a stair climbed by walking toward `hand`.
static func direction(axis: Vector2, hand: int) -> int:
	if absf(axis.y) >= VERTICAL:
		return -1 if axis.y > 0.0 else 1
	if is_zero_approx(axis.x):
		return 0
	return 1 if (axis.x > 0.0) == (hand > 0) else -1
