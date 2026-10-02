class_name ImageOps extends RefCounted

## Pure image operations used by tools/art/process_image.gd to prepare generated art for the project's frame and palette contract.

## Flood-fills edge-connected pixels within `tolerance` of `key`, preserving enclosed matching colors unless `holes` is true.
static func key_out(image: Image, key: Color, tolerance: float = 0.25, holes: bool = false) -> Image:
	var out := image.duplicate() as Image
	out.convert(Image.FORMAT_RGBA8)
	var size := out.get_size()
	var seen := {}
	var stack: Array[Vector2i] = []
	for x: int in size.x:
		stack.append(Vector2i(x, 0))
		stack.append(Vector2i(x, size.y - 1))
	for y: int in size.y:
		stack.append(Vector2i(0, y))
		stack.append(Vector2i(size.x - 1, y))
	while not stack.is_empty():
		var p: Vector2i = stack.pop_back()
		if seen.has(p) or p.x < 0 or p.y < 0 or p.x >= size.x or p.y >= size.y:
			continue
		seen[p] = true
		var c := out.get_pixelv(p)
		if c.a > 0.0 and _distance(c, key) > tolerance:
			continue
		out.set_pixelv(p, Color(0, 0, 0, 0))
		stack.append(p + Vector2i.RIGHT)
		stack.append(p + Vector2i.LEFT)
		stack.append(p + Vector2i.DOWN)
		stack.append(p + Vector2i.UP)
	if holes:
		for y: int in size.y:
			for x: int in size.x:
				if _distance(out.get_pixel(x, y), key) <= tolerance:
					out.set_pixel(x, y, Color(0, 0, 0, 0))
	return out

## Snaps opaque pixels to the nearest palette color and makes alpha binary.
static func quantize(image: Image, palette: PackedColorArray) -> Image:
	assert(not palette.is_empty(), "quantize needs a palette")
	var out := image.duplicate() as Image
	out.convert(Image.FORMAT_RGBA8)
	var cache := {}
	for y: int in out.get_height():
		for x: int in out.get_width():
			var c := out.get_pixel(x, y)
			if c.a < 0.5:
				out.set_pixel(x, y, Color(0, 0, 0, 0))
				continue
			var key := c.to_rgba32()
			if not cache.has(key):
				cache[key] = nearest(c, palette)
			out.set_pixel(x, y, cache[key])
	return out

static func nearest(color: Color, palette: PackedColorArray) -> Color:
	var best := palette[0]
	var best_distance := INF
	for candidate: Color in palette:
		var d := _distance(color, candidate)
		if d < best_distance:
			best_distance = d
			best = candidate
	return Color(best.r, best.g, best.b, 1.0)

## Cuts `count` equal frames out of a horizontal strip.
static func split_strip(strip: Image, count: int) -> Array[Image]:
	assert(count > 0 and strip.get_width() % count == 0, "a strip must divide into %d equal frames" % count)
	var width := strip.get_width() / count
	var frames: Array[Image] = []
	for i: int in count:
		frames.append(strip.get_region(Rect2i(i * width, 0, width, strip.get_height())))
	return frames

## Crops all frames to their shared opaque bounds so frame content stays aligned; empty frames remain unchanged.
static func trim_frames(frames: Array[Image]) -> Array[Image]:
	var bounds := Rect2i()
	for frame: Image in frames:
		var used := frame.get_used_rect()
		if used.has_area():
			bounds = used if not bounds.has_area() else bounds.merge(used)
	if not bounds.has_area():
		return frames
	var trimmed: Array[Image] = []
	for frame: Image in frames:
		trimmed.append(frame.get_region(bounds))
	return trimmed

## Packs frames into Sprite2D horizontal cells, preserving aspect ratio and bottom-centering each frame.
static func pack_strip(frames: Array[Image], frame_size: Vector2i) -> Image:
	var strip := Image.create(frame_size.x * frames.size(), frame_size.y, false, Image.FORMAT_RGBA8)
	for i: int in frames.size():
		var frame := frames[i].duplicate() as Image
		frame.convert(Image.FORMAT_RGBA8)
		var scale := minf(float(frame_size.x) / frame.get_width(), float(frame_size.y) / frame.get_height())
		var size := Vector2i((Vector2(frame.get_size()) * scale).round()).clamp(Vector2i.ONE, frame_size)
		if scale <= 0.5:
			frame = shrink_mode(frame, size)
		elif frame.get_size() != size:
			frame.resize(size.x, size.y, Image.INTERPOLATE_NEAREST)
		var at := Vector2i(i * frame_size.x + (frame_size.x - size.x) / 2, frame_size.y - size.y)
		strip.blit_rect(frame, Rect2i(Vector2i.ZERO, size), at)
	return strip

## Shrinks by assigning each target pixel the most common source-block color; transparent pixels count as a color.
static func shrink_mode(image: Image, size: Vector2i) -> Image:
	var source := image.duplicate() as Image
	source.convert(Image.FORMAT_RGBA8)
	var out := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	var step := Vector2(source.get_size()) / Vector2(size)
	for y: int in size.y:
		for x: int in size.x:
			var from := Vector2i((Vector2(x, y) * step).floor())
			var to := Vector2i((Vector2(x + 1, y + 1) * step).ceil()).min(source.get_size())
			var counts := {}
			var best := 0
			var best_count := 0
			for sy: int in range(from.y, to.y):
				for sx: int in range(from.x, to.x):
					var c := source.get_pixel(sx, sy)
					var key := 0 if c.a < 0.5 else c.to_rgba32()
					var n: int = counts.get(key, 0) + 1
					counts[key] = n
					if n > best_count:
						best_count = n
						best = key
			out.set_pixel(x, y, Color(0, 0, 0, 0) if best == 0 else Color.hex(best))
	return out

## Weighted RGB distance used for palette snapping.
static func _distance(a: Color, b: Color) -> float:
	var dr := a.r - b.r
	var dg := a.g - b.g
	var db := a.b - b.b
	return sqrt(2.0 * dr * dr + 4.0 * dg * dg + 3.0 * db * db) / 3.0
