extends SceneTree

## Converts an input image to an art prompt's frame sheet; inspect the result before use.
##
##   "<godot>" --headless --path . -s res://tools/art/process_image.gd -- \
##       --prompt=<id> --in=<picture or strip> [--key=#ff00ff] [--no-trim] [--no-palette]

const PALETTE := "res://tools/art/palette.json"

func _init() -> void:
	var args := _args()
	var prompt := ArtPrompt.find(args.get("prompt", ""))
	assert(prompt != null, "--prompt=<id> must name a file in %s" % ArtPrompt.DIR)
	var source := Image.load_from_file(args.get("in", ""))
	assert(source != null, "--in=<png> could not be read")
	source.convert(Image.FORMAT_RGBA8)
	if args.has("key"):
		# Explicit keys apply everywhere, including enclosed holes.
		source = ImageOps.key_out(source, Color.html(args["key"]), 0.25, true)
	elif source.get_pixel(0, 0).a > 0.0:
		source = ImageOps.key_out(source, source.get_pixel(0, 0))
	# Discard incomplete trailing columns that cannot form a frame.
	var width := source.get_width() - source.get_width() % prompt.frames
	var frames := ImageOps.split_strip(source.get_region(Rect2i(0, 0, width, source.get_height())), prompt.frames)
	if not args.has("no-trim"):
		frames = ImageOps.trim_frames(frames)
	# Quantize before shrinking so palette colours, not render noise, determine each block.
	if not args.has("no-palette"):
		var palette := _palette()
		for i: int in frames.size():
			frames[i] = ImageOps.quantize(frames[i], palette)
	var sheet := ImageOps.pack_strip(frames, prompt.frame_size)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(prompt.target.get_base_dir()))
	sheet.save_png(ProjectSettings.globalize_path(prompt.target))
	print("Wrote %s (%d frame(s) of %s)" % [prompt.target, prompt.frames, prompt.frame_size])
	quit()

func _palette() -> PackedColorArray:
	var colors := PackedColorArray()
	for hex: String in JSON.parse_string(FileAccess.get_file_as_string(PALETTE)):
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
