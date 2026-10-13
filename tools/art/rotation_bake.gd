class_name RotationBake extends RefCounted

## Bakes a turning still into frames on the art grid (architecture/props-and-ambient-life section 4): upscale, rotate by
## nearest sampling, shrink keeping each block's most common colour, so every output colour is a source colour.
## The still is read through one symmetry sector, so the turn by one period lands exactly on frame 0 and the loop
## closes without a hitch (bugs/the-baked-wheel-and-gear-hitch-at-their-loop-seam).

## Times each art pixel is split before rotating.
const UPSCALE := 4


## `count` frames over one symmetry period of `period_degrees`, each a square `margin` art px wider than the still
## on every side, turned clockwise about the still's centre (half-integer when a side is odd).
static func frames(art: Image, count: int, period_degrees: float, margin: int = 2) -> Array[Image]:
	var result: Array[Image] = []
	for index: int in count:
		result.append(turned(art, period_degrees * index / count, period_degrees, margin))
	return result

## The still turned clockwise by `degrees`, every point read back into the sector [0, period) of its source angle.
static func turned(art: Image, degrees: float, period_degrees: float, margin: int = 2) -> Image:
	var side := maxi(art.get_width(), art.get_height()) + margin * 2
	var out := Image.create_empty(side, side, false, Image.FORMAT_RGBA8)
	var pivot := Vector2(art.get_size()) * UPSCALE * 0.5
	var centre := Vector2(side, side) * UPSCALE * 0.5
	var period := deg_to_rad(period_degrees)
	for y: int in side:
		for x: int in side:
			var counts := {}
			var opaque := 0
			for j: int in UPSCALE:
				for i: int in UPSCALE:
					var offset := Vector2(x * UPSCALE + i + 0.5, y * UPSCALE + j + 0.5) - centre
					var colour := _sample(art, offset.rotated(-deg_to_rad(degrees)), pivot, period)
					if colour.a < 0.5:
						continue
					opaque += 1
					counts[colour] = int(counts.get(colour, 0)) + 1
			if opaque * 2 < UPSCALE * UPSCALE:
				continue
			var best: Color = counts.keys()[0]
			for colour: Color in counts:
				if counts[colour] > counts[best]:
					best = colour
			out.set_pixel(x, y, best)
	return out

## Px that change from each frame to the next, the last entry the wrap back to frame 0.
static func steps(images: Array[Image]) -> PackedInt32Array:
	var result := PackedInt32Array()
	for index: int in images.size():
		var a := images[index]
		var b := images[(index + 1) % images.size()]
		var changed := 0
		for y: int in a.get_height():
			for x: int in a.get_width():
				if a.get_pixel(x, y) != b.get_pixel(x, y):
					changed += 1
		result.append(changed)
	return result

## The wrap step over the median of the other steps: about 1 for a loop with no hitch.
static func wrap_ratio(images: Array[Image]) -> float:
	var all := steps(images)
	var inner := Array(all.slice(0, all.size() - 1))
	inner.sort()
	var median: float = inner[inner.size() / 2]
	return all[all.size() - 1] / maxf(1.0, median)

## The frames side by side, each enlarged `scale` times by nearest sampling.
static func strip(images: Array[Image], scale: int) -> Image:
	var size := images[0].get_size()
	var out := Image.create_empty(size.x * images.size(), size.y, false, Image.FORMAT_RGBA8)
	for index: int in images.size():
		out.blit_rect(images[index], Rect2i(Vector2i.ZERO, size), Vector2i(size.x * index, 0))
	out.resize(out.get_width() * scale, out.get_height() * scale, Image.INTERPOLATE_NEAREST)
	return out

# The still's colour at `offset` (fine px from the pivot), turned back into the first sector of its angle.
static func _sample(art: Image, offset: Vector2, pivot: Vector2, period: float) -> Color:
	var sector := floorf(fposmod(offset.angle(), TAU) / period)
	var source := (offset.rotated(-sector * period) + pivot) / UPSCALE
	var at := Vector2i(floori(source.x), floori(source.y))
	if at.x < 0 or at.y < 0 or at.x >= art.get_width() or at.y >= art.get_height():
		return Color(0, 0, 0, 0)
	return art.get_pixelv(at)
