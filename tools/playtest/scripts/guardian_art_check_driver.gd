extends SceneTree
## GRD-18 art check: forces each move in AC_MOVES (comma list of .tres basenames in AC_DIR) AC_REPS times against a
## still, god-mode Ivo. Prints [st] on every change of clock phase / clip / frame / hitbox / airborne (with phase time in
## physics frames), [hit] and [shot]. A shot is taken on the frame after each change (the viewport
## texture lags one frame) and every frame while the guardian is airborne. It sets max_physics_steps_per_frame to 1, so
## every physics state is drawn (the run is slow in real time). AC_IVO_X=<world x> teleports Ivo there before each throw.
## Run: AC_DIR=summer_guardian AC_MOVES=summer_claw,summer_pounce_slam AC_REPS=1 "$GODOT" --path . -s <this> --
## --script=<timeline> --out=<dir>  (playtests/2026-11-20-grd18-leaf-sun-mentor-art). No autoload or class_name is named.
var _out := ""
var _dir := ""
var _moves: Array = []
var _reps := 2
var _idx := 0
var _done := 0
var _p: Node2D
var _g: Node2D
var _ai: Node
var _prev := ""
var _phase_key := ""
var _phase_f0 := 0
var _shots := 0
var _max_shots := 900
var _pending := 0
var _prev_hp := -1
var _was_busy := false
var _cur_forced := ""
var _ivo_x := NAN
var _air_shot_f := -1

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			_out = a.substr(6)
	_dir = OS.get_environment("AC_DIR")
	for m in OS.get_environment("AC_MOVES").split(",", false):
		_moves.append(m)
	if OS.get_environment("AC_REPS") != "":
		_reps = int(OS.get_environment("AC_REPS"))
	if OS.get_environment("AC_IVO_X") != "":
		_ivo_x = float(OS.get_environment("AC_IVO_X"))
	# One physics step per drawn frame: every physics state is rendered and shot, at the cost of real-time speed.
	Engine.max_physics_steps_per_frame = 1
	change_scene_to_file.call_deferred("res://tools/playtest/playtest_runner.tscn")

func _el() -> float:
	return float(current_scene.get("_elapsed")) if current_scene else 0.0

func _find(n: Node) -> Node2D:
	if n.has_method("current_attack") and n.has_method("pressure_progress") and (n as Node2D).is_visible_in_tree():
		return n
	for c in n.get_children():
		var r := _find(c)
		if r:
			return r
	return null

func _clock() -> String:
	if _g.is_telegraphing():
		return "T"
	if _g.is_swinging():
		return "S"
	if _g.is_recovering():
		return "R"
	return "-"

func _rect_s(cs: CollisionShape2D) -> String:
	if cs == null or cs.shape == null:
		return "none"
	var r: Rect2 = cs.shape.get_rect()
	var xf: Transform2D = cs.get_global_transform_with_canvas()
	var a: Vector2 = xf * r.position
	var b: Vector2 = xf * (r.position + r.size)
	return "%.1f,%.1f,%.1f,%.1f" % [minf(a.x, b.x), minf(a.y, b.y), maxf(a.x, b.x), maxf(a.y, b.y)]

func _shot(tag: String) -> void:
	if _out == "" or _shots >= _max_shots:
		return
	_shots += 1
	var img := root.get_viewport().get_texture().get_image()
	var name := "%04d_%07.3f_%s.png" % [_shots, _el(), tag]
	img.save_png(_out.path_join(name))
	var gs := _g.get_global_transform_with_canvas().origin
	var ps := _p.get_global_transform_with_canvas().origin
	var hb: CollisionShape2D = _g.get_node("Hitbox/CollisionShape2D")
	var hba: Area2D = _g.get_node("Hitbox")
	var live := hba.monitoring and not hb.disabled
	var hurt: CollisionShape2D = _p.get_node("Hurtbox").get_child(0) as CollisionShape2D
	print("[shot] %s g=(%.1f,%.1f) p=(%.1f,%.1f) hb=%s live=%s hurt=%s st=%s" % [name, gs.x, gs.y, ps.x, ps.y, _rect_s(hb), live, _rect_s(hurt), _prev])

func _process(_d: float) -> bool:
	if current_scene == null:
		return false
	if _pending > 0:
		_pending -= 1
		if _pending == 0 and _g != null:
			_shot("c")
	_p = root.find_child("Player", true, false) as Node2D
	if _p == null or not _p.has_method("is_in_lesson"):
		return false
	if _g == null or not is_instance_valid(_g):
		_g = _find(root)
		if _g == null:
			return false
		_ai = _g.get_node("AI")
		_p.get_node("Hurtbox").connect("hit_received", func(_a = null, _b = null, _c = null) -> void:
			print("[hit] t=%.3f st=%s" % [_el(), _prev]))
	var h: Node = _p.get_node("Health")
	if int(h.get("current_hp")) <= 1:
		h.set("current_hp", 3)
	_ai.set("comfort_distance", 0.0)
	_ai.set("recall_after_attacks", 0)
	var ph: int = _g.phase()
	var busy: bool = _ai.is_attacking()
	if _was_busy and not busy and _cur_forced != "":
		_done += 1
		print("[done] %s rep %d" % [_cur_forced, _done])
		_cur_forced = ""
		if _done >= _reps:
			_done = 0
			_idx += 1
			if _idx >= _moves.size():
				print("[end] all moves thrown")
				quit()
				return false
	_was_busy = busy
	if ph == 1 and not busy and _idx < _moves.size():
		if not is_nan(_ivo_x) and absf(_p.global_position.x - _ivo_x) > 4.0 and _p.is_on_floor():
			_p.call("teleport", Vector2(_ivo_x, _p.global_position.y))
		var res: Resource = load("res://resources/characters/guardians/%s/%s.tres" % [_dir, _moves[_idx]])
		_ai.set("_next", res)
	var a: Resource = _g.current_attack()
	var an: String = a.resource_path.get_file().get_basename() if a else ""
	if busy and an == _moves[mini(_idx, _moves.size() - 1)]:
		_cur_forced = an
	var spr: Sprite2D = _g.get_node("Sprite2D")
	var tex := spr.texture.resource_path.get_file().get_basename() if spr.texture else "?"
	var hba: Area2D = _g.get_node("Hitbox")
	var hbs: CollisionShape2D = _g.get_node("Hitbox/CollisionShape2D")
	var live := hba.monitoring and not hbs.disabled
	var air := not (_g as CharacterBody2D).is_on_floor() if _g is CharacterBody2D else false
	var mir := spr.get_global_transform().determinant() < 0
	var key := "%s|%s|ph%d" % [_clock(), an, ph]
	var pf := Engine.get_physics_frames()
	if key != _phase_key:
		_phase_key = key
		_phase_f0 = pf
	var st := "%s %s fr%d vis=%s hb=%s air=%s mir=%s" % [key, tex, spr.frame, spr.is_visible_in_tree(), live, air, mir]
	var y := _g.global_position.y
	if st != _prev or (air and pf != _air_shot_f):
		var changed := st != _prev
		_prev = st
		var tph := float(pf - _phase_f0) / 60.0
		print("[st] t=%.3f pf=%d tph=%.3f %s g=(%.1f,%.1f) ivo=(%.1f,%.1f) dx=%.1f" % [_el(), pf, tph, st, _g.global_position.x, y, _p.global_position.x, _p.global_position.y, _g.global_position.x - _p.global_position.x])
		if air:
			_air_shot_f = pf
		if busy or changed:
			if busy:
				_pending = 1
	var hp: int = h.get("current_hp")
	_prev_hp = hp
	return false
