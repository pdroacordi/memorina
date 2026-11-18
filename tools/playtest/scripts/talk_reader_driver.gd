extends SceneTree
## Runs the playtest runner and reads any talk at a steady pace (Z after READ s of a fully typed line or choice, choice 0), printing [dlg]/[stage]/[box] lines; screenshots each line, each Props/Mentor stage change and every 0.2 s of a box-closed beat.
## Run: "$GODOT" --path . -s <abs>/talk_reader_driver.gd -- --script=<timeline> --out=<dir>; env SHOT_DIR=<abs dir>, READ (s, default 1.0), UP_AFTER=1 (after the talk, walk left 0.15 s and press Up), GAP (s between box-closed shots, default 0.2; 0.07 for a burst), CAMLOG=1 (a [cam] line on every change of screen centre or zoom), STRIPSHOT=1 (a shot one frame after each Props/Mentor strip frame change; [strip] lines always print), MASH=<s> (tap Z every <s> while the talk blocks Ivo).
var _out := ""
var _read := 1.0
var _typed_at := -1.0
var _last_text := ""
var _last_stage := ""
var _last_box := ""
var _line_n := 0
var _shots := 0
var _gap_next := 0.0
var _pressed_for := ""
var _talk_seen := false
var _ended_at := -1.0
var _up_phase := 0
var _pending: Array = []
var _last_cam := ""
var _last_strip := ""
var _shot_next := ""
var _mash_next := 0.0

func _initialize() -> void:
	_out = OS.get_environment("SHOT_DIR")
	if OS.get_environment("READ") != "":
		_read = float(OS.get_environment("READ"))
	change_scene_to_file.call_deferred("res://tools/playtest/playtest_runner.tscn")

func _now() -> float:
	return Time.get_ticks_msec() / 1000.0

func _t() -> float:
	var r := current_scene
	return float(r.get("_elapsed")) if r != null and r.get("_elapsed") != null else -1.0

func _key(code: Key, down: bool) -> void:
	var k := InputEventKey.new()
	k.keycode = code
	k.physical_keycode = code
	k.pressed = down
	Input.parse_input_event(k)

func _tap(code: Key) -> void:
	_key(code, true)
	_pending.append([_now() + 0.08, code])

func _shot(name: String) -> void:
	if _out == "" or _shots >= 600:
		return
	_shots += 1
	var img := root.get_texture().get_image()
	img.save_png("%s/%06.2f_%s.png" % [_out, _t(), name])

func _process(_delta: float) -> bool:
	var now := _now()
	for p in _pending.duplicate():
		if now >= p[0]:
			_key(p[1], false)
			_pending.erase(p)
	if _shot_next != "":
		_shot(_shot_next)
		_shot_next = ""
	var box: Control = root.find_child("DialogueBox", true, false)
	var player: Node = root.find_child("Player", true, false)
	if box == null or player == null:
		return false
	var mm: Node = root.find_child("Mentor", true, false)
	if mm != null and mm.get_parent() != null and mm.get_parent().name == "Props":
		var sd := ""
		for c in mm.get_children():
			if c is AnimatedSprite2D and (c as CanvasItem).visible:
				var a := c as AnimatedSprite2D
				sd += "%s:%s#%d " % [c.name, a.animation, a.frame]
			elif c is CanvasItem and (c as CanvasItem).visible:
				sd += "%s " % c.name
		if sd != _last_strip:
			_last_strip = sd
			var bx: Control = box
			print("[strip] t=%.3f f=%d %s box=%s" % [_t(), Engine.get_process_frames(), sd, bx.get_global_rect() if bx.is_visible_in_tree() else "closed"])
			if OS.get_environment("STRIPSHOT") == "1":
				_shot_next = "fr_" + sd.strip_edges().replace(" ", "+").replace(":", "-").replace("#", "f")
	var mash := float(OS.get_environment("MASH")) if OS.get_environment("MASH") != "" else 0.0
	if mash > 0.0 and _t() > 4.0 and _ended_at < 0.0 and _now() >= _mash_next:
		var blk: bool = player.get_node("PlayerInput").get("blocked") if player.has_node("PlayerInput") else false
		if blk or box.is_visible_in_tree():
			_mash_next = _now() + mash
			_tap(KEY_Z)
	var ivo := player as Node2D
	# Mentor staging and guardian body.
	var stage := ""
	var m: Node = root.find_child("Mentor", true, false)
	if m != null and m.get_parent() != null and m.get_parent().name == "Props":
		for c in m.get_children():
			if c is CanvasItem and (c as CanvasItem).visible:
				stage += "%s(a%.2f) " % [c.name, (c as CanvasItem).modulate.a]
	var g: Node = root.find_child("MentorGuardian", true, false)
	if g != null:
		stage += "| guardian vis=%s pm=%d pos=%s" % [(g as CanvasItem).visible, g.process_mode, (g as Node2D).global_position]
	if stage != _last_stage:
		_last_stage = stage
		print("[stage] t=%.2f %s" % [_t(), stage])
		_shot("stage")
	var text := ""
	var vis := box.is_visible_in_tree()
	if vis:
		text = box.text_label().text
		if box.is_choosing():
			text = "CHOICE: " + box.choice_button(0).text + " / " + box.choice_button(1).text
	var cam := root.get_camera_2d()
	var bdesc := "vis=%s" % vis
	if vis:
		var panel := box.get_global_rect()
		bdesc += " rect=%s" % panel
	if cam != null:
		bdesc += " cam=%s zoom=%.2f" % [cam.get_screen_center_position(), cam.zoom.x]
	bdesc += " ivo=%s" % ivo.global_position
	if text != _last_text:
		_last_text = text
		_typed_at = -1.0
		_pressed_for = ""
		if text != "":
			_line_n += 1
			_talk_seen = true
		print("[dlg] t=%.2f n=%d '%s'" % [_t(), _line_n, text])
	if cam != null and OS.get_environment("CAMLOG") == "1":
		var cl := "%.2f %.2f %.3f" % [cam.get_screen_center_position().x, cam.get_screen_center_position().y, cam.zoom.x]
		if cl != _last_cam:
			_last_cam = cl
			print("[cam] t=%.3f f=%d %s" % [_t(), Engine.get_process_frames(), cl])
	if bdesc != _last_box and (vis != _last_box.begins_with("vis=true")):
		print("[box] t=%.2f %s" % [_t(), bdesc])
	_last_box = bdesc
	var blocked: bool = player.get_node("PlayerInput").get("blocked") if player.has_node("PlayerInput") else false
	if vis and text != "":
		if not box.is_typing() and _typed_at < 0.0:
			_typed_at = now
			print("[dlg] t=%.2f typed n=%d" % [_t(), _line_n])
		if _typed_at >= 0.0 and _pressed_for != text:
			if now - _typed_at >= 0.15 and now - _typed_at < 0.15 + 1.0 / 60.0 * 2:
				_shot("L%02d" % _line_n)
			if now - _typed_at >= _read:
				_pressed_for = text
				print("[dlg] t=%.2f press Z n=%d" % [_t(), _line_n])
				_tap(KEY_Z)
	elif blocked and _talk_seen and now >= _gap_next:
		_gap_next = now + (float(OS.get_environment("GAP")) if OS.get_environment("GAP") != "" else 0.2)
		_shot("gap")
	# End of talk and the Up check.
	if _talk_seen and not blocked and not vis:
		if _ended_at < 0.0:
			_ended_at = now
			print("[dlg] t=%.2f talk ended, unblocked" % _t())
	else:
		_ended_at = -1.0 if blocked else _ended_at
	if OS.get_environment("UP_AFTER") == "1" and _ended_at > 0.0:
		if _up_phase == 0 and now - _ended_at > 1.5:
			_up_phase = 1
			print("[dlg] t=%.2f Up phase: left 0.15 s" % _t())
			_key(KEY_LEFT, true)
			_pending.append([now + 0.15, KEY_LEFT])
		elif _up_phase == 1 and now - _ended_at > 2.2:
			_up_phase = 2
			print("[dlg] t=%.2f Up pressed ivo=%s" % [_t(), ivo.global_position])
			_tap(KEY_UP)
			_talk_seen = false
	return false
