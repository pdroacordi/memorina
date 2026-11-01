extends SceneTree
## Closed-loop guardian fight bot (GRD-07 playtest). Loads the playtest runner (its timeline only sets up) and plays the fight:
## approach and combo in PRESSURE, the recall's own action while it is armed, draw and answer on call_window_opened.
## Prints [bot] (phase, move, hitbox, hp, signals), [spr] (guardian texture/frame/flip) and [shot] (guardian and Ivo
## screen position per event screenshot) lines; screenshots go to --out.
## Run: "$GODOT_WINDOWED" --path . -s res://tools/playtest/scripts/guardian_fight_bot_driver.gd -- --script=<timeline> --out=<dir>
## Env: BOT_GOD=1 tops Ivo up at hp 1; BOT_KEEP=<px> preferred distance (62); BOT_PASSIVE=1 never attacks;
## BOT_ANSWER=0 never answers; BOT_RECALL_WAIT=1 waits for the launch before a jump recall's presses;
## BOT_POKE=1 steps out of ordinary moves and rolls under lunges/leaps; BOT_BOUNCE=1 double-jumps over the guardian and pogoes;
## BOT_RESTORED_MS=<ms> how long the restored burst captures (1800; the mentor's restoration scene wants ~22000);
## BOT_MAX_SHOTS=<n> the screenshot cap (160).
## No autoload or class_name is referenced: a -s script compiles before the autoloads exist.
const PH := ["DORMANT", "PRESSURE", "LUCIDITY", "RELAPSE", "RESTORED"]
var _out := ""
var _p: Node2D
var _g: Node2D
var _queue: Array = []
var _hooked := false
var _last := ""
var _next_attack := 0
var _next_jump := 0
var _notes: Array = []
var _shots := 0
var _burst_until := 0
var _burst_next := 0
var _burst_tag := ""
var _seen: Dictionary = {}
var _prev_phase := -1
var _prev_atk := ""
var _prev_hb := false
var _prev_hp := -1
var _moving := ""
var _pogo_ok := false
var _tel_at := 0
var _rolled := false
var _prev_spr := ""
var _keep := 62.0
var _god := false
var _passive := false
var _answer := true
var _call_active := false
var _t0 := 0

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			_out = a.substr(6)
	_keep = float(OS.get_environment("BOT_KEEP")) if OS.get_environment("BOT_KEEP") != "" else 62.0
	_god = OS.get_environment("BOT_GOD") == "1"
	_passive = OS.get_environment("BOT_PASSIVE") == "1"
	_answer = OS.get_environment("BOT_ANSWER") != "0"
	change_scene_to_file.call_deferred("res://tools/playtest/playtest_runner.tscn")

func _now() -> int:
	return Time.get_ticks_msec()

func _el() -> float:
	return float(current_scene.get("_elapsed")) if current_scene else 0.0

func _act(action: String, pressed: bool) -> void:
	var e := InputEventAction.new()
	e.action = action
	e.pressed = pressed
	e.strength = 1.0 if pressed else 0.0
	Input.parse_input_event(e)

func _press(action: String, ms: int, delay: int = 0) -> void:
	_queue.append([_now() + delay, action, true])
	_queue.append([_now() + delay + ms, action, false])

func _move(dir: String) -> void:
	if dir == _moving:
		return
	if _moving != "":
		_act(_moving, false)
	_moving = dir
	if dir != "":
		_act(dir, true)

func _shot(tag: String) -> void:
	if _out == "" or _shots > (int(OS.get_environment("BOT_MAX_SHOTS")) if OS.get_environment("BOT_MAX_SHOTS") != "" else 160):
		return
	_shots += 1
	var img := root.get_viewport().get_texture().get_image()
	var name := "%03d_%06.2f_%s.png" % [_shots, _el(), tag]
	img.save_png(_out.path_join(name))
	var gs := _g.get_global_transform_with_canvas().origin if _g else Vector2.ZERO
	var ps := _p.get_global_transform_with_canvas().origin if _p else Vector2.ZERO
	print("[shot] %s g=(%.1f,%.1f) p=(%.1f,%.1f)" % [name, gs.x, gs.y, ps.x, ps.y])

func _burst(tag: String, ms: int) -> void:
	_burst_tag = tag
	_burst_until = _now() + ms
	_burst_next = 0

func _process(_d: float) -> bool:
	if current_scene == null:
		return false
	var now := _now()
	for q in _queue.duplicate():
		if q[0] <= now:
			_act(q[1], q[2])
			_queue.erase(q)
	if _burst_until > now and now >= _burst_next:
		_burst_next = now + (250 if _burst_tag == "lucid" else 700 if _burst_tag == "restored" and _burst_until - now > 3000 else 120)
		_shot(_burst_tag)
	_p = root.find_child("Player", true, false) as Node2D
	if _p == null or not _p.has_method("is_in_lesson"):
		return false
	if _g == null or not is_instance_valid(_g):
		_g = _find(root)
		if _g == null:
			return false
	if not _hooked:
		_hooked = true
		_t0 = now
		_notes = _g.get("stats").song.notes
		_p.connect("call_window_opened", _on_window)
		# The final battle calls a new phrase after each one answered (GRD-06): answer the phrase the call shows.
		_p.connect("call_opened", func(song: Resource, _r: int, _gs: int, _cd: int, _ct: int, _sd: int, _h: float) -> void: _notes = song.notes)
		for sig in ["call_opened", "call_closed", "call_answered", "skill_recalled", "skill_recall_missed", "recall_started", "recall_step_taken", "recall_ended", "lesson_started", "sequence_failed", "double_jumped", "jumped", "call_staged", "call_unstaged"]:
			var argc: int = _p.get_signal_list().filter(func(x: Dictionary) -> bool: return x.name == sig)[0].args.size()
			var cb: Callable = _on_sig.bind(sig)
			_p.connect(sig, cb.unbind(argc) if argc > 0 else cb)
	var h: Node = _p.get_node("Health")
	var hp: int = h.get("current_hp")
	if _god and hp <= 1 and hp > 0:
		h.set("current_hp", 3)
	_observe(hp)
	_policy(now)
	return false

func _observe(hp: int) -> void:
	var ph: int = _g.phase()
	var a: Resource = _g.current_attack()
	var an := a.resource_path.get_file().get_basename() if a else ""
	var hba: Area2D = _g.get_node("Hitbox")
	var hbs: CollisionShape2D = _g.get_node("Hitbox/CollisionShape2D")
	var hb := hba.monitoring and not hbs.disabled
	var spr: Sprite2D = _g.get_node("Sprite2D")
	var dx := _g.global_position.x - _p.global_position.x
	if ph != _prev_phase:
		_log("PHASE %s -> %s" % [PH[_prev_phase] if _prev_phase >= 0 else "-", PH[ph]])
		if ph == 2:
			_burst("lucid", 7600)
		elif ph == 4:
			_burst("restored", int(OS.get_environment("BOT_RESTORED_MS")) if OS.get_environment("BOT_RESTORED_MS") != "" else 1800)
		elif ph == 3:
			_burst("relapse", 600)
		_prev_phase = ph
	var tel: bool = _g.is_telegraphing()
	var key := an + ("T" if tel else ("S" if an != "" else ""))
	if key != _prev_atk:
		if tel:
			_tel_at = _now()
		_log("ATK %s dx=%.1f" % [key, dx])
		var n: int = _seen.get(key, 0)
		_seen[key] = n + 1
		if an != "" and n < 3:
			_shot("%s_%s" % [an, "tel" if tel else "swing"])
		_prev_atk = key
	if hb != _prev_hb:
		_log("HB %s %s dx=%.1f box=(%d,%d)" % ["open" if hb else "shut", an, dx, hbs.position.x, hbs.position.y])
		var k := "hb_" + an
		var n2: int = _seen.get(k, 0)
		_seen[k] = n2 + 1
		if hb and n2 < 3:
			_burst("hit_" + an, 360)
		_prev_hb = hb
	var sk := "%s fr=%d flip=%s" % [spr.texture.resource_path.get_file().get_basename().replace("_guardian", "") if spr.texture else "-", spr.frame, spr.flip_h]
	if sk != _prev_spr:
		_prev_spr = sk
		if sk.find("hurt fr=0") >= 0 and int(_seen.get("ghurt", 0)) < 3:
			_seen["ghurt"] = int(_seen.get("ghurt", 0)) + 1
			_burst("ghurt", 450)
		print("[spr] t=%.3f %s gpos=(%.1f,%.1f) spr=(%.0f,%.0f) mod=%s dx=%.1f" % [_el(), sk, _g.global_position.x, _g.global_position.y, spr.position.x, spr.position.y, spr.modulate, dx])
	if hp != _prev_hp:
		_log("HP %d -> %d dx=%.1f atk=%s hb=%s" % [_prev_hp, hp, dx, an, hb])
		if _prev_hp > hp:
			_shot("hurt")
		_prev_hp = hp

func _policy(now: int) -> void:
	var rc: Node = _p.get_node("AbilityRecall")
	if rc.is_armed():
		_move("")
		if String(rc.armed_stats().action) == "jump" and OS.get_environment("BOT_RECALL_WAIT") == "1" and _p.is_on_floor() and rc.steps_left() < 2:
			return
		if String(rc.armed_stats().action) == "jump" and OS.get_environment("BOT_RECALL_WAIT") == "1" and _p.is_on_floor() and rc.steps_left() >= 2 and not _launched_wait_over():
			return
		if now >= _next_jump:
			_next_jump = now + 280
			_log("JUMP press (armed steps=%d floor=%s ts=%.2f)" % [rc.steps_left(), _p.is_on_floor(), Engine.time_scale])
			_press(String(rc.armed_stats().action), 120)
		return
	var ph: int = _g.phase()
	if ph != 1 or _call_active or _p.is_in_lesson():
		_move("")
		return
	var dx := _g.global_position.x - _p.global_position.x
	var ad := absf(dx)
	var toward := "move_right" if dx > 0 else "move_left"
	var away := "move_left" if dx > 0 else "move_right"
	if OS.get_environment("BOT_BOUNCE") == "1":
		var fy: float = _g.global_position.y
		var up: float = fy - _p.global_position.y
		if ad > 8.0:
			_move(toward)
		else:
			_move("")
		if _p.is_on_floor() and now >= _next_jump:
			_next_jump = now + 900
			_press("jump", 300)
			_press("jump", 350, 420)
			_pogo_ok = true
		elif not _p.is_on_floor() and _p.get("velocity").y > 0.0 and up > 150.0 and _pogo_ok and now >= _next_attack:
			_next_attack = now + 400
			_pogo_ok = false
			_act("look_down", true)
			_press("attack", 60)
			_queue.append([now + 300, "look_down", false])
			_log("POGO press up=%.0f" % up)
		if not _p.is_on_floor() and _p.get("velocity").y < 0.0:
			_pogo_ok = true
		return
	if OS.get_environment("BOT_POKE") == "1":
		var ca2: Resource = _g.current_attack()
		if ca2 != null and ca2.get("recall") == null:
			var an2 := ca2.resource_path.get_file()
			if ca2.get("leap_impulse") > 0.0 or ca2.get("lunge_speed") > 0.0:
				if _g.is_telegraphing() and now - _tel_at > int(ca2.get("telegraph") * 1000.0) - 150 and not _rolled:
					_rolled = true
					_move(toward)
					_press("roll", 60)
					_log("POKE roll under " + an2)
				elif not _rolled:
					_move("")
				return
			_move(away)
			return
		_rolled = false
	if ad > _keep + 6:
		_move(toward)
	else:
		_move("")
		var ca: Resource = _g.current_attack()
		var recall_move: bool = ca != null and ca.get("recall") != null
		if not _passive and not recall_move and ad < 80 and now >= _next_attack and _p.is_on_floor():
			# face the guardian first if looking away
			_next_attack = now + 330
			_press("attack", 60)

func _on_sig(sig: String) -> void:
	_log("SIG " + sig)
	match sig:
		"call_opened": _call_active = true
		"call_closed": _call_active = false
		"call_answered": _burst("answered", 1500)
		"skill_recalled": _burst("recalled", 900)
		"recall_started": _shot("recall_start")
		"lesson_started": _burst("lesson", 400)
		"call_staged": _shot("staged")
		"call_unstaged": _burst("unstaged", 2500)

var _armed_at := 0
func _launched_wait_over() -> bool:
	return false

func _on_window() -> void:
	_log("SIG call_window_opened")
	_shot("window")
	if not _answer:
		return
	_press("draw_memorina", 80, 0)
	var acts := ["note_up", "note_down", "note_left", "note_right"]
	var d := 700
	for n in _notes:
		_press(acts[n], 80, d)
		d += 450

func _log(s: String) -> void:
	var hp := -1
	if _p:
		hp = _p.get_node("Health").get("current_hp")
	print("[bot] t=%.3f %s | ivo=(%.1f,%.1f) floor=%s hp=%d hits=%.2f" % [_el(), s, _p.global_position.x if _p else 0.0, _p.global_position.y if _p else 0.0, _p.is_on_floor() if _p else false, hp, _g.pressure_progress() if _g else -1.0])

func _find(n: Node) -> Node2D:
	if n.has_method("current_attack") and n.has_method("pressure_progress") and (n as Node2D).is_visible_in_tree():
		return n
	for c in n.get_children():
		var r := _find(c)
		if r:
			return r
	return null
