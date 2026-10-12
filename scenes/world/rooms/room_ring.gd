class_name RoomRing
extends RefCounted
## The void within WIDTH px of a room: the nearest room's backdrop draws it, and the camera may yield into it (systems/rooms).

## How a glide's two axes ease: both at once, or one after the other through a corner frame.
enum GlideOrder { TOGETHER, X_FIRST, Y_FIRST }

## Px past a room's bounds: Ivo whole, with the camera's subject margin, at the apex of a full jump from a floor FLOOR_ROWS
## rows under an open top, and under half the 384 px between rooms that do not touch (room_ring_test pins both).
const WIDTH := 160.0
## Rows below an open top a floor must lie for a full jump from it to stay in frame.
const FLOOR_ROWS := 2


## Where the camera may yield past `bounds` to keep Ivo whole: every pixel there is a resident room's or its ring's.
static func reach(bounds: Rect2) -> Rect2:
	return bounds.grow(WIDTH)

## The glide from frame `from` to frame `to` whose every frame stays inside the two reaches: straight if the box they
## span is, else through the corner frame whose two legs are (bugs/a-glide-skips-the-drawn-frame-correction-and-snaps-when-it-ends).
static func glide_order(from: Rect2, to: Rect2, from_reach: Rect2, to_reach: Rect2) -> GlideOrder:
	var reaches: Array[Rect2] = [from_reach, to_reach]
	if covers(reaches, from.merge(to)):
		return GlideOrder.TOGETHER
	var x_corner := Rect2(Vector2(to.position.x, from.position.y), from.size)
	if covers(reaches, from.merge(x_corner)) and covers(reaches, x_corner.merge(to)):
		return GlideOrder.X_FIRST
	var y_corner := Rect2(Vector2(from.position.x, to.position.y), from.size)
	if covers(reaches, from.merge(y_corner)) and covers(reaches, y_corner.merge(to)):
		return GlideOrder.Y_FIRST
	return GlideOrder.TOGETHER

## The part of a glide's start offset `from` still left at `weight` (1..0, linear in time) for `order`: each leg eases out
## over its own share of the glide, the whole glide or one half each.
static func glide_offset(from: Vector2, weight: float, order: GlideOrder) -> Vector2:
	var done := 1.0 - weight
	match order:
		GlideOrder.X_FIRST:
			return Vector2(from.x * _left(done * 2.0), from.y * _left(done * 2.0 - 1.0))
		GlideOrder.Y_FIRST:
			return Vector2(from.x * _left(done * 2.0 - 1.0), from.y * _left(done * 2.0))
	return from * _left(done)

# 1..0 as a leg's share `t` goes 0..1: a cubic ease-out, as the glide had before it was ordered.
static func _left(t: float) -> float:
	var rest := 1.0 - clampf(t, 0.0, 1.0)
	return rest * rest * rest

## Whether every point of `rect` lies in one of `rects`: each cell between their edges is tested at its centre.
static func covers(rects: Array[Rect2], rect: Rect2) -> bool:
	var xs: Array[float] = [rect.position.x, rect.end.x]
	var ys: Array[float] = [rect.position.y, rect.end.y]
	for other: Rect2 in rects:
		for x: float in [other.position.x, other.end.x]:
			if x > rect.position.x and x < rect.end.x:
				xs.append(x)
		for y: float in [other.position.y, other.end.y]:
			if y > rect.position.y and y < rect.end.y:
				ys.append(y)
	xs.sort()
	ys.sort()
	for i: int in xs.size() - 1:
		for j: int in ys.size() - 1:
			if xs[i + 1] <= xs[i] or ys[j + 1] <= ys[j]:
				continue
			var centre := Vector2((xs[i] + xs[i + 1]) * 0.5, (ys[j] + ys[j + 1]) * 0.5)
			if not rects.any(func(other: Rect2) -> bool: return other.has_point(centre)):
				return false
	return true
