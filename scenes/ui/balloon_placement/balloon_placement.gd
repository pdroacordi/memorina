class_name BalloonPlacement extends RefCounted

## Where a speech balloon sits on screen: kept inside it, its tail under the speaker. Shared by TeacherBalloon and
## BarkBalloon; units are whatever the caller's screen uses.


## The box's top-left centred over `anchor`, its tail's tip on the anchor, kept `margin` inside `screen`.
static func above(anchor: Vector2, box: Vector2, tail: float, screen: Vector2, margin: float) -> Vector2:
	return clamp_inside(anchor - Vector2(box.x / 2.0, box.y + tail), box, screen, margin)

## The box's top-left beside `anchor` on `side` (-1 west, 1 east), `gap` from it, its tail's tip at the anchor's
## height, kept inside `screen`. Overlapping `avoid`, it takes the other side, then the free spot nearest the anchor
## (`_clear_of`); `tail_points_up` tells which edge then carries the tail.
static func beside(anchor: Vector2, box: Vector2, tail: float, side: int, gap: float, screen: Vector2, margin: float,
		avoid: Rect2 = Rect2(), body: Rect2 = Rect2()) -> Vector2:
	var y := anchor.y - box.y - tail
	for s: int in [side, -side]:
		var placed := clamp_inside(Vector2(_beside_x(anchor.x, box.x, s, gap), y), box, screen, margin)
		if not _overlaps(placed, box, avoid):
			return placed
	var nearest := _clear_of(anchor, box, tail, side, gap, screen, margin, avoid, body)
	if nearest.is_finite():
		return nearest
	return clamp_inside(Vector2(_beside_x(anchor.x, box.x, side, gap), avoid.end.y + margin), box, screen, margin)

## Whether a box placed at `placed` hangs below `anchor`, so its tail rises from its top edge to the anchor.
static func tail_points_up(anchor: Vector2, placed: Vector2) -> bool:
	return placed.y > anchor.y

## `wanted` moved the least to keep the box `margin` inside `screen`, on whole pixels.
static func clamp_inside(wanted: Vector2, box: Vector2, screen: Vector2, margin: float) -> Vector2:
	var limit := screen - box - Vector2.ONE * margin
	return Vector2(clampf(wanted.x, margin, limit.x), clampf(wanted.y, margin, limit.y)).round()

## Px from the box's left edge to the tail's tip: under the anchor, kept `tail` from the box's corners.
static func tail_x(anchor_x: float, box_x: float, box_width: float, tail: float) -> float:
	return clampf(roundf(anchor_x - box_x), tail, box_width - tail)

# The spots that keep the box off `avoid` with the tail reaching the anchor: above the head, slid sideways off the sheet;
# or below the head beside `body` (clear of it), the tail up. The nearest to the anchor, or INF when none fits.
static func _clear_of(anchor: Vector2, box: Vector2, tail: float, side: int, gap: float, screen: Vector2, margin: float,
		avoid: Rect2, body: Rect2) -> Vector2:
	var above_y := anchor.y - box.y - tail
	# The tail's tip stays under the box: anchor.x - box.x within [tail, box.x - tail].
	var candidates: Array[Vector2] = [
		Vector2(anchor.x - box.x / 2.0, above_y),
		Vector2(avoid.end.x + margin, above_y),
		Vector2(avoid.position.x - margin - box.x, above_y),
	]
	var low_y := anchor.y + tail
	if not body.has_area():
		body = Rect2(anchor, Vector2.ZERO)
	for s: int in [side, -side]:
		var x := body.end.x + gap if s > 0 else body.position.x - gap - box.x
		candidates.append(Vector2(x, low_y))
		candidates.append(Vector2(x, maxf(low_y, avoid.end.y + margin)))
	var best := Vector2.INF
	var best_distance := INF
	for wanted: Vector2 in candidates:
		var placed := wanted.round()
		var tail_reach := anchor.x - placed.x
		if placed.y < anchor.y and (tail_reach < tail or tail_reach > box.x - tail):
			continue
		if clamp_inside(placed, box, screen, margin) != placed or _overlaps(placed, box, avoid):
			continue
		if placed.y > anchor.y and Rect2(placed, box).intersects(body):
			continue
		var tip := Vector2(placed.x + tail_x(anchor.x, placed.x, box.x, tail),
				placed.y - tail if placed.y > anchor.y else placed.y + box.y + tail)
		var distance := tip.distance_to(anchor)
		if distance < best_distance:
			best = placed
			best_distance = distance
	return best

static func _beside_x(anchor_x: float, width: float, side: int, gap: float) -> float:
	return anchor_x + gap if side > 0 else anchor_x - gap - width

static func _overlaps(placed: Vector2, box: Vector2, avoid: Rect2) -> bool:
	return avoid.has_area() and Rect2(placed, box).intersects(avoid)
