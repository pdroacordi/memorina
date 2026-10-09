class_name BackdropMath
extends RefCounted
## Where a backdrop layer draws for a camera, and which art texel a layer pixel shows (architecture/vertical-backdrops).
## art_row and art_col must match backdrop_layer.gdshader (gotchas/glsl-gdscript-math-must-be-duplicated).


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
