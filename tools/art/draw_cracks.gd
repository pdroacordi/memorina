extends SceneTree

## Writes a biome's 128x96 crack decal sheet: 4 hairline variants across, the same in each season band (architecture/secret-false-walls).
##   "<godot>" --headless --path . -s res://tools/art/draw_cracks.gd -- --out=<png> --color=#rrggbb [--scale=2] [--seed=1]

const VARIANTS := BiomeTileset.CRACK_VARIANTS
const BANDS := 3
## Art px kept clear of every tile edge, so a crack never meets its neighbour.
const MARGIN := 3
## Art px per crack, inclusive.
const MIN_LENGTH := 6
const MAX_LENGTH := 11


func _init() -> void:
	var args := _args()
	assert(args.has("out"), "--out=<png> is required")
	var scale := int(args.get("scale", "1"))
	var color := Color.html(args.get("color", "#2a2622"))
	var rng := RandomNumberGenerator.new()
	rng.seed = int(args.get("seed", "1"))
	var art := RoomMap.CELL_PX / scale
	var sheet := Image.create_empty(VARIANTS * art, BANDS * art, false, Image.FORMAT_RGBA8)
	for variant: int in VARIANTS:
		var tile := _crack(rng, art, color)
		for band: int in BANDS:
			sheet.blit_rect(tile, Rect2i(Vector2i.ZERO, tile.get_size()), Vector2i(variant * art, band * art))
	if scale > 1:
		sheet.resize(sheet.get_width() * scale, sheet.get_height() * scale, Image.INTERPOLATE_NEAREST)
	var out := ProjectSettings.globalize_path(args["out"])
	DirAccess.make_dir_recursive_absolute(out.get_base_dir())
	var error := sheet.save_png(out)
	assert(error == OK, "could not write %s" % out)
	print("wrote %s" % out)
	quit()

## One 8-connected hairline that wanders mostly sideways, inside the margin.
func _crack(rng: RandomNumberGenerator, art: int, color: Color) -> Image:
	var tile := Image.create_empty(art, art, false, Image.FORMAT_RGBA8)
	var at := Vector2i(rng.randi_range(MARGIN, art / 2), rng.randi_range(MARGIN, art - MARGIN - 1))
	var length := rng.randi_range(MIN_LENGTH, MAX_LENGTH)
	for step: int in length:
		tile.set_pixelv(at, color)
		var next := at + Vector2i(1, rng.randi_range(-1, 1))
		if next.x > art - MARGIN - 1:
			break
		at = Vector2i(next.x, clampi(next.y, MARGIN, art - MARGIN - 1))
	return tile

func _args() -> Dictionary:
	var parsed := {}
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--"):
			var parts := arg.substr(2).split("=", true, 1)
			parsed[parts[0]] = parts[1] if parts.size() == 2 else ""
	return parsed
