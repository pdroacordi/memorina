extends SceneTree

## Writes a 128x576 look sheet on the corner-Wang contract (architecture/biome-tilesets); inspect it in a room before use.
##
##   Composed from a recipe (tools/art/tiles/<biome>_<look>.json: body, variants, a lip per band, edges):
##   "<godot>" --headless --path . -s res://tools/art/assemble_tile_sheet.gd -- --recipe=<json> --out=<png>
##   Legacy 8-neighbour sheet -> Wang (every band):
##   "<godot>" --headless --path . -s res://tools/art/assemble_tile_sheet.gd -- \
##       --from-blob=<png> --blob-column=0|9 --out=<png> [--no-ledge]
##   Flat placeholder (one fill, a lip per band):
##   "<godot>" --headless --path . -s res://tools/art/assemble_tile_sheet.gd -- \
##       --placeholder --fill=#rrggbb --lips=#spring,#autumn,#winter --out=<png> [--no-ledge]

const BANDS := 3

func _init() -> void:
	var args := _args()
	assert(args.has("out"), "--out=<png> is required")
	var bands: Array[Dictionary] = []
	if args.has("recipe"):
		var text := FileAccess.get_file_as_string(ProjectSettings.globalize_path(args["recipe"]))
		var recipe: Dictionary = JSON.parse_string(text.trim_prefix(String.chr(0xFEFF)))
		assert(recipe != null, "--recipe=<json> could not be read")
		bands = _composed(recipe)
	elif args.has("from-blob"):
		var source := Image.load_from_file(ProjectSettings.globalize_path(args["from-blob"]))
		assert(source != null, "--from-blob=<png> could not be read")
		source.convert(Image.FORMAT_RGBA8)
		var column0 := int(args.get("blob-column", "0"))
		for band: int in BANDS:
			var entry := {"tiles": WangSheet.tiles_from_blob(source, column0, band)}
			if not args.has("no-ledge"):
				entry["ledge"] = WangSheet.ledge_from_blob(source, column0, band)
			bands.append(entry)
	elif args.has("placeholder"):
		var fill := Color.html(args.get("fill", "#808080"))
		var lips: PackedStringArray = args.get("lips", "").split(",", false)
		for band: int in BANDS:
			var lip := Color.html(lips[band]) if band < lips.size() else fill
			var entry := {"tiles": WangSheet.placeholder_tiles(fill, lip)}
			if not args.has("no-ledge"):
				entry["ledge"] = WangSheet.placeholder_ledge(fill, lip)
			bands.append(entry)
	else:
		assert(false, "give --recipe=<json>, --from-blob=<png> or --placeholder")
	var out := ProjectSettings.globalize_path(args["out"])
	DirAccess.make_dir_recursive_absolute(out.get_base_dir())
	var error := WangSheet.pack(bands).save_png(out)
	assert(error == OK, "could not write %s" % out)
	print("wrote %s" % out)
	quit()

func _composed(recipe: Dictionary) -> Array[Dictionary]:
	var body := _body(recipe["body"])
	var spill := int(recipe.get("spill", 6))
	var depth := int(recipe.get("depth", 4))
	var radius := int(recipe.get("radius", 5))
	var rim := int(recipe.get("rim", 3))
	var edge := Color.html(recipe.get("edge", "#140c08"))
	var ledge_height := int(recipe.get("ledge_height", 0))
	var variants: Array[Image] = []
	var decor := _decor_colors(recipe.get("decor_colors", {}))
	for variant: Dictionary in recipe.get("variants", []):
		variants.append(TilePainter.decorated(body, int(variant["seed"]), int(variant["count"]), PackedStringArray(variant["kinds"]), decor))
	var lips: Array = recipe.get("lips", [])
	var bands: Array[Dictionary] = []
	for band: int in BANDS:
		var lip := _lip(lips[mini(band, lips.size() - 1)] if not lips.is_empty() else {}, spill, depth)
		var entry := {"tiles": WangSheet.compose(body, lip, spill, radius, rim, edge), "variants": variants}
		if ledge_height > 0:
			entry["ledge"] = WangSheet.compose_ledge(body, lip, spill, ledge_height, radius, rim, edge)
		bands.append(entry)
	return bands

## The body a recipe names: a painted kind, a 32 px png, or a PixelLab tileset result's full tile.
func _body(spec: Dictionary) -> Image:
	var rng_seed := int(spec.get("seed", 1))
	match spec["kind"]:
		"noise":
			return TilePainter.noise_body(rng_seed, _colors(spec["ramp"]))
		"stone":
			return TilePainter.stone_body(rng_seed, int(spec.get("count", 6)), _colors(spec["ramp"]), Color.html(spec["mortar"]), _colors(spec.get("moss", [])))
		"plank":
			return TilePainter.plank_body(rng_seed, int(spec.get("board", 8)), _colors(spec["ramp"]), Color.html(spec["gap"]), Color.html(spec["nail"]))
		"timber":
			return TilePainter.timber_body(rng_seed, _colors(spec["plaster"]), _colors(spec["timber"]))
		"pixellab":
			var text := FileAccess.get_file_as_string(ProjectSettings.globalize_path(spec["path"]))
			var result: Dictionary = JSON.parse_string(text.trim_prefix(String.chr(0xFEFF)))
			return WangSheet.tiles_from_pixellab(result)[GroundAutotile.FULL]
	var image := Image.load_from_file(ProjectSettings.globalize_path(spec["path"]))
	assert(image != null and image.get_size() == Vector2i(WangSheet.TILE, WangSheet.TILE), "a png body must be 32 px")
	image.convert(Image.FORMAT_RGBA8)
	return image

func _lip(spec: Dictionary, spill: int, depth: int) -> Image:
	var rng_seed := int(spec.get("seed", 1))
	match spec.get("kind", "none"):
		"grass":
			return WangSheet.blade_strip(rng_seed, _colors(spec["greens"]), _colors(spec.get("flowers", [])), spill, depth)
		"litter":
			return WangSheet.litter_strip(rng_seed, _colors(spec["leaves"]), spill, depth)
		"snow":
			return WangSheet.snow_strip(rng_seed, _colors(spec["whites"]), _colors(spec["shades"]), spill, depth)
		"cobbles":
			return WangSheet.cobble_strip(rng_seed, _colors(spec["stones"]), Color.html(spec["joint"]), spill, depth)
		"layers":
			var strips: Array[Image] = []
			for layer: Dictionary in spec["layers"]:
				strips.append(_lip(layer, spill, depth))
			return WangSheet.layered(strips)
	return Image.create_empty(WangSheet.TILE, spill + depth, false, Image.FORMAT_RGBA8)

func _decor_colors(spec: Dictionary) -> Dictionary:
	var colors := {}
	for key: String in spec:
		colors[key] = Color.html(spec[key])
	return colors

func _colors(hexes: Array) -> PackedColorArray:
	var colors := PackedColorArray()
	for hex: String in hexes:
		colors.append(Color.html(hex))
	return colors

func _args() -> Dictionary:
	var parsed := {}
	for arg: String in OS.get_cmdline_user_args():
		if not arg.begins_with("--"):
			continue
		var parts := arg.substr(2).split("=", true, 1)
		parsed[parts[0]] = parts[1] if parts.size() == 2 else ""
	return parsed
