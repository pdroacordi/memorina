extends SceneTree

## Writes a 128x576 look sheet on the corner-Wang contract (architecture/biome-tilesets); inspect it in a room before use.
##
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
	if args.has("from-blob"):
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
		assert(false, "give --from-blob=<png> or --placeholder")
	var out := ProjectSettings.globalize_path(args["out"])
	DirAccess.make_dir_recursive_absolute(out.get_base_dir())
	var error := WangSheet.pack(bands).save_png(out)
	assert(error == OK, "could not write %s" % out)
	print("wrote %s" % out)
	quit()

func _args() -> Dictionary:
	var parsed := {}
	for arg: String in OS.get_cmdline_user_args():
		if not arg.begins_with("--"):
			continue
		var parts := arg.substr(2).split("=", true, 1)
		parsed[parts[0]] = parts[1] if parts.size() == 2 else ""
	return parsed
