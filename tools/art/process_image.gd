extends SceneTree

## Turns a generated (or pack-cropped) picture into the sheet its prompt's
## frame contract promises, and writes it to the contract's target:
##   1. key out the background by flood fill from the edges (skipped when the
##      picture is already transparent at its corners); an explicit --key is
##      cleared everywhere, holes the subject encloses included,
##   2. split it into the contract's frames and crop them to their shared
##      opaque bounds (a generated picture's margin; --no-trim keeps it),
##   3. snap every pixel onto tools/art/palette.json, at full size,
##   4. scale each frame by one factor to fit the contract's frame, standing
##      bottom-centre (a large shrink keeps each block's most common colour,
##      ImageOps.shrink_mode), and pack them into the strip a Sprite2D reads.
## Then run --import. Look at the result before committing it.
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
		# An explicit key is a colour the subject was drawn without, so it is
		# background wherever it is - enclosed holes too.
		source = ImageOps.key_out(source, Color.html(args["key"]), 0.25, true)
	elif source.get_pixel(0, 0).a > 0.0:
		source = ImageOps.key_out(source, source.get_pixel(0, 0))
	# A generated picture is rarely a multiple of the frame count wide; the
	# columns left over at the right are keyed-out background.
	var width := source.get_width() - source.get_width() % prompt.frames
	var frames := ImageOps.split_strip(source.get_region(Rect2i(0, 0, width, source.get_height())), prompt.frames)
	if not args.has("no-trim"):
		frames = ImageOps.trim_frames(frames)
	# Snapped BEFORE packing, at full size, so a large shrink counts palette
	# colours (ImageOps.shrink_mode) instead of the render's noise.
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
