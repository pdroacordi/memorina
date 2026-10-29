extends SceneTree
## Runs the playtest runner and prints teacher flow, balloon, echo, HUD and save state on every change ([probe]) and Ivo's signals ([sig]).
## Run: "$GODOT" --path . -s <abs>/core04_probe_driver.gd -- --script=<timeline> --out=<dir>. No autoload or class name is referenced (a -s script compiles before autoloads exist).
var _last := ""
var _frames := 0
var _hooked := false
const STATES := ["AWAY", "SINGING", "LISTENING", "DUET", "FLOURISH", "TAUGHT_QUIET", "TAUGHT_SINGING"]
var _cache: Array = []
func _initialize() -> void:
	change_scene_to_file.call_deferred("res://tools/playtest/playtest_runner.tscn")
func _process(_delta: float) -> bool:
	var runner := current_scene
	if runner == null:
		return false
	var p: Node = root.find_child("Player", true, false)
	if p == null or not p.has_method("is_echo_open"):
		return false
	if not _hooked:
		_hooked = true
		for sig in ["memorina_drawn", "memorina_sheathed", "note_played", "note_rejected", "sequence_failed", "sequence_reset", "phrase_echoed", "echo_opened", "echo_closed", "song_half_learned", "lesson_started", "performance_started", "performance_finished", "song_played"]:
			if p.has_signal(sig):
				var argc: int = p.get_signal_list().filter(func(x: Dictionary) -> bool: return x.name == sig)[0].args.size()
				var cb: Callable = _on_sig.bind(sig, runner)
				p.connect(sig, cb.unbind(argc) if argc > 0 else cb)
	var parts: PackedStringArray = []
	_frames += 1
	if _frames % 60 == 1:
		_cache = _teachers(root, [])
	for t: Node in _cache:
		if not is_instance_valid(t):
			continue
		var fl: RefCounted = t.flow()
		parts.append("%s:%s sing=%s fp=%s" % [t.name, STATES[fl.state()], t.is_singing(), t.flourish_pending()])
	var b: Control = root.find_child("TeacherBalloon", true, false)
	if b != null:
		parts.append("bal vis=%s pos=(%d,%d) rev=%s lit=%d shake=%s" % [b.visible, b.get_node("Box").position.x if b.has_node("Box") else -1, b.get_node("Box").position.y if b.has_node("Box") else -1, b.get("_revealed"), b.get("_lit_count"), absf(b.get("_shake")) > 0.01])
	var hud: Control = root.find_child("MemorinaHud", true, false)
	if hud != null:
		parts.append("hud vis=%s frame=%s echoing=%s" % [hud.visible, (hud.get_node("Frame") as CanvasItem).visible, hud.get("_echoing")])
	var mem: Node = p.get_node("Memorina")
	parts.append("echo=%s drawn=%s lesson=%s" % [p.is_echo_open(), mem.is_drawn(), p.is_in_lesson()])
	var d: Resource = root.get_node("SaveSystem").player_data
	parts.append("first=%s second=%s learned=%s guessed=%s" % [_bits(d.song_first_halves), _bits(d.song_second_halves), _bits(d.learned_songs), d.guessed_halves])
	var toast := root.find_child("NotebookToast", true, false) as CanvasItem
	if toast != null:
		parts.append("quill=%.1f" % toast.modulate.a)
	parts.append("paused=%s ts=%.2f" % [paused, Engine.time_scale])
	var line := " | ".join(parts)
	if line != _last:
		_last = line
		print("[probe] t=%.3f %s" % [float(runner.get("_elapsed")), line])
	return false
func _bits(a: Array) -> String:
	var s := ""
	for v: bool in a:
		s += "1" if v else "0"
	return s
func _teachers(n: Node, acc: Array) -> Array:
	if n.has_method("flourish_pending") and n.has_method("flow"):
		acc.append(n)
	for c in n.get_children():
		_teachers(c, acc)
	return acc

func _on_sig(sig: String, runner: Node) -> void:
	print("[sig] t=%.3f %s" % [float(runner.get("_elapsed")), sig])
