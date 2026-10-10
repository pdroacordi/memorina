extends SceneTree

## Writes a placeholder backdrop sheet that repeats on both axes, until its Codex art lands (architecture/backdrop-seams).
##   "<godot>" --headless --path . -s res://tools/art/draw_backdrop_placeholder.gd -- --out=<png> --kind=rock|strata|plaster|stone
##       --colors=#rrggbb,... [--accent=#rrggbb,...] [--size=256] [--scale=2] [--seed=1]
## rock: soft periodic value noise; strata: wavering horizontal bands; plaster: plaster between timber posts and beams
## (accent = timber); stone: dressed stones (accent = mortar).

## Art px between plaster's posts and beams.
const TIMBER_SPACING := 128
## Art px of a post or beam.
const TIMBER_WIDTH := 10


func _init() -> void:
	var args := _args()
	assert(args.has("out"), "--out=<png> is required")
	var size := int(args.get("size", "256"))
	var scale := int(args.get("scale", "2"))
	var rng_seed := int(args.get("seed", "1"))
	var colors := _colors(args.get("colors", "#2a2622,#33302b,#3d3a34"))
	var accent := _colors(args.get("accent", "#1e1a16"))
	TilePainter.size = size
	var image: Image
	match args.get("kind", "rock"):
		"strata":
			image = _strata(rng_seed, size, colors)
		"plaster":
			image = _plaster(rng_seed, size, colors, accent)
		"stone":
			image = TilePainter.stone_body(rng_seed, size * size / 900, colors, accent[0], PackedColorArray())
		_:
			image = ImageOps.majority(TilePainter.noise_body(rng_seed, colors), 2)
	if scale > 1:
		image.resize(size * scale, size * scale, Image.INTERPOLATE_NEAREST)
	var out := ProjectSettings.globalize_path(args["out"])
	DirAccess.make_dir_recursive_absolute(out.get_base_dir())
	var error := image.save_png(out)
	assert(error == OK, "could not write %s" % out)
	print("wrote %s" % out)
	quit()

## Bands a period apart down the sheet, each wavering by a periodic noise row, coloured in turn.
func _strata(rng_seed: int, size: int, colors: PackedColorArray) -> Image:
	var wobble := TilePainter.noise_body(rng_seed, PackedColorArray([Color(0, 0, 0), Color(1, 1, 1)]))
	var image := Image.create_empty(size, size, false, Image.FORMAT_RGBA8)
	var band := size / 8
	for y: int in size:
		for x: int in size:
			var shift := int(wobble.get_pixel(x, 0).r * band * 0.5)
			image.set_pixel(x, y, colors[posmod((y + shift) / band, colors.size())])
	return ImageOps.majority(image, 1)

func _plaster(rng_seed: int, size: int, plaster: PackedColorArray, timber: PackedColorArray) -> Image:
	var image := ImageOps.majority(TilePainter.noise_body(rng_seed, plaster), 2)
	for y: int in size:
		for x: int in size:
			if posmod(x, TIMBER_SPACING) < TIMBER_WIDTH or posmod(y, TIMBER_SPACING) < TIMBER_WIDTH:
				image.set_pixel(x, y, timber[0])
	return image

func _colors(spec: String) -> PackedColorArray:
	var colors := PackedColorArray()
	for hex: String in spec.split(",", false):
		colors.append(Color.html(hex))
	return colors

func _args() -> Dictionary:
	var parsed := {}
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--"):
			var parts := arg.substr(2).split("=", true, 1)
			parsed[parts[0]] = parts[1] if parts.size() == 2 else ""
	return parsed
