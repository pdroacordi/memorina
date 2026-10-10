class_name TilePainter
extends RefCounted
## Paints seamless 32 px tile bodies for WangSheet.compose: everything here repeats with a 32 px period, so a body
## tiles with itself, and fill variants differ only away from the tile's border (architecture/biome-tilesets).

const SIZE := 32
## Decorations stay this many px inside the border, so every variant tiles with the plain body and with each other.
const MARGIN := 4


## Soft loam: three octaves of periodic value noise (8, 4 and 2 px cells) mapped onto `ramp` (dark to light);
## the fine octaves carry most of the weight, so no blob reads as a repeat.
static func noise_body(rng_seed: int, ramp: PackedColorArray) -> Image:
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	var coarse := _lattice(rng, 4)
	var middle := _lattice(rng, 8)
	var fine := _lattice(rng, 16)
	var image := Image.create_empty(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	for y: int in SIZE:
		for x: int in SIZE:
			var v := 0.25 * _sample(coarse, 4, x, y) + 0.4 * _sample(middle, 8, x, y) + 0.35 * _sample(fine, 16, x, y)
			# Stretch the narrow middle of the sum back over the ramp.
			v = clampf((v - 0.5) * 2.2 + 0.5, 0.0, 0.999)
			image.set_pixel(x, y, ramp[int(v * ramp.size())])
	return image

## Rounded stones: a periodic Voronoi of `count` stones, each lit from the top left, with `mortar` in the joints
## and `moss` in some of them.
static func stone_body(rng_seed: int, count: int, ramp: PackedColorArray, mortar: Color, moss: PackedColorArray) -> Image:
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	var points: Array[Vector2] = []
	var tone: Array[int] = []
	for i: int in count:
		points.append(Vector2(rng.randf() * SIZE, rng.randf() * SIZE))
		tone.append(rng.randi_range(0, 1))
	var image := Image.create_empty(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	for y: int in SIZE:
		for x: int in SIZE:
			var best := 1e9
			var second := 1e9
			var owner := 0
			var offset := Vector2.ZERO
			for i: int in count:
				var d := _wrapped(Vector2(x + 0.5, y + 0.5), points[i])
				# Wider than tall, like laid street stones.
				var length := Vector2(d.x * 0.72, d.y * 1.2).length()
				if length < best:
					second = best
					best = length
					owner = i
					offset = d
				elif length < second:
					second = length
			var border := second - best
			if border < 1.0:
				var mossy := rng.randf() < 0.35 and not moss.is_empty()
				image.set_pixel(x, y, moss[rng.randi() % moss.size()] if mossy else mortar)
				continue
			# A bevel: dark at the joint, lighter inside, lightest on the upper half.
			var lit := clampf(border / 4.0, 0.0, 1.0) * 0.75 + (0.25 if offset.y < -0.5 else 0.0)
			var index := clampi(int(lit * (ramp.size() - 1) + 0.5) + tone[owner] - 1, 0, ramp.size() - 1)
			image.set_pixel(x, y, ramp[index])
	return image

## Horizontal boards `board` px tall with dark gaps, grain streaks and a nail by every butt joint.
static func plank_body(rng_seed: int, board: int, ramp: PackedColorArray, gap: Color, nail: Color) -> Image:
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	var image := Image.create_empty(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	for row: int in SIZE / board:
		var joint := rng.randi() % SIZE
		var base := rng.randi_range(1, ramp.size() - 2)
		for y: int in range(row * board, (row + 1) * board):
			for x: int in SIZE:
				var color := ramp[base]
				if y == row * board + board - 1 or x == joint:
					color = gap
				elif y == row * board:
					color = ramp[mini(base + 1, ramp.size() - 1)]
				elif rng.randf() < 0.18:
					color = ramp[maxi(base - 1, 0)]
				image.set_pixel(x, y, color)
		image.set_pixel((joint + 2) % SIZE, row * board + board / 2, nail)
		image.set_pixel((joint + SIZE - 2) % SIZE, row * board + board / 2, nail)
	return image

## Plaster between dark timber: a beam along the top and one upright, plaster with soft stains.
static func timber_body(rng_seed: int, plaster: PackedColorArray, timber: PackedColorArray) -> Image:
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	var image := noise_body(rng_seed, plaster)
	for y: int in SIZE:
		for x: int in SIZE:
			var beam := y < 5 or (x >= 13 and x < 18)
			if beam:
				var edge := y == 4 or x == 13 or x == 17
				image.set_pixel(x, y, timber[0] if edge else timber[1 + rng.randi() % (timber.size() - 1)])
	return image

## `body` with `count` decorations from `kinds` scattered inside the margin: "pebble", "root", "sprig".
static func decorated(body: Image, rng_seed: int, count: int, kinds: PackedStringArray, colors: Dictionary) -> Image:
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	var image := body.duplicate() as Image
	for i: int in count:
		# The largest decoration (a sprig) is 5 px wide and 6 px tall: it ends inside the margin.
		var at := Vector2i(rng.randi_range(MARGIN, SIZE - MARGIN - 5), rng.randi_range(MARGIN, SIZE - MARGIN - 6))
		match kinds[rng.randi() % kinds.size()]:
			"pebble":
				# A 3x2 stone, lit from the top left, with a dark underside.
				var light: Color = colors.get("pebble", Color.GRAY)
				image.set_pixel(at.x + 1, at.y, light)
				image.set_pixel(at.x, at.y + 1, light.darkened(0.2))
				image.set_pixel(at.x + 1, at.y + 1, light.darkened(0.3))
				image.set_pixel(at.x + 2, at.y + 1, light.darkened(0.45))
				image.set_pixel(at.x + 1, at.y + 2, light.darkened(0.7))
			"root":
				var root: Color = colors.get("root", Color.TAN)
				var y := at.y
				var x := at.x - 2
				for step: int in rng.randi_range(6, 9):
					image.set_pixel(clampi(x, MARGIN, SIZE - MARGIN - 1), y, root if step % 3 else root.darkened(0.25))
					x += 1
					if rng.randf() < 0.4:
						y = clampi(y + rng.randi_range(-1, 1), MARGIN, SIZE - MARGIN - 1)
			"sprig":
				# A small fern: a stem with alternating fronds, darker at the base.
				var leaf: Color = colors.get("sprig", Color.DARK_OLIVE_GREEN)
				for dy: int in 5:
					var shade := leaf.darkened(0.15 * dy)
					image.set_pixel(at.x + 2, at.y + dy, shade)
					if dy < 4:
						image.set_pixel(at.x + (1 if dy % 2 == 0 else 3), at.y + dy, shade.lightened(0.1))
					if dy == 1 or dy == 3:
						image.set_pixel(at.x + (0 if dy == 1 else 4), at.y + dy + 1, shade)
	return image

static func _lattice(rng: RandomNumberGenerator, cells: int) -> PackedFloat32Array:
	var values := PackedFloat32Array()
	for i: int in cells * cells:
		values.append(rng.randf())
	return values

## Smoothstep-interpolated lattice value at (x, y); the lattice wraps every SIZE px.
static func _sample(values: PackedFloat32Array, cells: int, x: int, y: int) -> float:
	var step := float(SIZE) / cells
	var fx := (x + 0.5) / step
	var fy := (y + 0.5) / step
	var x0 := int(floor(fx)) % cells
	var y0 := int(floor(fy)) % cells
	var x1 := (x0 + 1) % cells
	var y1 := (y0 + 1) % cells
	var tx := smoothstep(0.0, 1.0, fx - floor(fx))
	var ty := smoothstep(0.0, 1.0, fy - floor(fy))
	var top := lerpf(values[y0 * cells + x0], values[y0 * cells + x1], tx)
	var bottom := lerpf(values[y1 * cells + x0], values[y1 * cells + x1], tx)
	return lerpf(top, bottom, ty)

## The shortest offset from `point` to `site` on the 32 px torus.
static func _wrapped(point: Vector2, site: Vector2) -> Vector2:
	var d := point - site
	d.x -= SIZE * round(d.x / SIZE)
	d.y -= SIZE * round(d.y / SIZE)
	return d
