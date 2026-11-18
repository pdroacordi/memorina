extends SceneTree
## Guardian fight driver that dodges like a player (GRD-13 playtest). Loads the playtest runner (its timeline only sets
## up). Swings in the guardian's idle and recovery, backs off from close strings, jumps floor runners and dashes, steps
## between lobbed pods' landing spots, presses the recall's action while armed, answers the call on call_window_opened.
## Prints [st] (phase, stage, move, clock phase T/S/R, link, hitbox, live spawns) on every change, [hit] (what hurt Ivo),
## [sp] (each spawn's birth and landing x), [spr] (guardian clip frame) and [shot] lines; screenshots go to --out.
## Run: "$GODOT" --path . -s res://tools/playtest/scripts/guardian_fight_player_driver.gd -- --script=<timeline> --out=<dir>
## Env: PL_GOD=1 tops Ivo up at hp 1; PL_PASSIVE=1 stands still and never attacks (answers still);
## PL_POUNCE=away|jump|under how the pounce is dodged (away); PL_POGO=1 pogoes in punish windows instead of swinging;
## PL_LASH=back|stay|two (stay swings through the string, two swings through the lash and backs off from the back-lash on); PL_ROW_LEAD=<s> (0.12); PL_DASH_AT=<strike s> (0.33);
## PL_SWINGS=<n> swings per approach (2); PL_MAX_SHOTS=<n> (260); PL_ANSWER=0 never answers.
## No autoload or class_name is referenced: a -s script compiles before the autoloads exist.
const PH := ["DORMANT", "PRESSURE", "LUCIDITY", "RELAPSE", "RESTORED"]
const LASH_STRING := ["bloom_lash", "bloom_back_lash", "bloom_antler_thrust"]
var _out := ""
var _p: Node2D
var _g: Node2D
var _queue: Array = []
var _hooked := false
var _shots := 0
var _max_shots := 260
var _burst_until := 0
var _burst_next := 0
var _burst_tag := ""
var _seen: Dictionary = {}
var _prev_st := ""
var _prev_hp := -1
var _prev_phase := -1
var _prev_spr := ""
var _moving := ""
var _god := false
var _passive := false
var _answer := true
var _pogo := false
var _pounce_mode := "away"
var _swings_max := 2
var _call_active := false
var _next_attack := 0
var _next_jump := 0
var _swings := 0
var _backoff_until := 0
var _notes: Array = []
var _known_spawns: Dictionary = {}
var _jumped_for: Dictionary = {}
var _last_threat := ""
var _learned := false
var _lash_mode := "back"
var _row_lead := 0.12
var _dash_at := 0.33
var _restored_at := 0

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			_out = a.substr(6)
	_god = OS.get_environment("PL_GOD") == "1"
	_passive = OS.get_environment("PL_PASSIVE") == "1"
	_answer = OS.get_environment("PL_ANSWER") != "0"
	_pogo = OS.get_environment("PL_POGO") == "1"
	if OS.get_environment("PL_POUNCE") != "":
		_pounce_mode = OS.get_environment("PL_POUNCE")
	if OS.get_environment("PL_SWINGS") != "":
		_swings_max = int(OS.get_environment("PL_SWINGS"))
	if OS.get_environment("PL_LASH") != "":
		_lash_mode = OS.get_environment("PL_LASH")
	if OS.get_environment("PL_DASH_AT") != "":
		_dash_at = float(OS.get_environment("PL_DASH_AT"))
	if OS.get_environment("PL_ROW_LEAD") != "":
		_row_lead = float(OS.get_environment("PL_ROW_LEAD"))
	if OS.get_environment("PL_MAX_SHOTS") != "":
		_max_shots = int(OS.get_environment("PL_MAX_SHOTS"))
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
	if _out == "" or _shots >= _max_shots:
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
		_burst_next = now + (250 if _burst_tag == "lucid" else 100)
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
		_notes = _g.get("stats").song.notes
		_p.connect("call_window_opened", _on_window)
		for sig in ["call_opened", "call_closed", "call_answered", "skill_recalled", "skill_recall_missed", "recall_started", "recall_step_taken", "recall_ended", "lesson_started", "sequence_failed", "jumped"]:
			var argc: int = _p.get_signal_list().filter(func(x: Dictionary) -> bool: return x.name == sig)[0].args.size()
			var cb: Callable = _on_sig.bind(sig)
			_p.connect(sig, cb.unbind(argc) if argc > 0 else cb)
	if _restored_at > 0 and now - _restored_at > 3000:
		quit()
		return false
	var h: Node = _p.get_node("Health")
	var hp: int = h.get("current_hp")
	if _god and hp <= 1 and hp > 0:
		h.set("current_hp", 3)
	_observe(hp)
	_policy(now)
	return false

func _spawns() -> Array:
	var sp: Node = _g.get_node_or_null("Spawner")
	if sp == null:
		return []
	return sp.get_children().filter(func(c: Node) -> bool: return c.has_method("is_live") and is_instance_valid(c) and not c.is_queued_for_deletion())

func _kind(s: Node) -> String:
	if s.has_method("run_at"):
		return "row"
	if s.has_method("launch"):
		return "pod"
	return "patch"

func _spawn_x(s: Node) -> float:
	if _kind(s) == "row":
		return s.global_position.x + float(s.get("facing")) * float(s.call("run_at", float(s.get("_t"))))
	return s.global_position.x

func _clock() -> String:
	if _g.is_telegraphing():
		return "T"
	if _g.is_swinging():
		return "S"
	if _g.has_method("is_recovering") and _g.is_recovering():
		return "R"
	return ""

func _stage() -> int:
	if _g.has_method("fight") and _g.fight() != null and _g.fight().has_method("stage"):
		return _g.fight().stage()
	return -1

func _observe(hp: int) -> void:
	var ph: int = _g.phase()
	var a: Resource = _g.current_attack()
	var an := a.resource_path.get_file().get_basename() if a else ""
	var hba: Area2D = _g.get_node("Hitbox")
	var hbs: CollisionShape2D = _g.get_node("Hitbox/CollisionShape2D")
	var hb := hba.monitoring and not hbs.disabled
	var spr: Sprite2D = _g.get_node("Sprite2D")
	var dx := _g.global_position.x - _p.global_position.x
	var sps := _spawns()
	var live := []
	for s in sps:
		var id: int = s.get_instance_id()
		if not _known_spawns.has(id):
			_known_spawns[id] = true
			print("[sp] t=%.3f BORN %s x=%.1f facing=%s ivo_x=%.1f g_x=%.1f" % [_el(), _kind(s), s.global_position.x, s.get("facing"), _p.global_position.x, _g.global_position.x])
			if int(_seen.get("sp_" + _kind(s), 0)) < 3:
				_seen["sp_" + _kind(s)] = int(_seen.get("sp_" + _kind(s), 0)) + 1
				_burst("sp_" + _kind(s), 1100 if _kind(s) == "row" else 1500)
		if s.call("is_live", float(s.get("_t"))):
			live.append("%s@%.0f" % [_kind(s), _spawn_x(s) - _p.global_position.x])
	if ph != _prev_phase:
		print("[st] t=%.3f PHASE %s -> %s spawns_alive=%d" % [_el(), PH[_prev_phase] if _prev_phase >= 0 else "-", PH[ph], sps.size()])
		if ph == 2:
			_burst("lucid", 3000)
		if ph == 4:
			_restored_at = _now()
		_prev_phase = ph
	var li: int = _g.get_node("AI").link_index() if _g.get_node("AI").has_method("link_index") else 0
	var st := "%s|%s|%s|%d|%s|%d" % [PH[ph], an, _clock(), li, "HB" if hb else "-", _stage()]
	if st != _prev_st:
		print("[st] t=%.3f %s dx=%.1f gy=%.1f gvx=%.1f ivo=(%.1f,%.1f) floor=%s live=%s" % [_el(), st, dx, _g.global_position.y, _g.get("velocity").x, _p.global_position.x, _p.global_position.y, _p.is_on_floor(), ",".join(live)])
		if _clock() == "T" and int(_seen.get("tel_" + an, 0)) < 2:
			_seen["tel_" + an] = int(_seen.get("tel_" + an, 0)) + 1
			_burst("tel_" + an, 450)
		if hb and int(_seen.get("hb_" + an, 0)) < 2:
			_seen["hb_" + an] = int(_seen.get("hb_" + an, 0)) + 1
			_burst("hb_" + an, 350)
		_prev_st = st
	var sk := "%s fr=%d flip=%s" % [spr.texture.resource_path.get_file().get_basename().replace("_guardian", "") if spr.texture else "-", spr.frame, spr.flip_h]
	if sk != _prev_spr:
		_prev_spr = sk
		print("[spr] t=%.3f %s gpos=(%.1f,%.1f) dx=%.1f" % [_el(), sk, _g.global_position.x, _g.global_position.y, dx])
	if hp != _prev_hp:
		if _prev_hp > hp:
			print("[hit] t=%.3f hp %d -> %d by atk=%s clock=%s hb=%s dx=%.1f dy=%.1f live=%s ivo=(%.1f,%.1f) floor=%s threat=%s" % [_el(), _prev_hp, hp, an, _clock(), hb, dx, _g.global_position.y - _p.global_position.y, ",".join(live), _p.global_position.x, _p.global_position.y, _p.is_on_floor(), _last_threat])
			_shot("hurt")
		_prev_hp = hp

func _policy(now: int) -> void:
	var rc: Node = _p.get_node("AbilityRecall")
	if rc.is_armed():
		_move("")
		if now >= _next_jump:
			_next_jump = now + 280
			_press(String(rc.armed_stats().action), 120)
		return
	var ph: int = _g.phase()
	if ph != 1 or _call_active or _p.is_in_lesson():
		_move("")
		return
	if _passive:
		_move("")
		return
	var px := _p.global_position.x
	var dx := _g.global_position.x - px
	var ad := absf(dx)
	var toward := "move_right" if dx > 0 else "move_left"
	var away := "move_left" if dx > 0 else "move_right"
	var on_floor: bool = _p.is_on_floor()
	var arena: Rect2 = _g.arena_bounds() if _g.has_method("arena_bounds") else Rect2()
	# 1. Spawns: jump a floor runner's head, step out of a pod's or patch's spot.
	var spots: Array = []
	var row_near := false
	for s in _spawns():
		var k := _kind(s)
		var t := float(s.get("_t"))
		var warn := float(s.get("warn"))
		if k == "row":
			var head := _spawn_x(s)
			var fac := float(s.get("facing"))
			var gap := (px - head) * fac
			if gap > -14.0:
				var t_reach := maxf(warn - t, 0.0) + maxf(gap - 18.0, 0.0) / float(s.get("speed"))
				if t_reach < 0.6:
					row_near = true
				if t_reach < _row_lead and on_floor and not _jumped_for.has(s.get_instance_id()):
					_jumped_for[s.get_instance_id()] = true
					_last_threat = "row jump gap=%.0f t_reach=%.2f" % [gap, t_reach]
					print("[pl] t=%.3f JUMP row gap=%.1f t_reach=%.2f live=%s" % [_el(), gap, t_reach, s.call("is_live", t)])
					_move("")
					_press("jump", 380)
					return
		elif k == "pod":
			if t < warn + float(s.get("live")):
				spots.append(s.global_position.x)
		else:
			if t < warn + float(s.get("live")):
				spots.append(s.global_position.x)
	if not spots.is_empty() and on_floor:
		var bad := false
		for x in spots:
			if absf(px - x) < 36.0:
				bad = true
		if bad:
			var best := px
			var bestd := INF
			for x in spots:
				for c in [x - 48.0, x + 48.0, x - 110.0, x + 110.0]:
					var ok := true
					for y in spots:
						if absf(c - y) < 38.0:
							ok = false
						# Never walk through another spot on the way.
						if absf(y - px) >= 36.0 and (y - px) * (c - px) > 0.0 and absf(y - px) < absf(c - px):
							ok = false
					if arena.size.x > 0.0 and (c < arena.position.x + 16.0 or c > arena.end.x - 16.0):
						ok = false
					if ok and absf(c - px) < bestd:
						bestd = absf(c - px)
						best = c
			_last_threat = "pod step to %.0f" % best
			if absf(best - px) > 3.0:
				_move("move_right" if best > px else "move_left")
			else:
				_move("")
			return
		if _moving != "" and _last_threat.begins_with("pod"):
			_move("")
			return
	if row_near:
		_move("")
		return
	# 2. The guardian's own move.
	var ca: Resource = _g.current_attack()
	var an := ca.resource_path.get_file().get_basename() if ca else ""
	var clk := _clock()
	if ca != null and ca.get("recall") != null:
		if _learned and ad < 120.0 and (clk == "T" or clk == "S"):
			_last_threat = "burst back off"
			_move(away)
		else:
			_move("")
		return
	if an == "bloom_antler_dash" and (clk == "T" or clk == "S"):
		var el: float = _g.get_node("AI").swing_elapsed() if clk == "S" else 0.0
		_last_threat = "dash el=%.2f" % el
		# Jump as the dash leaves the backstep (0.35 s into the strike): its hang outlasts any crossing.
		if clk == "S" and el >= _dash_at and on_floor and now >= _next_jump:
			_next_jump = now + 700
			print("[pl] t=%.3f JUMP dash ad=%.1f el=%.2f" % [_el(), ad, el])
			_press("jump", 400)
		_move("")
		return
	if (an == "bloom_pounce" or an == "bloom_pounce_again") and (clk == "T" or clk == "S"):
		_last_threat = "pounce " + _pounce_mode
		if _pounce_mode == "under":
			_move(toward if clk == "S" else "")
		elif _pounce_mode == "jump":
			_move("")
			if clk == "S" and ad < 90.0 and on_floor and now >= _next_jump:
				_next_jump = now + 700
				_press("jump", 400)
		else:
			_move(away)
		return
	if an == "bloom_thorn_row" and clk == "T":
		_move("")
		return
	if an in LASH_STRING and (_lash_mode == "stay" or (_lash_mode == "two" and _g.get_node("AI").link_index() == 0)) and (clk == "T" or clk == "S"):
		_last_threat = "lash stay"
		if ad > 64.0:
			_move(toward)
		else:
			_move("")
			if now >= _next_attack and on_floor:
				_next_attack = now + 330
				_press("attack", 60)
		return
	if an in LASH_STRING and (clk == "T" or clk == "S") and ad < 135.0:
		_last_threat = "lash back off"
		_move(away)
		_backoff_until = now + 250
		return
	if an == "bloom_seed_lob" and clk == "T":
		_move("")
		return
	if now < _backoff_until:
		_move(away)
		return
	# 3. Offense in the idle or the recovery.
	var punish := clk == "R" or clk == ""
	if not punish:
		_move("")
		return
	if _swings >= _swings_max:
		_swings = 0
		_backoff_until = now + 300
		_move(away)
		return
	if _pogo and ad < 110.0 and on_floor and now >= _next_jump:
		_next_jump = now + 1100
		_move(toward)
		_press("jump", 380)
		_queue.append([now + 330, "look_down", true])
		_queue.append([now + 340, "attack", true])
		_queue.append([now + 400, "attack", false])
		_queue.append([now + 700, "look_down", false])
		_swings += 1
		return
	if ad > 64.0:
		_move(toward)
	else:
		_move("")
		if ad < 80.0 and now >= _next_attack and on_floor:
			_next_attack = now + 330
			_swings += 1
			_press("attack", 60)

func _on_sig(sig: String) -> void:
	print("[sig] t=%.3f %s ivo=(%.1f,%.1f) hp=%d" % [_el(), sig, _p.global_position.x, _p.global_position.y, _p.get_node("Health").get("current_hp")])
	match sig:
		"call_opened": _call_active = true
		"call_closed": _call_active = false
		"call_answered": _burst("answered", 1000)
		"recall_started": _burst("recall", 900)
		"skill_recalled": _learned = true

func _on_window() -> void:
	print("[sig] t=%.3f call_window_opened stage=%d" % [_el(), _stage()])
	_shot("window")
	if not _answer:
		return
	_press("draw_memorina", 80, 0)
	var acts := ["note_up", "note_down", "note_left", "note_right"]
	var d := 700
	for n in _notes:
		_press(acts[n], 80, d)
		d += 450

func _find(n: Node) -> Node2D:
	if n.has_method("current_attack") and n.has_method("pressure_progress") and (n as Node2D).is_visible_in_tree():
		return n
	for c in n.get_children():
		var r := _find(c)
		if r:
			return r
	return null
