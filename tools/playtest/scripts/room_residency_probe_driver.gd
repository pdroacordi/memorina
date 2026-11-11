extends SceneTree
## Dev-only: loads the playtest runner and, on RenderingServer.frame_pre_draw, checks room residency against the view.
## Prints [t12] BUILD/WAKE/IDLE/EVICT/STATE, INVIEW/OUTVIEW, VIOLATION (a waiting or pending room's shown cells, or an
## unbuilt room's bounds, meet the drawn view while the fade is not opaque), NEAR, HITCH (dt > 20 ms) and SUMMARY.
## T12_DISS=1 forces the dissonance veil (2.0 s) and revelation (3.5 s) off at 5.0 s. playtests/2026-11-11-tech12-room-loading

var _game: Node = null
var _runner: Node = null
var _last_us := 0
var _frame := 0
var _state: Dictionary = {}
var _inview: Dictionary = {}
var _dts: PackedFloat32Array = []
var _wait_frames := 0
var _min_gap := INF
var _diss_stage := -1


func _initialize() -> void:
	change_scene_to_file.call_deferred("res://tools/playtest/playtest_runner.tscn")
	RenderingServer.frame_pre_draw.connect(_pre_draw)


func _t() -> float:
	if _runner != null and is_instance_valid(_runner):
		return float(_runner.get("_elapsed"))
	return -1.0


func _find_game() -> void:
	if _runner == null or not is_instance_valid(_runner):
		_runner = current_scene
	if _game == null or not is_instance_valid(_game):
		_game = null
		for n: Node in root.find_children("*", "Node2D", true, false):
			if n.get("_residency") != null and n.get("_camera") != null:
				_game = n
				break


func _view() -> Rect2:
	var vp := root
	var xf := vp.get_canvas_transform()
	return xf.affine_inverse() * Rect2(Vector2.ZERO, vp.get_visible_rect().size)


func _pre_draw() -> void:
	_frame += 1
	var now := Time.get_ticks_usec()
	var dt := (now - _last_us) / 1000.0 if _last_us > 0 else 0.0
	_last_us = now
	_find_game()
	if _game == null:
		return
	if dt > 20.0:
		print("[t12] HITCH f=%d t=%.3f dt=%.1fms" % [_frame, _t(), dt])
	_dts.append(dt)
	if OS.get_environment("T12_DISS") == "1":
		_force_dissonance()
	var view := _view()
	var res: Object = _game.get("_residency")
	var waiting: Array = res.get("_waiting") if res.get("_waiting") != null else []
	var rooms := _all_rooms()
	var cur: Node = _game.get("_current_room")
	if not waiting.is_empty() and _game.get("_fade") != null and _game.get("_fade").has_method("is_opaque") and not _fade_opaque():
		_wait_frames += 1
		for w: Node in waiting:
			for cell: Rect2 in w.call("shown_cells"):
				var g := _gap(view, cell)
				if g < _min_gap:
					_min_gap = g
				if g < 48.0:
					print("[t12] NEAR f=%d t=%.3f %s gap=%.1f" % [_frame, _t(), w.call("id"), g])
	for room: Node in rooms:
		var id := String(room.call("id"))
		var c: Node = room.call("contents")
		var st := "none"
		if c != null:
			if not c.is_inside_tree():
				st = "pending"
			elif room.call("is_active"):
				st = "active"
			else:
				st = "idle"
		if room in waiting:
			st = "waiting"
		var prev: String = _state.get(id, "none")
		if prev != st:
			print("[t12] %s f=%d t=%.3f dt=%.1f %s->%s%s" % [_ev(prev, st), _frame, _t(), dt, prev, st, " CUR" if room == cur else ""] + " " + id)
			_state[id] = st
			if st == "active" and c != null:
				_check_clip(id, c)
		var shown: Array = room.call("shown_cells") if room.has_method("shown_cells") else [room.call("get_bounds")]
		var meets := false
		for cell: Rect2 in shown:
			if view.intersects(cell):
				meets = true
				break
		var was: bool = _inview.get(id, false)
		if meets and not was:
			print("[t12] INVIEW f=%d t=%.3f %s state=%s view=%s" % [_frame, _t(), id, st, view])
		elif was and not meets:
			print("[t12] OUTVIEW f=%d t=%.3f %s" % [_frame, _t(), id])
		_inview[id] = meets
		var hole: bool = st != "active" and view.intersects(room.call("get_bounds"))
		if ((meets and (st == "waiting" or st == "pending")) or hole) and not _fade_opaque():
			print("[t12] VIOLATION f=%d t=%.3f %s state=%s hole=%s view=%s" % [_frame, _t(), id, st, hole, view])


func _gap(a: Rect2, b: Rect2) -> float:
	var dx := maxf(a.position.x - b.end.x, b.position.x - a.end.x)
	var dy := maxf(a.position.y - b.end.y, b.position.y - a.end.y)
	return maxf(maxf(dx, dy), 0.0)


func _fade_opaque() -> bool:
	var f: Object = _game.get("_fade")
	return f != null and f.has_method("is_opaque") and bool(f.call("is_opaque"))


func _check_clip(id: String, c: Node) -> void:
	var bd := c.find_child("Backdrop", true, false)
	if bd == null or not bd.has_method("clip_of"):
		print("[t12] CLIP %s no-backdrop" % id)
		return
	print("[t12] CLIP %s self=%s visible=%s" % [id, bd.call("clip_of", bd), (bd as CanvasItem).is_visible_in_tree()])


func _ev(prev: String, st: String) -> String:
	if st == "active" and prev == "idle":
		return "WAKE"
	if st == "active":
		return "BUILD"
	if st == "idle":
		return "IDLE"
	if st == "none":
		return "EVICT"
	return "STATE"


func _all_rooms() -> Array[Node]:
	var out: Array[Node] = []
	for n: Node in get_nodes_in_group(&"room"):
		out.append(n)
	if out.is_empty():
		for n: Node in root.find_children("*", "Area2D", true, false):
			if n.has_method("shown_cells"):
				out.append(n)
	return out


func _finalize() -> void:
	var s := Array(_dts)
	s.sort()
	if s.size() > 10:
		print("[t12] WAITSUM visible_waiting_frames=%d min_gap=%.1f" % [_wait_frames, _min_gap])
		print("[t12] SUMMARY frames=%d p50=%.1f p99=%.1f max=%.1f over20=%d over33=%d" % [s.size(), s[s.size() / 2], s[int(s.size() * 0.99)], s[-1], s.filter(func(x: float) -> bool: return x > 20.0).size(), s.filter(func(x: float) -> bool: return x > 33.0).size()])


func _force_dissonance() -> void:
	var t := _t()
	var stage := 0 if t < 2.0 else (1 if t < 3.5 else (2 if t < 5.0 else 3))
	if stage == _diss_stage:
		return
	_diss_stage = stage
	var vals := [[0.0, 0.0], [0.6, 0.0], [0.0, 0.8], [0.0, 0.0]][stage] as Array
	for n: Node in root.find_children("*", "Node", true, false):
		if n.has_method("set_dissonance"):
			n.call("set_dissonance", vals[0], vals[1])
			var copy: Node = n.get_node_or_null(n.get("copy_path")) if n.get("copy_path") != null else null
			var veil: Node = n.get_node_or_null(n.get("veil_path"))
			print("[t12] DISS t=%.3f veil=%s rev=%s veil_visible=%s copy=%s" % [t, vals[0], vals[1], veil.visible if veil else null, (copy as CanvasItem).visible if copy else "none"])
