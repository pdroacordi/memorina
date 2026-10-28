extends SceneTree
## Runs the playtest runner with song14_confirmed_page.json, then has Ivo find Redoma's guessed half (Player.learn_song_half) at 4 s real: no timeline step reaches the confirmed state.
var _t := 0.0
var _done := false
func _initialize() -> void:
	change_scene_to_file.call_deferred("res://tools/playtest/playtest_runner.tscn")
func _find(n: Node) -> Node:
	if n.has_method("learn_song_half") and n is CharacterBody2D:
		return n
	for c in n.get_children():
		var f := _find(c)
		if f != null:
			return f
	return null
func _process(delta: float) -> bool:
	_t += delta
	if not _done and _t >= 4.0:
		_done = true
		var p := _find(root)
		var ok: bool = p.learn_song_half(load("res://resources/songs/bell_jar.tres"), 2)
		print("[force] Player.learn_song_half(BELL_JAR, SECOND) -> %s at %.2f" % [ok, _t])
	return false
