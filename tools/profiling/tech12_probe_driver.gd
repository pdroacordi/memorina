extends SceneTree
## TECH-12 frame-cost probe: boots the game through the playtest runner, visits one room per region and records CPU, GPU and draw stats.
## Run (windowed, scratch APPDATA): "$GODOT" --path . --disable-vsync -s res://tools/profiling/tech12_probe_driver.gd --
##   --script=res://tools/profiling/tech12_timeline.json --out=<abs dir> --perf_out=<abs json> --size=1280x720 [--attrib=all|none|<room,room>] [--walk]
## Changes only runtime state (visibility, update modes, the cull mask, MemoryField.baseline); docs/knowledge/performance/2026-11-11-tech12-baseline.md.

const SETTLE_S := 3.0
const ARRIVE_S := 4.0
const MEASURE_S := 5.0
const TOGGLE_S := 3.0
const TOGGLE_SETTLE_S := 0.6
const WALK_S := 16.0

## [room id, Ivo's feet position]; one busy room per region, plus an interior.
const VISITS: Array = [
	["village_mill", Vector2(2576, 286)],
	["threshold_fields", Vector2(5648, 286)],
	["frost_shore", Vector2(9520, 286)],
	["woods_edge", Vector2(-2384, 286)],
	["lake_fishing_village", Vector2(1616, -1634)],
	["orchard_mill_town", Vector2(-7024, -1250)],
	["caldera_open_crater", Vector2(-1296, 2206)],
	["village_house", Vector2(320, 12286)],
]
const VILLAGE_LEVELS: Array[float] = [0.6, 0.0, 1.0]
const WALK_START := Vector2(1616, 286)

var _results: Dictionary = {}
var _perf_out := ""
var _size := Vector2i(1280, 720)
var _attrib := "all"
var _walk := false
var _vsync := false
var _room_events: Array = []
var _t0 := 0


func _initialize() -> void:
	_t0 = Time.get_ticks_msec()
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--perf_out="):
			_perf_out = arg.get_slice("=", 1)
		elif arg.begins_with("--size="):
			var p := arg.get_slice("=", 1).split("x")
			_size = Vector2i(int(p[0]), int(p[1]))
		elif arg.begins_with("--attrib="):
			_attrib = arg.get_slice("=", 1)
		elif arg == "--walk":
			_walk = true
		elif arg == "--vsync":
			_vsync = true
	print("[perf] userdir=", OS.get_user_data_dir())
	change_scene_to_file.call_deferred("res://tools/playtest/playtest_runner.tscn")
	_run.call_deferred()


func _run() -> void:
	await _frames(90)
	if not _vsync:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		Engine.max_fps = 0
	_apply_size()
	await _frames(60)
	_apply_size()
	await _frames(30)
	var rids := _viewport_rids()
	for k: String in rids:
		RenderingServer.viewport_set_measure_render_time(rids[k], true)
	_results["setup"] = {
		"window": [root.size.x, root.size.y],
		"screen": [DisplayServer.screen_get_size().x, DisplayServer.screen_get_size().y],
		"visible_rect": [root.get_visible_rect().size.x, root.get_visible_rect().size.y],
		"canvas_scale": root.get_final_transform().x.x,
		"adapter": RenderingServer.get_video_adapter_name(),
		"cpu": OS.get_processor_name(),
		"cores": OS.get_processor_count(),
		"driver": RenderingServer.get_current_rendering_driver_name(),
		"debug": OS.is_debug_build(),
		"vsync": DisplayServer.window_get_vsync_mode(),
		"subviewports": rids.keys(),
	}
	print("[perf] setup ", JSON.stringify(_results["setup"]))
	var game := _game()
	if game != null and game.has_signal("room_changed"):
		game.connect("room_changed", _on_room_changed)
	_results["rooms"] = {}
	for visit: Array in VISITS:
		await _visit(String(visit[0]), visit[1] as Vector2)
	_results["revisits"] = {}
	for visit: Array in [VISITS[0], VISITS[5]]:
		var p := _player()
		_room_events.clear()
		var t := Time.get_ticks_usec()
		p.call("teleport", visit[1] as Vector2)
		var a := await _sample(ARRIVE_S, t)
		a["room_events"] = _room_events.duplicate()
		_results["revisits"][String(visit[0])] = a
		print("[perf] revisit %s max %.1f over33 %d" % [visit[0], a.dt.max, a.over_33])
		await _secs(SETTLE_S)
	if _walk:
		await _walk_test()
	await _contents_cost()
	_results["elapsed_s"] = (Time.get_ticks_msec() - _t0) / 1000.0
	if _perf_out != "":
		DirAccess.make_dir_recursive_absolute(_perf_out.get_base_dir())
		var f := FileAccess.open(_perf_out, FileAccess.WRITE)
		f.store_string(JSON.stringify(_results, "\t"))
		f.close()
	print("[perf] done ", _perf_out)
	quit()


func _apply_size() -> void:
	var screen := DisplayServer.screen_get_size()
	var win := root
	if _size.x >= screen.x or _size.y >= screen.y - 80:
		win.borderless = true
		win.position = DisplayServer.screen_get_position()
	win.size = _size
	if not win.borderless:
		win.move_to_center()


func _visit(id: String, at: Vector2) -> void:
	var entry: Dictionary = {}
	_room_events.clear()
	var player := _player()
	if player == null:
		print("[perf] no player")
		return
	var t_tele := Time.get_ticks_usec()
	player.call("teleport", at)
	entry["arrival"] = await _sample(ARRIVE_S, t_tele)
	entry["arrival"]["room_events"] = _room_events.duplicate()
	await _secs(SETTLE_S)
	entry["where"] = _where()
	entry["base"] = await _sample(MEASURE_S)
	print("[perf] %s base %s" % [id, _brief(entry["base"])])
	if id == "village_mill":
		entry["levels"] = {}
		var field := _node("World/MemoryField")
		var authored: float = field.get("baseline")
		for level: float in VILLAGE_LEVELS:
			field.set("baseline", level)
			await _secs(1.5)
			entry["levels"][str(level)] = await _sample(MEASURE_S)
			print("[perf] %s memory %.1f %s" % [id, level, _brief(entry["levels"][str(level)])])
		field.set("baseline", authored)
		await _secs(1.5)
	if _attrib == "all" or id in _attrib.split(","):
		entry["toggles"] = {}
		for name: String in _toggle_names():
			var saved: Dictionary = _toggle(name, true, {})
			await _secs(TOGGLE_SETTLE_S)
			var s := await _sample(TOGGLE_S)
			s["changed"] = saved.get("count", 0)
			entry["toggles"][name] = s
			_toggle(name, false, saved)
			await _secs(TOGGLE_SETTLE_S)
			print("[perf] %s off:%s %s" % [id, name, _brief(s)])
		entry["base_after"] = await _sample(TOGGLE_S)
		print("[perf] %s base_after %s" % [id, _brief(entry["base_after"])])
	_results["rooms"][id] = entry


func _walk_test() -> void:
	var player := _player()
	player.call("teleport", WALK_START)
	await _secs(ARRIVE_S + SETTLE_S)
	_room_events.clear()
	var ev := InputEventAction.new()
	ev.action = &"move_right"
	ev.pressed = true
	Input.parse_input_event(ev)
	var s := await _sample(WALK_S, Time.get_ticks_usec(), true)
	var up := InputEventAction.new()
	up.action = &"move_right"
	up.pressed = false
	Input.parse_input_event(up)
	s["room_events"] = _room_events.duplicate()
	s["end_x"] = _player().global_position.x
	_results["walk"] = s
	print("[perf] walk %s events=%s" % [_brief(s), JSON.stringify(_room_events)])


## Instantiates each visited room's contents again, hidden and out of the world, and times instantiate and enter-tree (_ready).
func _contents_cost() -> void:
	var out := {}
	var holder := Node2D.new()
	holder.visible = false
	holder.process_mode = Node.PROCESS_MODE_DISABLED
	root.add_child(holder)
	for visit: Array in VISITS:
		for r: Node in get_nodes_in_group(&"room"):
			if String(r.call("id")) != String(visit[0]):
				continue
			var packed: PackedScene = r.get("contents_scene")
			var t0 := Time.get_ticks_usec()
			var inst := packed.instantiate()
			var t1 := Time.get_ticks_usec()
			holder.add_child(inst)
			var t2 := Time.get_ticks_usec()
			out[String(visit[0])] = {"instantiate_ms": (t1 - t0) / 1000.0, "enter_tree_ready_ms": (t2 - t1) / 1000.0,
				"nodes": _all(inst).size()}
			holder.remove_child(inst)
			inst.free()
			await _frames(5)
	holder.queue_free()
	_results["contents_cost"] = out
	print("[perf] contents_cost ", JSON.stringify(out))


func _on_room_changed(room: Node) -> void:
	_room_events.append({"room": String(room.call("id")), "t_ms": Time.get_ticks_msec() - _t0, "frame": Engine.get_process_frames()})


## Per-frame samples over `seconds`; `keep_frames` stores every frame's dt and the frame number.
func _sample(seconds: float, from_usec: int = -1, keep_frames: bool = false) -> Dictionary:
	var rids := _viewport_rids()
	var dt: Array[float] = []
	var proc: Array[float] = []
	var phys: Array[float] = []
	var gpu: Array[float] = []
	var gpu_root: Array[float] = []
	var gpu_sub: Dictionary = {}
	var rcpu: Array[float] = []
	var setup: Array[float] = []
	var draws: Array[float] = []
	var objs: Array[float] = []
	var prims: Array[float] = []
	var frames: Array = []
	for k: String in rids:
		gpu_sub[k] = [] as Array[float]
	var start := Time.get_ticks_usec() if from_usec < 0 else from_usec
	var last := Time.get_ticks_usec()
	while Time.get_ticks_usec() - start < int(seconds * 1e6):
		await process_frame
		var now := Time.get_ticks_usec()
		var d := (now - last) / 1000.0
		last = now
		dt.append(d)
		proc.append(Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0)
		phys.append(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0)
		var g := 0.0
		var c := 0.0
		for k: String in rids:
			var gv := RenderingServer.viewport_get_measured_render_time_gpu(rids[k])
			(gpu_sub[k] as Array[float]).append(gv)
			g += gv
			c += RenderingServer.viewport_get_measured_render_time_cpu(rids[k])
		gpu.append(g)
		gpu_root.append(RenderingServer.viewport_get_measured_render_time_gpu(rids["root"]))
		rcpu.append(c)
		setup.append(RenderingServer.get_frame_setup_time_cpu())
		draws.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		objs.append(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME))
		prims.append(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
		if keep_frames:
			frames.append([Engine.get_process_frames(), snappedf(d, 0.01), int(_player().global_position.x) if _player() else 0])
	var out := {
		"frames": dt.size(),
		"dt": _stats(dt),
		"over_33": dt.filter(func(x: float) -> bool: return x > 33.3).size(),
		"over_16": dt.filter(func(x: float) -> bool: return x > 16.7).size(),
		"cpu_process": _stats(proc),
		"cpu_physics": _stats(phys),
		"render_cpu": _stats(rcpu),
		"frame_setup_cpu": _stats(setup),
		"gpu_total": _stats(gpu),
		"gpu_root": _stats(gpu_root),
		"draw_calls": _stats(draws),
		"objects": _stats(objs),
		"primitives": _stats(prims),
		"video_mem_mb": Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0,
		"texture_mem_mb": Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1048576.0,
		"nodes": Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
		"rooms_active": _rooms(true),
		"rooms_loaded": _rooms(false),
		"static_mem_mb": Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0,
	}
	var sub := {}
	for k: String in gpu_sub:
		sub[k] = _stats(gpu_sub[k])["mean"]
	out["gpu_by_viewport_mean"] = sub
	var worst := 0
	for i: int in dt.size():
		if dt[i] > dt[worst]:
			worst = i
	out["worst_frame_index"] = worst
	out["worst_frame_ms_from_start"] = snappedf(_sum(dt.slice(0, worst + 1)), 0.1)
	if keep_frames:
		out["per_frame"] = frames
	return out


func _stats(a: Array[float]) -> Dictionary:
	if a.is_empty():
		return {"mean": 0.0, "p50": 0.0, "p95": 0.0, "p99": 0.0, "max": 0.0}
	var s := a.duplicate()
	s.sort()
	return {
		"mean": snappedf(_sum(a) / a.size(), 0.001),
		"p50": snappedf(s[int(s.size() * 0.5)], 0.001),
		"p95": snappedf(s[mini(s.size() - 1, int(s.size() * 0.95))], 0.001),
		"p99": snappedf(s[mini(s.size() - 1, int(s.size() * 0.99))], 0.001),
		"max": snappedf(s[s.size() - 1], 0.001),
	}


func _sum(a: Array) -> float:
	var t := 0.0
	for x: float in a:
		t += x
	return t


func _brief(s: Dictionary) -> String:
	return "dt=%.2f/p99 %.2f/max %.2f gpu=%.3f root=%.3f proc=%.2f phys=%.2f rcpu=%.2f draws=%d objs=%d nodes=%d rooms=%d/%d sub=%s" % [
		s.dt.mean, s.dt.p99, s.dt.max, s.gpu_total.mean, s.gpu_root.mean, s.cpu_process.mean, s.cpu_physics.mean,
		s.render_cpu.mean, s.draw_calls.mean, s.objects.mean, s.nodes, s.rooms_active, s.rooms_loaded, JSON.stringify(s.gpu_by_viewport_mean)]


func _toggle_names() -> Array[String]:
	return ["greyhush", "season_mask", "creature_pass", "foreground_pass", "dissonance_copy", "all_fullscreen",
		"backdrops", "grass", "water", "particles", "region_weather", "ambient_motion", "neighbours", "world_hidden"]


## Turns candidate `name` off (`off` true, returns what to restore) or back on from `saved`.
func _toggle(name: String, off: bool, saved: Dictionary) -> Dictionary:
	var out := {"count": 0}
	match name:
		"greyhush":
			_vis(_node("CanvasLayer/Greyhush"), off, out)
		"season_mask":
			var sm := _node("SeasonMask") as SubViewport
			sm.render_target_update_mode = SubViewport.UPDATE_DISABLED if off else SubViewport.UPDATE_ALWAYS
			out.count = 1
		"creature_pass":
			_pass(_node("CreatureMask") as SubViewport, 2, _node("CanvasLayer/Creatures"), off)
			out.count = 1
		"foreground_pass":
			_pass(_node("ForegroundPass") as SubViewport, 4, _node("CanvasLayer/Foreground"), off)
			out.count = 1
		"dissonance_copy":
			_vis(_node("CanvasLayer/DissonanceCopy"), off, out)
		"all_fullscreen":
			for n: String in ["greyhush", "season_mask", "creature_pass", "foreground_pass", "dissonance_copy"]:
				_toggle(n, off, {})
			out.count = 5
		"backdrops":
			for c: Node in _contents():
				_vis(c.get_node_or_null("Backdrop"), off, out)
		"grass":
			for c: Node in _contents():
				_vis(c.get_node_or_null("RoomMap/Grass"), off, out)
		"water":
			for c: Node in _contents():
				var map := c.get_node_or_null("RoomMap")
				if map != null:
					for w: Node in map.get_children():
						if String(w.name).begins_with("Water"):
							_vis(w, off, out)
		"particles":
			var game := _game()
			for p: Node in game.find_children("*", "CPUParticles2D", true, false):
				_vis(p, off, out)
			for p: Node in game.find_children("*", "GPUParticles2D", true, false):
				_vis(p, off, out)
		"region_weather":
			var rw := _node("World/RegionWeather")
			_vis(rw, off, out)
			rw.process_mode = Node.PROCESS_MODE_DISABLED if off else Node.PROCESS_MODE_ALWAYS
		"ambient_motion":
			for n: Node in _all(_node("World")):
				if n is AmbientMotion:
					n.set_physics_process(not off)
					out.count += 1
		"neighbours":
			var here := _current_room()
			if off:
				var keep: Array = []
				for r: Node in get_nodes_in_group(&"room"):
					if r != here and r.call("is_active"):
						r.call("deactivate")
						keep.append(r)
				out["rooms"] = keep
				out.count = keep.size()
			else:
				for r: Node in saved.get("rooms", []):
					if is_instance_valid(r):
						r.call("activate")
		"world_hidden":
			_vis(_node("World"), off, out)
	return out


func _vis(n: Node, off: bool, out: Dictionary) -> void:
	if n is CanvasItem:
		(n as CanvasItem).visible = not off
		out.count += 1


func _pass(vp: SubViewport, bit: int, composite: Node, off: bool) -> void:
	vp.render_target_update_mode = SubViewport.UPDATE_DISABLED if off else SubViewport.UPDATE_ALWAYS
	if off:
		root.canvas_cull_mask |= bit
	else:
		root.canvas_cull_mask &= ~bit
	(composite as CanvasItem).visible = not off


func _all(n: Node) -> Array[Node]:
	var out: Array[Node] = [n]
	for c: Node in n.get_children():
		out.append_array(_all(c))
	return out


func _contents() -> Array[Node]:
	var out: Array[Node] = []
	for r: Node in get_nodes_in_group(&"room"):
		var c: Node = r.call("contents")
		if c != null and r.call("is_active"):
			out.append(c)
	return out


func _rooms(active_only: bool) -> int:
	var n := 0
	for r: Node in get_nodes_in_group(&"room"):
		if active_only and r.call("is_active"):
			n += 1
		elif not active_only and r.call("contents") != null:
			n += 1
	return n


func _current_room() -> Node:
	var p := _player()
	for r: Node in get_nodes_in_group(&"room"):
		if (r.call("get_bounds") as Rect2).has_point(p.global_position + Vector2(0, -8)):
			return r
	return null


func _where() -> Dictionary:
	var r := _current_room()
	var p := _player()
	return {"room": String(r.call("id")) if r != null else "", "pos": [p.global_position.x, p.global_position.y],
		"baseline": _node("World/MemoryField").get("baseline")}


func _viewport_rids() -> Dictionary:
	var out := {"root": root.get_viewport_rid()}
	for k: String in ["CreatureMask", "ForegroundPass", "SeasonMask"]:
		var vp := _node(k) as Viewport
		if vp != null:
			out[k] = vp.get_viewport_rid()
	return out


func _game() -> Node:
	var runner := root.get_node_or_null("PlaytestRunner")
	return runner.get_node_or_null("Game") if runner != null else null


func _node(path: String) -> Node:
	var g := _game()
	return g.get_node_or_null(path) if g != null else null


func _player() -> Node2D:
	return get_first_node_in_group(&"player") as Node2D


func _frames(n: int) -> void:
	for i: int in n:
		await process_frame


func _secs(s: float) -> void:
	var start := Time.get_ticks_msec()
	while Time.get_ticks_msec() - start < int(s * 1000):
		await process_frame
