extends SceneTree
## MEM-05 probe: runs the playtest runner and prints [wx] every WX_MS real ms (default 100; 0 = every frame): the
## region gust clock, strength, fight level, drive, the air at Ivo, the memory there, the snow layers and Ivo's motion.
## Optional WX_MEMORY=<0..1> holds a scratch MemorySource-free override: it is applied by writing the field's baseline.
## Run: "$GODOT" --path . -s res://tools/playtest/scripts/mem05_weather_probe_driver.gd -- --script=<timeline> --out=<dir>.
## No autoload or class name is referenced (a -s script compiles before autoloads exist).
var _last_ms := -100000
var _every := 100
var _baseline := -1.0
var _hooked := false

func _initialize() -> void:
	_every = int(OS.get_environment("WX_MS")) if OS.get_environment("WX_MS") != "" else 100
	_baseline = float(OS.get_environment("WX_MEMORY")) if OS.get_environment("WX_MEMORY") != "" else -1.0
	print("[wx] userdir=", OS.get_user_data_dir())
	change_scene_to_file.call_deferred("res://tools/playtest/playtest_runner.tscn")

func _process(_delta: float) -> bool:
	var runner := current_scene
	if runner == null:
		return false
	var p := root.find_child("Player", true, false) as CharacterBody2D
	var rw: Node = root.find_child("RegionWind", true, false)
	var rwx: Node = root.find_child("RegionWeather", true, false)
	if p == null or rw == null:
		return false
	if not _hooked:
		_hooked = true
		for sig in ["memorina_drawn", "memorina_sheathed", "note_played", "note_rejected", "sequence_failed", "sequence_reset", "performance_started", "performance_finished", "song_played"]:
			if p.has_signal(sig):
				var argc: int = p.get_signal_list().filter(func(x: Dictionary) -> bool: return x.name == sig)[0].args.size()
				var cb: Callable = _on_sig.bind(sig, runner, p)
				p.connect(sig, cb.unbind(argc) if argc > 0 else cb)
	var mf: Node = rw.get("_memory")
	if _baseline >= 0.0 and mf != null:
		mf.set("baseline", _baseline)
	var now := Time.get_ticks_msec()
	if _every > 0 and now - _last_ms < _every:
		return false
	_last_ms = now
	var pos := p.global_position
	var parts: PackedStringArray = []
	parts.append("t=%.2f real=%.2f" % [float(runner.get("_elapsed")), now / 1000.0])
	var game: Node = root.find_child("Game", true, false)
	var room: Node = game.get("_current_room") if game != null else null
	parts.append("room=%s" % (room.name if room != null else "-"))
	parts.append("pos=(%.1f,%.1f) vel=(%.1f,%.1f) floor=%s" % [pos.x, pos.y, p.velocity.x, p.velocity.y, p.is_on_floor()])
	var mem: Node = p.get_node_or_null("Memorina")
	if mem != null:
		parts.append("drawn=%s" % mem.call("is_drawn"))
	var g: RefCounted = rw.get("_gust")
	if g != null:
		parts.append("gt=%.2f str=%.3f fight=%.2f" % [float(g.get("_time")), float(g.call("strength")), float(g.get("_fight_level"))])
	else:
		parts.append("gust=none")
	parts.append("drive=%.3f wind=%.1f" % [float(rw.call("drive")), (rw.call("wind_at", pos) as Vector2).x])
	var af: Node = root.find_child("Airflow", true, false)
	if af != null and af.has_method("sample"):
		parts.append("air=%.1f" % (af.call("sample", pos) as Vector2).x)
	if mf != null:
		parts.append("mem=%.3f base=%.2f" % [float(mf.call("sample", pos)), float(mf.get("baseline"))])
	var st: Node = root.get_node_or_null("Settings")
	if st != null:
		parts.append("int=%.1f" % float(st.call("weather_intensity")))
	if rwx != null:
		var gl: CPUParticles2D = rwx.get("_gust_layer")
		var am: CPUParticles2D = rwx.get("_particles")
		parts.append("wvis=%s sky=%.2f/%.0f" % [(rwx as CanvasItem).visible, float(rwx.get("_sky_level")), float(rwx.get("_sky_target"))])
		if gl != null:
			parts.append("gust_a=%.2f dir=%.0f spd=%.2f" % [gl.modulate.a, gl.direction.x, gl.speed_scale])
		if am != null:
			parts.append("amb_a=%.2f" % am.modulate.a)
	parts.append("paused=%s" % paused)
	print("[wx] " + " ".join(parts))
	return false

func _on_sig(sig: String, runner: Node, p: CharacterBody2D) -> void:
	print("[sig] t=%.2f %s pos=(%.1f,%.1f) vel=%.1f" % [float(runner.get("_elapsed")), sig, p.global_position.x, p.global_position.y, p.velocity.x])
