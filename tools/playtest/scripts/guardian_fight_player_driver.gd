extends SceneTree
## Guardian fight driver that dodges like a player (GRD-13 playtest). Loads the playtest runner (its timeline only sets
## up). Swings in the guardian's idle and recovery, backs off from close strings, jumps floor runners and dashes, steps
## between lobbed pods' landing spots, presses the recall's action while armed, answers the call on call_window_opened.
## Prints [st] (phase, stage, move, clock phase T/S/R, link, hitbox, live spawns) on every change, [hit] (what hurt Ivo),
## [sp] (each spawn's birth and landing x), [spr] (guardian clip frame) and [shot] lines; screenshots go to --out.
## PL_CLIMB=1 climbs the wall through an owned gust's floor blow; PL_RECALL_DELAY=<ms> waits before answering a recall.
## Run: "$GODOT" --path . -s res://tools/playtest/scripts/guardian_fight_player_driver.gd -- --script=<timeline> --out=<dir>
## Env: PL_GOD=1 tops Ivo up at hp 1; PL_PASSIVE=1 stands still and never attacks (answers still);
## PL_POUNCE=away|jump|under how the pounce is dodged (away); PL_POGO=1 pogoes in punish windows instead of swinging;
## PL_LASH=back|stay|two (stay swings through the string, two swings through the lash and backs off from the back-lash on); PL_ROW_LEAD=<s> (0.12); PL_DASH_AT=<strike s> (0.33);
## PL_SWINGS=<n> swings per approach (2); PL_MAX_SHOTS=<n> (260); PL_ANSWER=0 never answers.
## Frost (GRD-14): backs out of the swipe string and the slam, jumps the ice wave and the landing shock, steps out of an
## icicle's glint and the body drop's shadow; PL_CHARGE=jump|roll how an owned charge is dodged (jump);
## PL_SWIPE=back|jump how the swipe and second swipe are dodged (back);
## PL_LEARNED=1 treats the recall's skill as owned from the start (a timeline that seeds it through "skills").
## Leaf (GRD-15): backs out of the sweep string and the overhead claw (PL_SWEEP=jump jumps the sweeps late in their
## wind-up), backs away from the hop, stands under the leaf blades on their way out and jumps them on their way back,
## steps out of the dive's shadow and the scatter's swirl, and jumps an owned gust's floor blow at the wall.
## Sun (GRD-16): backs out of the claw string (PL_CLAW=jump jumps the claws and the bite late in their wind-up; pinned
## or with a spot behind it always jumps), jumps the charge and its wall bounce, backs out of the roar (pinned, jumps over the lion), steps
## between the embers, steps out of each sun shaft just before it burns, steps out of the pounce's shadow and jumps its
## embers. Swings stand outside the guardian's contact box. The answer's notes are paced on the physics clock, and a
## [frame] line gives the median real ms per frame (gotchas/scripted-presses-timed-in-real-ms-collapse-at-a-low-frame-rate).
## A no-god run quits PL_DEATH_WAIT ms (3000) after Ivo dies. PL_KIT=lake|orchard picks the pinned roar's answer (roll
## through it, or double jump over it); PL_CHARGE=roll rolls toward the lion PL_ROLL_LEAD s (0.12) before the box
## arrives; PL_BOXED=1 answers a roar thrown into an ember gap as pinned; PL_PJ=1 jumps out of a pounce shadow over a
## burning patch (PL_PJ_AT, strike s); PL_FORCE_SEQ=1 forces ember spit then pounce slam, the pounce's jump-out swept
## (playtests/2026-11-19-grd16-sun-feel).
## No autoload or class_name is referenced: a -s script compiles before the autoloads exist.
const PH := ["DORMANT", "PRESSURE", "LUCIDITY", "RELAPSE", "RESTORED"]
const LASH_STRING := ["bloom_lash", "bloom_back_lash", "bloom_antler_thrust"]
const SWIPE_STRING := ["frost_swipe", "frost_swipe_again", "frost_slam"]
const CHARGES := ["frost_charge", "frost_charge_back", "summer_charge", "summer_charge_back"]
## Px from the guardian's centre its charge box first touches Ivo, its lunge in px/s, and how long before the box
## arrives Ivo jumps (s): the Sun's box tops out at 90 px.
const CHARGE_REACH := {"frost_charge": [112.0, 455.0, 0.24], "frost_charge_back": [112.0, 455.0, 0.24],
		"summer_charge": [88.0, 400.0, 0.34], "summer_charge_back": [88.0, 400.0, 0.34]}
const CLAW_STRING := ["summer_claw", "summer_claw_again", "summer_bite_lunge"]
const SWEEP_STRING := ["autumn_sweep", "autumn_sweep_again", "autumn_overhead_claw"]
## Px an Ivo keeps from a spot's centre, by spawn kind: an icicle's, the body drop's shadow, a pod's or patch's.
const SPOT_CLEAR := {"shard": 24.0, "shadow": 72.0, "pod": 36.0, "patch": 36.0, "swirl": 44.0}
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
## The answer's notes still to press, and the physics frame the next may go on: paced on the game's clock, so a slow
## render cannot bunch two presses inside MemorinaVoice.min_note_gap
## (gotchas/scripted-presses-timed-in-real-ms-collapse-at-a-low-frame-rate).
var _answer_left: Array = []
var _answer_frame := 0
## Real ms between rendered frames, for the run's median frame time ([frame] lines).
var _frame_ms: Array = []
var _last_frame_ms := 0
var _known_spawns: Dictionary = {}
var _jumped_for: Dictionary = {}
var _last_threat := ""
var _learned := false
var _lash_mode := "back"
var _row_lead := 0.12
var _dash_at := 0.33
var _restored_at := 0
var _charge_mode := "jump"
var _swipe_mode := "back"
var _sweep_mode := "back"
var _claw_mode := "back"
var _hop_dir := ""
var _climb := false
var _recall_delay := 0
var _armed_at := 0
var _kit := ""
var _death_wait := 3000
var _rdj_lead := 0.15
var _rdj_gap := 450
var _roll_lead := 0.12
var _boxed := false
var _pj := false
var _pj_at := 0.05
var _pj_until := 0

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
	# The roll seeded through the timeline's "skills" is owned from the start.
	_learned = OS.get_environment("PL_LEARNED") == "1"
	if OS.get_environment("PL_SWIPE") != "":
		_swipe_mode = OS.get_environment("PL_SWIPE")
	_climb = OS.get_environment("PL_CLIMB") == "1"
	if OS.get_environment("PL_RECALL_DELAY") != "":
		_recall_delay = int(OS.get_environment("PL_RECALL_DELAY"))
	if OS.get_environment("PL_SWEEP") != "":
		_sweep_mode = OS.get_environment("PL_SWEEP")
	if OS.get_environment("PL_CLAW") != "":
		_claw_mode = OS.get_environment("PL_CLAW")
	if OS.get_environment("PL_CHARGE") != "":
		_charge_mode = OS.get_environment("PL_CHARGE")
	_kit = OS.get_environment("PL_KIT")
	_boxed = OS.get_environment("PL_BOXED") == "1"
	_pj = OS.get_environment("PL_PJ") == "1"
	if OS.get_environment("PL_PJ_AT") != "":
		_pj_at = float(OS.get_environment("PL_PJ_AT"))
	if OS.get_environment("PL_ROLL_LEAD") != "":
		_roll_lead = float(OS.get_environment("PL_ROLL_LEAD"))
	if OS.get_environment("PL_DEATH_WAIT") != "":
		_death_wait = int(OS.get_environment("PL_DEATH_WAIT"))
	if OS.get_environment("PL_RDJ_LEAD") != "":
		_rdj_lead = float(OS.get_environment("PL_RDJ_LEAD"))
	if OS.get_environment("PL_RDJ_GAP") != "":
		_rdj_gap = int(OS.get_environment("PL_RDJ_GAP"))
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
	_track_frame(now)
	if _restored_at > 0 and now - _restored_at > _death_wait:
		quit()
		return false
	_p = root.find_child("Player", true, false) as Node2D
	if _p == null or not _p.has_method("is_in_lesson"):
		return false
	_answer_step()
	if _g == null or not is_instance_valid(_g):
		_g = _find(root)
		if _g == null:
			return false
	if not _hooked:
		_hooked = true
		_notes = _g.get("stats").song.notes
		_p.connect("call_window_opened", _on_window)
		_p.get_node("Hurtbox").connect("hit_received", _on_hurt_by)
		for sig in ["call_opened", "call_closed", "call_answered", "skill_recalled", "skill_recall_missed", "recall_started", "recall_step_taken", "recall_ended", "lesson_started", "sequence_failed", "jumped"]:
			var argc: int = _p.get_signal_list().filter(func(x: Dictionary) -> bool: return x.name == sig)[0].args.size()
			var cb: Callable = _on_sig.bind(sig)
			_p.connect(sig, cb.unbind(argc) if argc > 0 else cb)
	if _restored_at > 0 and now - _restored_at > _death_wait:
		quit()
		return false
	var h: Node = _p.get_node("Health")
	var hp: int = h.get("current_hp")
	if _god and hp <= 1 and hp > 0:
		h.set("current_hp", 3)
	# Dead without god mode: the run is over.
	if hp == 0 and not _god:
		if _restored_at == 0:
			print("[st] t=%.3f IVO DIED" % _el())
			_restored_at = now
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
	var kind: String = s.get_script().get_global_name()
	if kind == "FallingShard":
		return "shard"
	if kind == "FloorShadow":
		return "shadow"
	if kind == "Boomerang":
		return "blade"
	if kind == "LeafSwirl":
		return "swirl"
	if kind == "LightColumn":
		return "shaft"
	return "patch"

func _spawn_x(s: Node) -> float:
	if _kind(s) == "row":
		return s.global_position.x + float(s.get("facing")) * float(s.call("run_at", float(s.get("_t"))))
	if _kind(s) == "blade":
		return s.global_position.x + float(s.get("facing")) * float(s.call("turn_reach")) * sin(PI * _blade_u(s))
	return s.global_position.x

## 0..1 through a blade's flight: out before 0.5, back after.
func _blade_u(s: Node) -> float:
	return clampf((float(s.get("_t")) - float(s.get("warn"))) / maxf(float(s.get("live")), 0.001), 0.0, 1.0)

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
		print("[st] t=%.3f %s dx=%.1f gy=%.1f gvx=%.1f ivo=(%.1f,%.1f) floor=%s live=%s gsx=%.1f gf=%s psx=%.1f hp=%d" % [_el(), st, dx, _g.global_position.y, _g.get("velocity").x, _p.global_position.x, _p.global_position.y, _p.is_on_floor(), ",".join(live), _g.get_global_transform_with_canvas().origin.x, _g.get("facing"), _p.get_global_transform_with_canvas().origin.x, hp])
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

var _pj_list: Array = [0.0, 0.1, 0.2, 0.3, 0.4, 0.5]
var _pj_n := 0
## PL_FORCE_SEQ: a pounce is owed after each ember spit, kept until it winds up (other moves may come first).
var _want_pounce := false

## Forces ember spit, then pounce slam, then spit again: the pounce is set as the next move until it winds up.
func _force_seq() -> void:
	var ai: Node = _g.get_node("AI")
	if _g.phase() != 1:
		return
	var spit: Resource = load("res://resources/characters/guardians/summer_guardian/summer_ember_spit.tres")
	var pounce: Resource = load("res://resources/characters/guardians/summer_guardian/summer_pounce_slam.tres")
	var current: Resource = _g.current_attack()
	if current == spit:
		_want_pounce = true
	elif current == pounce:
		_want_pounce = false
	if ai.is_attacking():
		return
	ai.set("_next", pounce if _want_pounce else spit)

func _policy(now: int) -> void:
	if OS.get_environment("PL_FORCE_SEQ") == "1":
		_force_seq()
	var rc: Node = _p.get_node("AbilityRecall")
	if rc.is_armed():
		_move("")
		if _armed_at == 0:
			_armed_at = now
			print("[pl] t=%.3f ARMED ivo=(%.1f,%.1f)" % [_el(), _p.global_position.x, _p.global_position.y])
		if now - _armed_at >= _recall_delay and now >= _next_jump:
			_next_jump = now + 280
			_press(String(rc.armed_stats().action), 120)
		return
	_armed_at = 0
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
	# No room to back off: the wall (or the arena's FightWall, a cell inside it) is behind Ivo.
	var pinned: bool = arena.size.x > 0.0 and ((dx > 0 and px - arena.position.x < 80.0) or (dx < 0 and arena.end.x - px < 80.0))
	# 1. Spawns: jump a floor runner's head, step out of a pod's or patch's spot.
	var spots: Array = []
	var row_near := false
	var blade_near := false
	for s in _spawns():
		var k := _kind(s)
		var t := float(s.get("_t"))
		var warn := float(s.get("warn"))
		if k == "blade":
			if not s.call("is_live", t):
				continue
			blade_near = true
			var bx := _spawn_x(s)
			# Jump a blade on its way back (low), never while another is still high on its way out over Ivo.
			var back := _blade_u(s) > 0.5
			for o in _spawns():
				if _kind(o) == "blade" and _blade_u(o) < 0.5 and absf(_spawn_x(o) - px) < 40.0:
					back = false
			# On the way back it is low: jump it as it comes within reach; on the way out it is high: stay down.
			if back and absf(bx - px) < 70.0 + 8.0 and on_floor and not _jumped_for.has(s.get_instance_id()):
				for o in _spawns():
					if _kind(o) == "blade":
						_jumped_for[o.get_instance_id()] = true
				_last_threat = "blade jump gap=%.0f" % (bx - px)
				var us := []
				for o in _spawns():
					if _kind(o) == "blade":
						us.append("%.2f@%.0f" % [_blade_u(o), _spawn_x(o) - px])
				print("[pl] t=%.3f JUMP blade gap=%.1f u=%.2f blades=%s" % [_el(), bx - px, _blade_u(s), ",".join(us)])
				_move("")
				_press("jump", 380)
				return
			continue
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
		elif k == "shaft":
			# Lit first: out of it just before it burns, back in once it has.
			if t >= warn - 0.3 and t < warn + float(s.get("live")):
				spots.append([s.global_position.x, float(s.get("width")) * 0.5 + 12.0])
		else:
			# A shadow is never live: it marks its landing through its warning.
			if t < warn + float(s.get("live")) or (k == "shadow" and t < warn):
				# A shadow is as wide as its body's reach: keep its half width and Ivo's clear of its centre.
				var clear := float(s.get("width")) * 0.5 + 12.0 if k == "shadow" else float(SPOT_CLEAR[k])
				# A burning patch wider than the default keeps its own half width and some clear of Ivo.
				if k == "patch" and s.get("width") != null:
					clear = maxf(clear, float(s.get("width")) * 0.5 + 16.0)
				elif k == "pod" and s.has_method("rest_width"):
					clear = maxf(clear, float(s.call("rest_width")) * 0.5 + 16.0)
				spots.append([s.global_position.x, clear])
	# A roar thrown at an Ivo boxed in an ember gap: answer it as pinned (PL_BOXED=1).
	var ca0: Resource = _g.current_attack()
	var roar_boxed := false
	if _boxed and ca0 != null and ca0.resource_path.get_file() == "summer_roar.tres" and absf(dx) < 130.0:
		for sp in spots:
			if (sp[0] - px) * dx < 0.0 and absf(sp[0] - px) < sp[1] + 40.0:
				roar_boxed = true
	if roar_boxed:
		pinned = true
		_last_threat = "roar boxed"
	# A pounce shadow whose away side holds a burning patch: jump out over it (PL_PJ=1).
	if _pj and ca0 != null and ca0.resource_path.get_file() == "summer_pounce_slam.tres" and _clock() == "S" and on_floor:
		var pel: float = _g.get_node("AI").swing_elapsed()
		var blocked := false
		for s2 in _spawns():
			if _kind(s2) == "patch" and (s2.global_position.x - px) * dx < 0.0 and absf(s2.global_position.x - px) < 110.0:
				blocked = true
		if OS.get_environment("PL_FORCE_SEQ") == "1" and not _jumped_for.has(-_shadow_id()):
			_jumped_for[-_shadow_id()] = true
			_pj_at = _pj_list[_pj_n % _pj_list.size()]
			_pj_n += 1
			print("[pl] t=%.3f POUNCE #%d pj_at=%.2f ad=%.1f" % [_el(), _pj_n, _pj_at, absf(dx)])
		if blocked and pel >= _pj_at and not _jumped_for.has(_shadow_id()):
			_jumped_for[_shadow_id()] = true
			print("[pl] t=%.3f JUMP out of pounce over patch el=%.2f ad=%.1f" % [_el(), pel, absf(dx)])
			_move(away)
			_press("jump", 400)
			_pj_until = now + 900
			return
	if now < _pj_until:
		_move(away)
		return
	if not spots.is_empty() and on_floor and not roar_boxed:
		var bad := false
		for sp in spots:
			if absf(px - sp[0]) < sp[1]:
				bad = true
		if bad:
			var best := px
			var bestd := INF
			for sp in spots:
				var x: float = sp[0]
				for c in [x - sp[1] - 12.0, x + sp[1] + 12.0, x - sp[1] - 74.0, x + sp[1] + 74.0]:
					var ok := true
					for o in spots:
						var y: float = o[0]
						if absf(c - y) < o[1] + 2.0:
							ok = false
						# Never walk through another spot on the way.
						if absf(y - px) >= o[1] and (y - px) * (c - px) > 0.0 and absf(y - px) < absf(c - px):
							ok = false
					# Never step into the guardian's body; a diving one is in the air, and a cornered Ivo runs out under it.
					var diving: bool = _g.current_attack() != null and _g.current_attack().resource_path.get_file() == "autumn_dive.tres"
					if not diving and (absf(c - _g.global_position.x) < _body_clear() or ((c - px) * (_g.global_position.x - px) > 0.0 and absf(_g.global_position.x - px) < absf(c - px) + 40.0)):
						ok = false
					if arena.size.x > 0.0 and (c < arena.position.x + 16.0 or c > arena.end.x - 16.0):
						ok = false
					if ok and absf(c - px) < bestd:
						bestd = absf(c - px)
						best = c
			_last_threat = "spot step to %.0f" % best
			if absf(best - px) > 3.0:
				_move("move_right" if best > px else "move_left")
			else:
				_move("")
			return
		if _moving != "" and _last_threat.begins_with("spot"):
			_move("")
			return
	# A live or warned spot just ahead toward the guardian: hold ground rather than walk into it.
	var spot_ahead := false
	# A spot just behind Ivo: no room to back off, so a low move is jumped instead.
	var spot_behind := false
	for sp in spots:
		if (sp[0] - px) * dx > 0.0 and absf(sp[0] - px) < sp[1] + 24.0:
			spot_ahead = true
		if (sp[0] - px) * dx < 0.0 and absf(sp[0] - px) < sp[1] + 40.0:
			spot_behind = true
	if row_near or blade_near:
		_move("")
		return
	# 2. The guardian's own move.
	var ca: Resource = _g.current_attack()
	var an := ca.resource_path.get_file().get_basename() if ca else ""
	var clk := _clock()
	if an != "autumn_hop":
		_hop_dir = ""
	if an == "autumn_gust" and _learned and clk == "S":
		# An owned gust carries Ivo to the wall; its floor blow opens 2.0 s in: jump it there.
		var gel: float = _g.get_node("AI").swing_elapsed()
		_last_threat = "gust el=%.2f" % gel
		if _climb and gel >= 1.2:
			# Climb: hold into the nearest wall and tap jump every 0.5 s through the floor blow.
			var wall := "move_left" if px - arena.position.x < arena.end.x - px else "move_right"
			_move(wall)
			if now >= _next_jump:
				_next_jump = now + 500
				print("[pl] t=%.3f CLIMB gust el=%.2f y=%.1f floor=%s" % [_el(), gel, _p.global_position.y, on_floor])
				_press("jump", 300)
			return
		_move("")
		if gel >= 1.85 and gel < 2.1 and on_floor and now >= _next_jump:
			_next_jump = now + 700
			print("[pl] t=%.3f JUMP gust el=%.2f" % [_el(), gel])
			_press("jump", 400)
		return
	if an == "autumn_overhead_claw" and pinned and (clk == "T" or clk == "S") and ad < 150.0:
		# Pinned under the claw: a double jump over its 150 px reach.
		_last_threat = "claw double jump"
		_move("")
		if clk == "T" and now >= _next_jump:
			_next_jump = now + 900
			print("[pl] t=%.3f DOUBLE JUMP claw ad=%.1f floor=%s" % [_el(), ad, on_floor])
			# Still in the air from jumping the sweep: the air jump alone.
			if on_floor:
				_press("jump", 380)
				_press("jump", 380, 420)
			else:
				_press("jump", 380)
		return
	if an in SWEEP_STRING and (_sweep_mode == "jump" or pinned) and an != "autumn_overhead_claw" and (clk == "T" or clk == "S") and ad < 150.0:
		_last_threat = "%s jump" % an
		_move("")
		var sleft := float(_g.get_node("AI").get("_clock").get("_left")) if clk == "T" else 0.0
		if clk == "T" and sleft < 0.12 and on_floor and now >= _next_jump:
			_next_jump = now + 600
			print("[pl] t=%.3f JUMP %s ad=%.1f left=%.2f" % [_el(), an, ad, sleft])
			_press("jump", 380)
		return
	if an in SWEEP_STRING and (clk == "T" or clk == "S") and ad < 150.0:
		_last_threat = "%s back off" % an
		_move(away)
		_backoff_until = now + 250
		return
	if an == "autumn_hop" and (clk == "T" or clk == "S"):
		# Under the middle of its arc from its comfort distance out; from closer, away unless the wall is behind. The
		# direction is chosen once per hop, as it winds up: the hop closes the distance and passes over Ivo.
		if _hop_dir == "":
			_hop_dir = toward if (pinned or ad >= 100.0) else away
		var under := _hop_dir == toward
		_last_threat = "hop under" if under else "hop away"
		_move(("" if clk == "T" else _hop_dir) if under else _hop_dir)
		return
	if (an == "autumn_dive" or an == "autumn_leaf_blades" or an == "autumn_scatter") and clk == "T":
		_move("")
		return
	if an in CHARGES and _charge_mode != "roll" and (ca.get("recall") == null or _learned) and (clk == "T" or clk == "S"):
		var cel: float = _g.get_node("AI").swing_elapsed() if clk == "S" else 0.0
		_last_threat = "charge %s el=%.2f" % [_charge_mode, cel]
		_move("")
		# The box opens at 0.5 s, first touches Ivo at its reach and runs at its lunge; a jump needs ~0.22 s to clear it.
		var reach: float = CHARGE_REACH[an][0]
		var speed: float = CHARGE_REACH[an][1]
		var t_hit := 0.5 + maxf(ad - reach, 0.0) / speed if cel < 0.5 else maxf(ad - reach, 0.0) / speed
		if clk == "S" and t_hit - (cel if cel < 0.5 else 0.0) <= float(CHARGE_REACH[an][2]) and on_floor and now >= _next_jump:
			_next_jump = now + 700
			print("[pl] t=%.3f %s charge ad=%.1f el=%.2f" % [_el(), _charge_mode.to_upper(), ad, cel])
			_press("roll" if _charge_mode == "roll" else "jump", 120 if _charge_mode == "roll" else 400)
		return
	if an in CHARGES and _charge_mode == "roll" and (clk == "T" or clk == "S"):
		# Roll through the charge toward the lion as its box is about to reach Ivo (0.58 s of i-frames).
		var rel: float = _g.get_node("AI").swing_elapsed() if clk == "S" else 0.0
		var rreach: float = CHARGE_REACH[an][0]
		var rt := 0.5 + maxf(ad - rreach, 0.0) / 400.0 if rel < 0.5 else maxf(ad - rreach, 0.0) / 400.0
		_last_threat = "charge roll el=%.2f" % rel
		_move(toward if clk == "S" else "")
		if clk == "S" and rt - (rel if rel < 0.5 else 0.0) <= _roll_lead and on_floor and now >= _next_jump:
			_next_jump = now + 900
			print("[pl] t=%.3f ROLL charge ad=%.1f el=%.2f" % [_el(), ad, rel])
			_press("roll", 120)
		return
	if an in SWIPE_STRING and _swipe_mode == "jump" and an != "frost_slam" and (clk == "T" or clk == "S") and ad < 170.0:
		# Jump the swipes in place late in their wind-up (their box top is 60 px), and back out of the slam.
		_last_threat = "%s jump" % an
		_move("")
		var remaining := float(_g.get_node("AI").get("_clock").get("_left")) if clk == "T" else 0.0
		if clk == "T" and remaining < 0.15 and on_floor and now >= _next_jump:
			_next_jump = now + 600
			print("[pl] t=%.3f JUMP %s ad=%.1f left=%.2f" % [_el(), an, ad, remaining])
			_press("jump", 380)
		return
	if an in SWIPE_STRING and (clk == "T" or clk == "S") and ad < 140.0:
		_last_threat = "%s back off" % an
		_move(away)
		_backoff_until = now + 250
		return
	if an in CLAW_STRING and (clk == "T" or clk == "S") and ad < 180.0:
		if _claw_mode == "jump" or pinned or spot_behind:
			# The claws' box tops out at 48 px, the bite's at 80: jump late in the claws' wind-up, earlier for the bite.
			_last_threat = "%s jump" % an
			_move("")
			var cleft := float(_g.get_node("AI").get("_clock").get("_left")) if clk == "T" else 0.0
			var lead := 0.3 if an == "summer_bite_lunge" else 0.12
			if clk == "T" and cleft < lead and on_floor and now >= _next_jump:
				_next_jump = now + 600
				print("[pl] t=%.3f JUMP %s ad=%.1f left=%.2f" % [_el(), an, ad, cleft])
				_press("jump", 380)
			return
		_last_threat = "%s back off" % an
		_move(away)
		_backoff_until = now + 250
		return
	if an == "summer_roar" and (clk == "T" or clk == "S"):
		if pinned and ad < 130.0 and _kit == "lake":
			_last_threat = "roar roll"
			var rleft := float(_g.get_node("AI").get("_clock").get("_left")) if clk == "T" else 0.0
			if clk == "T" and rleft < 0.3 and on_floor and now >= _next_jump:
				_next_jump = now + 1200
				print("[pl] t=%.3f ROLL through roar ad=%.1f left=%.2f" % [_el(), ad, rleft])
				_move(toward)
				_press("roll", 120)
			return
		if pinned and ad < 130.0 and _kit == "orchard":
			_last_threat = "roar djump"
			_move("")
			var dleft := float(_g.get_node("AI").get("_clock").get("_left")) if clk == "T" else 0.0
			if clk == "T" and dleft < _rdj_lead and on_floor and now >= _next_jump:
				_next_jump = now + 1500
				print("[pl] t=%.3f DJUMP roar ad=%.1f left=%.2f" % [_el(), ad, dleft])
				_press("jump", 400)
				_press("jump", 400, _rdj_gap)
			return
		if pinned and ad < 130.0:
			# No room to back off: over the lion early in its wind-up, before it rears.
			_last_threat = "roar over"
			if clk == "T" and on_floor and now >= _next_jump:
				_next_jump = now + 1200
				print("[pl] t=%.3f JUMP over roar ad=%.1f" % [_el(), ad])
				_press("jump", 400)
			_move(toward if not on_floor or now < _next_jump else "")
			return
		if ad < 140.0:
			_last_threat = "roar back off"
			_move(away)
			return
		_move("")
		return
	if (an == "summer_ember_spit" or an == "summer_sun_shafts" or an == "summer_pounce_slam") and clk == "T":
		_move("")
		return
	if (an == "frost_icicle_fall" or an == "frost_body_drop") and clk == "T":
		_move("")
		return
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
	var stand := _stand_at()
	# A guardian walking in stops where its next move reaches: wait for it a little further out.
	if float(_g.get("velocity").x) * signf(px - _g.global_position.x) > 10.0:
		stand += 24.0
	if ad > stand:
		_move("" if spot_ahead else toward)
	else:
		_move("")
		# Swing only once stopped: a running swing carries Ivo into the contact box.
		if ad < stand + 16.0 and now >= _next_attack and on_floor and absf(float(_p.get("velocity").x)) < 20.0:
			_next_attack = now + 330
			_swings += 1
			_press("attack", 60)

func _shadow_id() -> int:
	for s3 in _spawns():
		if _kind(s3) == "shadow":
			return s3.get_instance_id()
	return -1

## Px from the guardian's centre an Ivo swings from: outside its contact box, never under 64.
func _stand_at() -> float:
	return maxf(64.0, (_g.body_rect().size.x * 0.5 if _g.has_method("body_rect") else 0.0) + 30.0)

## Px from the guardian's centre a step never ends inside.
func _body_clear() -> float:
	return maxf(72.0, (_g.body_rect().size.x * 0.5 if _g.has_method("body_rect") else 0.0) + 24.0)

## What hurt Ivo: the hitting node, its position and Ivo's.
func _on_hurt_by(damage: int, _knockback: Vector2, source: Node2D) -> void:
	var path := "%s/%s" % [source.get_parent().name, source.name] if source else "-"
	print("[src] t=%.3f dmg=%d by=%s at=(%.1f,%.1f) ivo=(%.1f,%.1f)" % [_el(), damage, path, source.global_position.x if source else 0.0,
			source.global_position.y if source else 0.0, _p.global_position.x, _p.global_position.y])

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
	_answer_left = _notes.duplicate()
	_answer_frame = Engine.get_physics_frames() + 42

## Presses the answer's next note once 0.45 s of game time has passed since the last and the voice will take it.
func _answer_step() -> void:
	if _answer_left.is_empty() or Engine.get_physics_frames() < _answer_frame:
		return
	var voice: Node = _p.get_node_or_null("MemorinaVoice")
	if voice != null and voice.has_method("can_play_note") and not voice.can_play_note():
		return
	var acts := ["note_up", "note_down", "note_left", "note_right"]
	_press(acts[_answer_left.pop_front()], 80)
	_answer_frame = Engine.get_physics_frames() + 27

## Records the real ms since the last rendered frame; every 600 frames prints the median.
func _track_frame(now: int) -> void:
	if _last_frame_ms > 0:
		_frame_ms.append(now - _last_frame_ms)
	_last_frame_ms = now
	if _frame_ms.size() >= 600:
		_frame_ms.sort()
		print("[frame] t=%.3f median_ms=%d max_ms=%d n=%d" % [_el(), _frame_ms[_frame_ms.size() / 2], _frame_ms[-1], _frame_ms.size()])
		_frame_ms.clear()

func _find(n: Node) -> Node2D:
	if n.has_method("current_attack") and n.has_method("pressure_progress") and (n as Node2D).is_visible_in_tree():
		return n
	for c in n.get_children():
		var r := _find(c)
		if r:
			return r
	return null
