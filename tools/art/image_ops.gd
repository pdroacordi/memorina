class_name ImageOps extends RefCounted

## Pure image operations for the art pipeline (tools/art/process_image.gd):
## turning a generated picture into a sheet that obeys this project's frame
## contract and palette. No file access here, so every step is testable.

## Makes the background transparent by flood-filling from every edge pixel
## whose colour is within `tolerance` of `key`. Filling from the edges - not
## replacing the key colour everywhere - keeps a purple body purple.
static func key_out(image: Image, key: Color, tolerance: float = 0.1) -> Image:
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
	return out

## Every opaque pixel snapped to its nearest palette colour; alpha is made
## binary (pixel art has no half-transparent edge).
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

## Lays frames side by side, each resized (nearest neighbour, never
## smoothed) to exactly `frame_size`, into the strip a Sprite2D with
## hframes = frames.size() reads.
static func pack_strip(frames: Array[Image], frame_size: Vector2i) -> Image:
	var strip := Image.create(frame_size.x * frames.size(), frame_size.y, false, Image.FORMAT_RGBA8)
	for i: int in frames.size():
		var frame := frames[i].duplicate() as Image
		frame.convert(Image.FORMAT_RGBA8)
		if frame.get_size() != frame_size:
			frame.resize(frame_size.x, frame_size.y, Image.INTERPOLATE_NEAREST)
		strip.blit_rect(frame, Rect2i(Vector2i.ZERO, frame_size), Vector2i(i * frame_size.x, 0))
	return strip

## Weighted RGB distance: close enough to perceptual for snapping to a
## hand-picked palette, and cheap.
static func _distance(a: Color, b: Color) -> float:
	var dr := a.r - b.r
	var dg := a.g - b.g
	var db := a.b - b.b
	return sqrt(2.0 * dr * dr + 4.0 * dg * dg + 3.0 * db * db) / 3.0
