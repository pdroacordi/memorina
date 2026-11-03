extends SceneTree
## Loads the playtest runner (or, with AUDIO_TITLE=1, the boot scene: pass `-- --title`) and adds audio_probe.gd to the root.
## Run: "$GODOT_WINDOWED" --path . -s res://tools/playtest/scripts/audio_probe_driver.gd -- --script=<timeline> --out=<dir>
## AUDIO_QUIT=<s> quits after that many real seconds. AUDIO_KEYS="t:Key,t:Key" presses raw keys at real seconds (title runs, where no timeline runs).

func _initialize() -> void:
	root.add_child.call_deferred(load("res://tools/playtest/scripts/audio_probe.gd").new())
	if OS.get_environment("AUDIO_TITLE") == "1":
		change_scene_to_file.call_deferred("res://scenes/boot/boot.tscn")
	else:
		change_scene_to_file.call_deferred("res://tools/playtest/playtest_runner.tscn")
	if OS.get_environment("AUDIO_QUIT") != "":
		create_timer(float(OS.get_environment("AUDIO_QUIT")), true, false, true).timeout.connect(quit)
	for pair in OS.get_environment("AUDIO_KEYS").split(",", false):
		var parts := pair.split(":")
		create_timer(float(parts[0]), true, false, true).timeout.connect(_tap.bind(OS.find_keycode_from_string(parts[1]), parts[1]))

func _tap(code: Key, label: String) -> void:
	print("[key] %s at %d ms" % [label, Time.get_ticks_msec()])
	for pressed in [true, false]:
		var e := InputEventKey.new()
		e.keycode = code
		e.physical_keycode = code
		e.pressed = pressed
		Input.parse_input_event(e)
