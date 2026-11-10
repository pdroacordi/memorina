extends SceneTree
## UI-07 probe: runs the playtest runner (default) or Boot with --title (PROBE_TITLE=1, schedule from PROBE_KEYS json)
## and prints [probe] on every change of the settings / pause / focus / bindings / Ivo state.
## Run: "$GODOT" --path . -s res://tools/playtest/scripts/ui07_settings_probe_driver.gd -- --script=<timeline> --out=<dir>;
## title: PROBE_TITLE=1 PROBE_KEYS=<abs json> PROBE_OUT=<dir> ... -- --title (redirect APPDATA: the title session writes settings_debug.cfg).
var _last := ""
var _t0 := 0
var _sched: Array = []
var _out := ""
var _title := false
var _rects := false

func _initialize() -> void:
	_t0 = Time.get_ticks_msec()
	_title = OS.get_environment("PROBE_TITLE") == "1"
	print("[probe] userdir=", OS.get_user_data_dir())
	if _title:
		var f := FileAccess.open(OS.get_environment("PROBE_KEYS"), FileAccess.READ)
		_sched = JSON.parse_string(f.get_as_text())
		_out = OS.get_environment("PROBE_OUT")
		DirAccess.make_dir_recursive_absolute(_out)
		change_scene_to_file.call_deferred("res://scenes/boot/boot.tscn")
	else:
		change_scene_to_file.call_deferred("res://tools/playtest/playtest_runner.tscn")

func _now() -> float:
	return (Time.get_ticks_msec() - _t0) / 1000.0

func _ev(e: InputEvent) -> String:
	if e is InputEventKey:
		var k := e as InputEventKey
		return OS.get_keycode_string(k.physical_keycode if k.physical_keycode != 0 else k.keycode)
	if e is InputEventJoypadButton:
		return "J%d" % (e as InputEventJoypadButton).button_index
	if e is InputEventJoypadMotion:
		return "A%d" % (e as InputEventJoypadMotion).axis
	return e.get_class()

func _acts(a: String) -> String:
	var p: PackedStringArray = []
	if not InputMap.has_action(a):
		return "-"
	for e in InputMap.action_get_events(a):
		p.append(_ev(e))
	return ",".join(p)

func _process(_d: float) -> bool:
	var now := _now()
	while _title and not _sched.is_empty() and float(_sched[0].t) <= now:
		_do(_sched.pop_front())
	var parts: PackedStringArray = []
	parts.append("paused=%s ts=%.2f" % [paused, Engine.time_scale])
	var vp := root
	var fo := vp.gui_get_focus_owner()
	var ft := ""
	if fo != null:
		ft = "%s/%s('%s')" % [fo.get_parent().name, fo.name, fo.get("text") if fo.get("text") != null else ""]
	parts.append("focus=" + ft)
	var ss: Control = root.find_child("SettingsScreen", true, false)
	if ss != null:
		if ss.is_visible_in_tree() and not _rects:
			_rects = true
			for pg in ["KeyboardPage", "SoundPage"]:
				var n: Control = ss.get_node("%" + pg)
				var rs: PackedStringArray = []
				for c in n.get_children():
					rs.append("%s y=%.1f h=%.1f" % [c.name, c.position.y, c.size.y])
				print("[probe] rects %s pos=%s: %s" % [pg, n.position, ", ".join(rs)])
			var stl: Control = ss.get_node("%Status")
			print("[probe] rects Status pos=%s size=%s" % [stl.position, stl.size])
		parts.append("set=%s page=%s status='%s' capt=%s" % [ss.is_visible_in_tree(), ss.call("page"), ss.call("status"), ss.call("is_capturing")])
		var playing: PackedStringArray = []
		for n in ["MasterPreview", "MusicPreview", "NotesPreview", "SfxPreview"]:
			var pl: AudioStreamPlayer = ss.get_node_or_null("%" + n)
			if pl != null and pl.playing:
				playing.append("%s(%s,%.0fdB)" % [n, pl.bus, pl.volume_db])
		parts.append("preview=[%s]" % ",".join(playing))
		for c in ["ConfirmResetKeyboard", "ConfirmResetPad"]:
			var cp: Control = ss.get_node_or_null("%" + c)
			if cp != null and cp.visible:
				parts.append(c)
	var st: Node = root.get_node_or_null("Settings")
	if st != null:
		var v: PackedStringArray = []
		for b in ["Master", "Music", "Notes", "Sfx"]:
			var idx := AudioServer.get_bus_index(b)
			v.append("%s=%d(%.1fdB%s)" % [b, st.call("volume", StringName(b)), AudioServer.get_bus_volume_db(idx) if idx >= 0 else -999.0, " mute" if idx >= 0 and AudioServer.is_bus_mute(idx) else ""])
		parts.append("vol " + " ".join(v))
		parts.append("lang=%s locale=%s disk=%s" % [st.call("current_language"), TranslationServer.get_locale(), st.call("has_disk")])
	parts.append("jump=[%s] zin=[%s] map=[%s] attack=[%s] accept=[%s]" % [_acts("jump"), _acts("map_zoom_in"), _acts("map"), _acts("attack"), _acts("ui_accept")])
	var mi: Node = root.find_child("MenuInput", true, false)
	if mi != null:
		parts.append("mi_capt=%s" % mi.get("capturing"))
	var wf: Node = root.find_child("WorldFreeze", true, false)
	if wf != null:
		parts.append("held=%s" % wf.call("is_held"))
	var p: Node2D = root.find_child("Player", true, false) as Node2D
	if p != null and p is CharacterBody2D:
		var cb := p as CharacterBody2D
		parts.append("ivo=(%d,%d) vy=%d floor=%s" % [p.global_position.x, p.global_position.y, cb.velocity.y, cb.is_on_floor()])
	var line := " | ".join(parts)
	if line != _last:
		_last = line
		print("[probe] t=%.2f %s" % [now, line])
	return false

func _do(s: Dictionary) -> void:
	if s.has("screenshot"):
		var img := root.get_texture().get_image()
		img.save_png(_out.path_join(String(s.screenshot) + ".png"))
		print("[probe] shot ", s.screenshot, " t=%.2f" % _now())
		return
	if s.has("quit"):
		quit()
		return
	if s.has("key"):
		var e := InputEventKey.new()
		var code := OS.find_keycode_from_string(String(s.key))
		e.keycode = code
		e.physical_keycode = code
		e.pressed = bool(s.pressed)
		Input.parse_input_event(e)
	elif s.has("joy_button"):
		var j := InputEventJoypadButton.new()
		j.button_index = int(s.joy_button)
		j.pressed = bool(s.pressed)
		Input.parse_input_event(j)
