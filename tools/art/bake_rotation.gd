extends SceneTree

## Bakes a wheel or sails still into a strip of turning frames ("Baked pixel frames", user, 2026-10-09).
##   "<godot>" --headless --path . -s res://tools/art/bake_rotation.gd -- --in=<still.png> --out=<strip.png>
##       --frames=12 --period=45
## The still is a 2x-density PNG; it is halved to art px and turned over one symmetry period (`--period` degrees,
## 360 / symmetry order) by RotationBake, read through one sector so the loop closes, and written back at 2x. It
## prints each step's changed px and the wrap ratio (the last-to-first step over the median; about 1 means no hitch).


func _init() -> void:
	var options := {}
	for arg: String in OS.get_cmdline_user_args():
		var parts := arg.trim_prefix("--").split("=", true, 1)
		options[parts[0]] = parts[1] if parts.size() > 1 else ""
	var still := Image.load_from_file(ProjectSettings.globalize_path(options["in"]))
	still.convert(Image.FORMAT_RGBA8)
	still.resize(still.get_width() / 2, still.get_height() / 2, Image.INTERPOLATE_NEAREST)
	var frames := RotationBake.frames(still, int(options.get("frames", "12")), float(options.get("period", "45")))
	var out := RotationBake.strip(frames, 2)
	out.save_png(ProjectSettings.globalize_path(options["out"]))
	print("%s: %d frames of %dx%d" % [options["out"], frames.size(), out.get_height(), out.get_height()])
	print("steps (art px): %s, wrap ratio %.2f" % [RotationBake.steps(frames), RotationBake.wrap_ratio(frames)])
	quit()
