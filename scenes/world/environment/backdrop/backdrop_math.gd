class_name BackdropMath
extends RefCounted
## Where a backdrop layer draws, which texel a pixel shows, and which room draws a pixel (systems/backdrops).
## art_row, art_col, pixel_centre, keeps, void_owner, hold, over_top and rect_distance must match backdrop_layer.gdshader
## (gotchas/glsl-gdscript-math-must-be-duplicated).

## How a room holds a void pixel, highest first: over its top, beside it (its rows), under its floor, past a corner, so the
## sky goes up from a room and a taller neighbour's wall goes on down beside a floor. Must match owner_gap's z.
const ABOVE := 3
const BESIDE := 2
const BELOW := 1
const CORNER := 0
## World px a room rect is grown (own) or shrunk (neighbour) by, so float noise makes two rooms draw a pixel, never neither.
const SEAM_EPSILON := 0.01

## `drawn_cells` by [own, neighbours, ring, part].
static var _drawn_memo: Dictionary = {}


## The camera centre at which the anchor's horizon sits at `horizon_screen_y`: every layer's authored pose.
static func reference_centre(anchor: Vector2, horizon_screen_y: float, half_view: Vector2) -> Vector2:
	return Vector2(anchor.x, anchor.y + half_view.y - horizon_screen_y)

## World position of a layer's anchor point (art column 0, its horizon row) for a camera centre.
static func anchor_position(anchor: Vector2, ref: Vector2, camera_centre: Vector2, scroll: Vector2) -> Vector2:
	return anchor + (camera_centre - ref) * (Vector2.ONE - scroll)

## The Parallax2D.scroll_offset that draws the anchor at `anchor_position` under a parent at `parent_global`.
## Parallax2D puts itself at (camera top-left) * (1 - scroll) + scroll_offset in its parent (gotchas/parallax2d-ignores-its-parents-offset).
static func scroll_offset(anchor: Vector2, ref: Vector2, parent_global: Vector2, scroll: Vector2, half_view: Vector2) -> Vector2:
	return anchor - parent_global + (half_view - ref) * (Vector2.ONE - scroll)

## Layer-local rect (relative to the anchor point) the room's camera can show at zoom 1 or more, grown by `margin`, in whole px.
static func cover_rect(bounds: Rect2, anchor: Vector2, ref: Vector2, scroll: Vector2, half_view: Vector2, margin: float) -> Rect2i:
	var low := Vector2.ZERO
	var high := Vector2.ZERO
	for axis: int in 2:
		var centre_min := bounds.position[axis] + half_view[axis]
		var centre_max := bounds.end[axis] - half_view[axis]
		# A room smaller than the view is shown centred.
		if centre_min > centre_max:
			centre_min = bounds.get_center()[axis]
			centre_max = centre_min
		var still := ref[axis] * (1.0 - scroll[axis]) - anchor[axis]
		low[axis] = centre_min * scroll[axis] + still - half_view[axis] - margin
		high[axis] = centre_max * scroll[axis] + still + half_view[axis] + margin
	var start := Vector2i(floori(low.x), floori(low.y))
	var end := Vector2i(ceili(high.x), ceili(high.y))
	return Rect2i(start, end - start)

## `cover` trimmed to where the layer can show art: no rows past a NONE side, no columns outside an unrepeated strip.
static func clip_to_fills(cover: Rect2i, strip: Vector2i, horizon_row: int, fill_above: BackdropLayer.Fill,
		fill_below: BackdropLayer.Fill, repeat_x: bool) -> Rect2i:
	var top := cover.position.y
	var bottom := cover.end.y
	if fill_above == BackdropLayer.Fill.NONE:
		top = maxi(top, -horizon_row)
	if fill_below == BackdropLayer.Fill.NONE:
		bottom = mini(bottom, strip.y - horizon_row)
	var left := cover.position.x
	var right := cover.end.x
	if not repeat_x:
		left = maxi(left, 0)
		right = mini(right, strip.x)
	if right <= left or bottom <= top:
		return Rect2i()
	return Rect2i(left, top, right - left, bottom - top)

## The band-local art row a layer row shows, or -1 for transparent.
static func art_row(row: int, strip_h: int, fill_above: BackdropLayer.Fill, fill_below: BackdropLayer.Fill) -> int:
	if row >= 0 and row < strip_h:
		return row
	var fill := fill_above if row < 0 else fill_below
	match fill:
		BackdropLayer.Fill.EDGE:
			return 0 if row < 0 else strip_h - 1
		BackdropLayer.Fill.REPEAT:
			return posmod(row, strip_h)
	return -1

## The art column a layer column shows, or -1 for transparent.
static func art_col(col: int, strip_w: int, repeat_x: bool) -> int:
	if repeat_x:
		return posmod(col, strip_w)
	return col if col >= 0 and col < strip_w else -1

## The anchor a layer is placed from: world 0 on an axis where the art repeats, so rooms of one set draw the same pixels,
## and the room's horizon anchor on an axis where the art has an edge (architecture/backdrop-seams).
static func layer_anchor(room_anchor: Vector2, repeat_x: bool, repeats_y: bool) -> Vector2:
	return Vector2(0.0 if repeat_x else room_anchor.x, 0.0 if repeats_y else room_anchor.y)

## Whether two rooms draw the same backdrop pixels: one set, placed from equal anchors on every axis where one of its
## layers has an edge (`layer_anchor` places a repeating axis from world 0).
static func same_picture(set_a: BackdropSet, anchor_a: Vector2, set_b: BackdropSet, anchor_b: Vector2) -> bool:
	if set_a != set_b:
		return false
	if set_a == null:
		return true
	for layer: BackdropLayer in set_a.layers:
		if layer == null:
			continue
		if not layer.repeat_x and anchor_a.x != anchor_b.x:
			return false
		if not layer.repeats_y() and anchor_a.y != anchor_b.y:
			return false
	return true

## The centre of the world pixel holding `point`: what every quad judges a pixel by, so two quads that place one pixel a
## hair apart give one answer (gotchas/two-quads-disagree-on-a-pixels-world-position).
static func pixel_centre(point: Vector2) -> Vector2:
	return point.floor() + Vector2(0.5, 0.5)

## Whether the room `own` draws the backdrop pixel centred at `point`: the point lies in it, or lies in no room and `own`
## is the void's owner there (`void_owner`) within `ring` px.
static func keeps(point: Vector2, own: Rect2, neighbours: Array[Rect2], ring: float) -> bool:
	if own.grow(SEAM_EPSILON).has_point(point):
		return true
	for other: Rect2 in neighbours:
		if other.grow(-SEAM_EPSILON).has_point(point):
			return false
	if rect_distance(own, point) > ring:
		return false
	var rooms: Array[Rect2] = [own]
	rooms.append_array(neighbours)
	return void_owner(point, rooms, ring) == 0

## The index in `rooms` of the room that draws the void pixel at `point`, among those within `ring` px (-1 for none): the
## highest hold (ABOVE, BESIDE, BELOW, CORNER), then the smallest gap, then the lower x, then y. Every boundary is straight
## (bugs/a-ring-corner-diagonal-shows-a-rock-wall-in-the-mills-sky-on-a-jump).
static func void_owner(point: Vector2, rooms: Array[Rect2], ring: float) -> int:
	var best := -1
	var best_gap := INF
	var best_rank := -1
	for i: int in rooms.size():
		var rect := rooms[i]
		if rect_distance(rect, point) > ring:
			continue
		var rank := hold(rect, point)
		var gap: float
		match rank:
			ABOVE, BELOW:
				gap = maxf(maxf(rect.position.y - point.y, point.y - rect.end.y), 0.0)
			BESIDE:
				gap = maxf(maxf(rect.position.x - point.x, point.x - rect.end.x), 0.0)
			_:
				gap = rect_distance(rect, point)
		if best < 0 or rank > best_rank or (rank == best_rank and (gap < best_gap \
				or gap == best_gap and _before(rect, rooms[best]))):
			best = i
			best_gap = gap
			best_rank = rank
	return best

## How `rect` holds the void pixel at `point`: ABOVE or BELOW in its columns, BESIDE in its rows, else CORNER.
static func hold(rect: Rect2, point: Vector2) -> int:
	if point.x >= rect.position.x and point.x < rect.end.x:
		return BELOW if point.y >= rect.end.y else ABOVE
	if point.y >= rect.position.y and point.y < rect.end.y:
		return BESIDE
	return CORNER

## World rects holding every pixel `own` keeps among `neighbours` (`keeps`) in `part` (Backdrop.Part: 0 all, 1 under its
## top, 2 over it). A superset: the grid runs on every room edge and ring line, so a hold is constant per cell, and a cell
## where two holds tie is kept. Memoised: rooms never move (systems/backdrops, "Clipped quads").
static func drawn_cells(own: Rect2, neighbours: Array[Rect2], ring: float, part: int = 0) -> Array[Rect2]:
	var key := [own, neighbours, ring, part]
	if _drawn_memo.has(key):
		return _drawn_memo[key]
	var xs := _grid_lines(own, neighbours, ring, 0)
	var ys := _grid_lines(own, neighbours, ring, 1)
	var runs: Array[Rect2] = []
	for j: int in ys.size() - 1:
		var start := -1
		for i: int in xs.size():
			var kept := i < xs.size() - 1 and _keeps_cell(Vector2((xs[i] + xs[i + 1]) * 0.5, (ys[j] + ys[j + 1]) * 0.5),
					own, neighbours, ring, part)
			if kept and start < 0:
				start = i
			elif not kept and start >= 0:
				runs.append(Rect2(xs[start], ys[j], xs[i] - xs[start], ys[j + 1] - ys[j]))
				start = -1
	var cells := _merge_runs(runs)
	_drawn_memo[key] = cells
	return cells

## The bounding rect of `rects`; empty for none.
static func bounding(rects: Array[Rect2]) -> Rect2:
	if rects.is_empty():
		return Rect2()
	var box := rects[0]
	for rect: Rect2 in rects:
		box = box.merge(rect)
	return box

# Every edge and ring line of the rooms along `axis`, inside own's ring, sorted and unique.
static func _grid_lines(own: Rect2, neighbours: Array[Rect2], ring: float, axis: int) -> PackedFloat64Array:
	var low := own.position[axis] - ring
	var high := own.end[axis] + ring
	var lines := PackedFloat64Array([low, high])
	var rooms: Array[Rect2] = [own]
	rooms.append_array(neighbours)
	for rect: Rect2 in rooms:
		for line: float in [rect.position[axis], rect.end[axis], rect.position[axis] - ring, rect.end[axis] + ring]:
			if line > low and line < high and not line in lines:
				lines.append(line)
	lines.sort()
	return lines

# Whether `own` may keep the pixels of the grid cell centred at `centre`: `keeps` without its gap tie-breaks.
static func _keeps_cell(centre: Vector2, own: Rect2, neighbours: Array[Rect2], ring: float, part: int) -> bool:
	if (part == 1 and over_top(centre, own)) or (part == 2 and not over_top(centre, own)):
		return false
	if own.grow(SEAM_EPSILON).has_point(centre):
		return true
	for other: Rect2 in neighbours:
		if other.grow(-SEAM_EPSILON).has_point(centre):
			return false
	if rect_distance(own, centre) > ring:
		return false
	var mine := hold(own, centre)
	for other: Rect2 in neighbours:
		if rect_distance(other, centre) <= ring and hold(other, centre) > mine:
			return false
	return true

# Row runs merged downward where a run below spans the same columns.
static func _merge_runs(runs: Array[Rect2]) -> Array[Rect2]:
	var merged: Array[Rect2] = []
	for run: Rect2 in runs:
		var joined := false
		for i: int in merged.size():
			var above := merged[i]
			if above.position.x == run.position.x and above.size.x == run.size.x and above.end.y == run.position.y:
				merged[i] = above.merge(run)
				joined = true
				break
		if not joined:
			merged.append(run)
	return merged

## Whether the pixel centred at `point` lies over the top of `own`: there a room shows its region's open set, not its own
## override (systems/backdrops).
static func over_top(point: Vector2, own: Rect2) -> bool:
	return point.y < own.position.y

## World px from `point` to `rect` along the farther axis, 0 inside it: the ring is `rect.grow(ring)`, square-cornered
## like the camera's reach.
static func rect_distance(rect: Rect2, point: Vector2) -> float:
	var dx := maxf(rect.position.x - point.x, point.x - rect.end.x)
	var dy := maxf(rect.position.y - point.y, point.y - rect.end.y)
	return maxf(maxf(dx, dy), 0.0)

static func _before(a: Rect2, b: Rect2) -> bool:
	return a.position.x < b.position.x or (a.position.x == b.position.x and a.position.y < b.position.y)
