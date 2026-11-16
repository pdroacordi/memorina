extends SceneTree
## Dev-only cue log for the SND-01 playtest (2026-11-16): loads the playtest runner and prints every SfxEmitter voice.
## Run: "$GODOT" --path . -s res://tools/playtest/scripts/snd01_cue_log_driver.gd -- --script=<timeline> --out=<dir>
## Prints [sfx] per `cue_played` (real ms, process frame, cue path, emitter owner, bus, pause, time scale, Ivo's pos,
## clip, floor surface, process mode), [muf] when the SfxWorld low-pass changes, [voices] every 0.5 real s listing SFX
## players still playing, [ivo] when Ivo's node is replaced (a world rebuild).
## Env (forced test beds, label their results "forced"): SND_SHALLOW="x,y,w" adds a water_shallow body with its top-left
## at (x, y), w px wide, 24 deep, to the world once Ivo exists; SND_KILL=<real s> deals Ivo 999 damage then;
## SND_BOT="<start real s>:<end real s>" walks Ivo to the nearest creature and swings until it dies; SND_GOD=1 keeps
## Ivo's hp topped up. No autoload or class_name is referenced (a -s script compiles before them).

const SURFACES := ["NONE", "EARTH", "STONE", "SNOW", "WOOD", "SHALLOW_WATER"]

var _t0 := 0
var _frame := 0
var _ivo: Node
var _muf := ""
var _next_voices := 0
var _shallow_done := false
var _bot := Vector2(-1, -1)
var _bot_dir := 0
var _next_swing := 0


func _initialize() -> void:
	_t0 = Time.get_ticks_msec()
	node_added.connect(_on_node_added)
	process_frame.connect(_on_frame)
	physics_frame.connect(_on_physics)
	change_scene_to_file.call_deferred("res://tools/playtest/playtest_runner.tscn")
	var kill := OS.get_environment("SND_KILL")
	if kill != "":
		create_timer(float(kill), true, false, true).timeout.connect(_kill)
	var bot := OS.get_environment("SND_BOT")
	if bot != "":
		var parts := bot.split(":")
		_bot = Vector2(float(parts[0]), float(parts[1]))

func _t() -> float:
	return (Time.get_ticks_msec() - _t0) / 1000.0

func _on_node_added(node: Node) -> void:
	if node.has_signal(&"cue_played") and node.is_in_group(&"sfx_emitters"):
		node.connect(&"cue_played", _on_cue.bind(node))

func _on_cue(cue: Resource, emitter: Node) -> void:
	var owner_path := str(emitter.get_parent().get_path()) if emitter.get_parent() != null else "?"
	var line := "[sfx] t=%.3f f=%d cue=%s owner=%s bus=%s paused=%s ts=%.2f" % [_t(), _frame, cue.resource_path,
		owner_path.trim_prefix("/root/PlaytestRunner/"), cue.call(&"bus"), paused, Engine.time_scale]
	line += _ivo_state()
	print(line)

func _ivo_state() -> String:
	if _ivo == null or not is_instance_valid(_ivo):
		return " ivo=none"
	var surface: int = _ivo.call(&"floor_surface")
	return " ivo=(%.1f,%.1f) vel=(%.0f,%.0f) clip=%s pos=%.3f surf=%s stroll=%s pmode=%d hp=%d" % [
		_ivo.global_position.x, _ivo.global_position.y, _ivo.velocity.x, _ivo.velocity.y,
		_ivo.call(&"animation_state"), _ivo.call(&"animation_position"),
		SURFACES[surface] if surface < SURFACES.size() else str(surface), _ivo.call(&"is_strolling"),
		_ivo.process_mode, _ivo.get(&"health").get(&"current_hp")] + _true_surface()

## The surface of the Solid cell under Ivo's feet, looked up by position (cross-check of StepSurfaceProbe).
func _true_surface() -> String:
	var feet: Vector2 = (_ivo as Node2D).global_position + Vector2(0, 4)
	var query := PhysicsPointQueryParameters2D.new()
	query.position = feet
	query.collision_mask = 0xFFFFFFFF
	for hit: Dictionary in (_ivo as Node2D).get_world_2d().direct_space_state.intersect_point(query, 8):
		var layer := hit.collider as TileMapLayer
		if layer != null and layer.get_parent() != null and layer.get_parent().has_method(&"surface_at"):
			var cell := layer.local_to_map(layer.to_local(feet))
			var quad := layer.get_coords_for_body_rid(hit.rid)
			var s: int = layer.get_parent().call(&"surface_at", cell)
			var q: int = layer.get_parent().call(&"surface_at", quad)
			return " true=%s cell=%s rid_coords=%s(%s)" % [SURFACES[s], cell, quad, SURFACES[q]]
	return " true=-"

func _on_frame() -> void:
	_frame += 1
	var ivo := get_first_node_in_group(&"player")
	if ivo != _ivo and ivo != null:
		_ivo = ivo
		print("[ivo] t=%.3f f=%d new Ivo %s at %s" % [_t(), _frame, ivo.get_path(), ivo.global_position])
	_log_muffle()
	if _ivo != null and is_instance_valid(_ivo) and not _shallow_done and OS.get_environment("SND_SHALLOW") != "" and _t() > 2.0:
		_add_shallow()
	if OS.get_environment("SND_GOD") == "1" and _ivo != null and is_instance_valid(_ivo):
		var health: Node = _ivo.get(&"health")
		if int(health.get(&"current_hp")) < int(health.get(&"max_hp")) and int(health.get(&"current_hp")) > 0:
			health.call(&"heal", 9)
	var now := Time.get_ticks_msec()
	if now >= _next_voices:
		_next_voices = now + 500
		_log_voices()

func _log_muffle() -> void:
	var bus := AudioServer.get_bus_index("SfxWorld")
	if bus < 0:
		return
	var text := ""
	for i: int in AudioServer.get_bus_effect_count(bus):
		var effect := AudioServer.get_bus_effect(bus, i)
		if effect is AudioEffectLowPassFilter:
			text = "on=%s cutoff=%d" % [AudioServer.is_bus_effect_enabled(bus, i),
				roundi((effect as AudioEffectLowPassFilter).cutoff_hz / 50.0) * 50]
	if text != _muf:
		_muf = text
		print("[muf] t=%.3f f=%d %s paused=%s%s" % [_t(), _frame, text, paused, _ivo_state()])

func _log_voices() -> void:
	var playing: PackedStringArray = []
	for emitter: Node in get_nodes_in_group(&"sfx_emitters"):
		for child: Node in emitter.get_children():
			if (child is AudioStreamPlayer or child is AudioStreamPlayer2D) and child.get(&"playing"):
				playing.append("%s<%s>@%.2f" % [str(emitter.get_parent().name), child.get(&"stream").resource_path.get_file(),
					child.call(&"get_playback_position")])
	if not playing.is_empty():
		print("[voices] t=%.3f %s" % [_t(), " ".join(playing)])

func _add_shallow() -> void:
	_shallow_done = true
	var parts := OS.get_environment("SND_SHALLOW").split(",")
	var body := (load("res://scenes/world/environment/water/water_shallow.tscn") as PackedScene).instantiate() as Node2D
	body.set(&"size", Vector2i(int(parts[2]), 24))
	body.position = Vector2(float(parts[0]), float(parts[1]))
	var game := root.find_child("Game", true, false)
	game.add_child(body)
	print("[forced] t=%.3f shallow water at %s size %s" % [_t(), body.position, body.get(&"size")])

func _kill() -> void:
	if _ivo != null and is_instance_valid(_ivo):
		print("[forced] t=%.3f kill Ivo at %s" % [_t(), _ivo.global_position])
		_ivo.get(&"health").call(&"take_damage", 999)

func _on_physics() -> void:
	if _bot.x < 0 or _ivo == null or not is_instance_valid(_ivo):
		return
	var t := _t()
	if t < _bot.x:
		return
	var target: Node2D = null
	var best := 500.0
	for node: Node in get_nodes_in_group(&"characters"):
		if node == _ivo or not node.has_method(&"is_dormant") or not (node as CanvasItem).is_visible_in_tree():
			continue
		if int(node.get(&"health").get(&"current_hp")) <= 0:
			continue
		var d: float = (node as Node2D).global_position.distance_to((_ivo as Node2D).global_position)
		if d < best:
			best = d
			target = node
	var dir := 0
	if t < _bot.y and target != null:
		var dx: float = target.global_position.x - (_ivo as Node2D).global_position.x
		if absf(dx) > 34.0:
			dir = 1 if dx > 0 else -1
		elif Time.get_ticks_msec() >= _next_swing:
			_next_swing = Time.get_ticks_msec() + 420
			if (dx > 0) != (int(_ivo.get(&"facing")) > 0):
				_press(&"move_right" if dx > 0 else &"move_left", true)
				_press(&"move_right" if dx > 0 else &"move_left", false)
			_press(&"attack", true)
			_press(&"attack", false)
			print("[bot] t=%.3f swing dx=%.1f foe=%s hp=%d" % [t, dx, target.name, int(target.get(&"health").get(&"current_hp"))])
	if dir != _bot_dir:
		if _bot_dir != 0:
			_press(&"move_right" if _bot_dir > 0 else &"move_left", false)
		if dir != 0:
			_press(&"move_right" if dir > 0 else &"move_left", true)
		_bot_dir = dir

func _press(action: StringName, pressed: bool) -> void:
	var e := InputEventAction.new()
	e.action = action
	e.pressed = pressed
	e.strength = 1.0 if pressed else 0.0
	Input.parse_input_event(e)
