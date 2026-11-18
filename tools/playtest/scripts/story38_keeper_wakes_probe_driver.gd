extends SceneTree
## Lantern (four restored, 2026-11-17 second build): zone room x 0..940 (world 10880..11820) floor to roof, triggered grounded; ivo_stand 11704; body 11600; wall x 12000.
## STORY-38 probe (run: "$GODOT" --path . -s <abs>/story38_keeper_wakes_probe_driver.gd -- --script=<timeline> --out=<dir>): runs the playtest runner and prints one [p] line per frame whose state changed (mentor staging
## children, guardian body, fight phase/telegraph/swing, FightWall, cutscene, Ivo, camera). SHOT_DIR + SHOTS=1 saves a
## screenshot on every staging/body/wall/phase change. KILL=<real s> kills Ivo. CAM=1 adds camera centre/zoom to the key.

var _last := ""
var _out := ""
var _shots := 0
var _frame := 0
var _t0 := 0

func _initialize() -> void:
	_t0 = Time.get_ticks_msec()
	_out = OS.get_environment("SHOT_DIR")
	var kill := OS.get_environment("KILL")
	if kill != "":
		for k in kill.split(","):
			create_timer(float(k), true, false, true).timeout.connect(_kill)
	change_scene_to_file.call_deferred("res://tools/playtest/playtest_runner.tscn")

func _t() -> float:
	var r := current_scene
	return float(r.get("_elapsed")) if r != null and r.get("_elapsed") != null else -1.0

func _kill() -> void:
	var ivo: Node = root.find_child("Player", true, false)
	if ivo != null:
		print("[p] KILL rt=%.2f t=%.2f" % [(Time.get_ticks_msec() - _t0) / 1000.0, _t()])
		ivo.get(&"health").call(&"take_damage", 999)

func _process(_delta: float) -> bool:
	_frame += 1
	var ivo: Node2D = root.find_child("Player", true, false) as Node2D
	if ivo == null:
		return false
	var stage := ""
	var m: Node = root.find_child("Mentor", true, false)
	if m != null:
		for c in m.get_children():
			if c is CanvasItem and (c as CanvasItem).visible:
				stage += "%s(a%.2f)" % [c.name, (c as CanvasItem).modulate.a]
				if c is AnimatedSprite2D:
					stage += "f%d" % (c as AnimatedSprite2D).frame
				stage += " "
	var g: Node2D = root.find_child("MentorGuardian", true, false) as Node2D
	var gs := "nobody"
	if g != null:
		var ph := -1
		if g.visible and g.has_method("phase"):
			ph = int(g.call("phase"))
		var act := ""
		if g.visible and g.has_method("is_swinging"):
			act = "swing" if g.call("is_swinging") else ("tele" if g.call("is_telegraphing") else "-")
		gs = "vis=%s pm=%d ph=%d %s gx=%.0f" % [g.visible, g.process_mode, ph, act, g.global_position.x]
	var wall := "nowall"
	var fw: Node = root.find_child("FightWall*", true, false)
	if fw == null:
		var lst := root.find_children("*", "StaticBody2D", true, false)
		for n in lst:
			if n.has_method("is_closed"):
				fw = n
				break
	if fw != null:
		wall = "wall=%s@%.0f" % [fw.call("is_closed"), (fw as Node2D).global_position.x]
	var dir: Node = root.find_child("CutsceneDirector", true, false)
	var sc := "-"
	if dir != null and dir.has_method("is_playing") and dir.call("is_playing"):
		var p: Resource = dir.call("playing")
		sc = String(p.get("id")) if p != null else "?"
	var hp: int = int(ivo.get(&"health").get(&"current_hp")) if ivo.get(&"health") != null else -1
	var key := "stage=[%s] g[%s] %s scene=%s hp=%d" % [stage.strip_edges(), gs, wall, sc, hp]
	var cam := root.get_camera_2d()
	var camstr := ""
	if cam != null:
		camstr = " cam=(%.1f,%.1f) z=%.3f" % [cam.get_screen_center_position().x, cam.get_screen_center_position().y, cam.zoom.x]
	var full := key + (camstr if OS.get_environment("CAM") == "1" else "")
	if full != _last:
		var changed_key := _last.split(" cam=")[0] != key
		_last = full
		print("[p] t=%.3f f=%d ivo=(%.1f,%.1f) %s%s" % [_t(), _frame, ivo.global_position.x, ivo.global_position.y, key, camstr])
		if changed_key and _out != "" and OS.get_environment("SHOTS") == "1" and _shots < 120:
			_shots += 1
			root.get_texture().get_image().save_png("%s/p%06.2f_%03d.png" % [_out, _t(), _shots])
	return false
