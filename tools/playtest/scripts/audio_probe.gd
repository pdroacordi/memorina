extends Node
## Dev-only audio probe (music levels and sync playtest, 2026-11-03). Added to the root by an audio driver, never by the game.
## Prints [aud] every 0.1 real s: per-bus peak dB (max over the window, max of L/R), the Music cue, position, live deck
## volume, stems, duck, pause; [cue] on each lit performance glyph; [perf] per frame while a performance plays;
## [call] on each guardian call note. Env: AUDIO_FIX_REGION=1 assigns each Region its region_<scene>.tres at runtime
## (for when the scene's `music` fails to load); AUDIO_RESTORE="<real s>:<Enums.Guardian>" restores a guardian then. No autoload or class_name is referenced (a -s script compiles before them).
const BUSES := ["Master", "Music", "Notes", "Sfx"]
const WINDOW_MS := 100
var _peak := {}
var _next := 0
var _t0 := 0
var _p: Node
var _hooked := false
var _perf_player: AudioStreamPlayer
var _cues := PackedFloat32Array()
var _g: Node
var _g_hooked := false
var _frame := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_t0 = Time.get_ticks_msec()
	_reset()
	var r := OS.get_environment("AUDIO_RESTORE")
	if r != "":
		var parts := r.split(":")
		get_tree().create_timer(float(parts[0]), true, false, true).timeout.connect(func() -> void:
			print("[aud-ev] t=%.3f f=%d restore_guardian %s" % [_t(), _frame, parts[1]])
			get_tree().root.get_node("SaveSystem").call("restore_guardian", int(parts[1])))

var _fixed := false

func _fix_regions() -> void:
	if _fixed or OS.get_environment("AUDIO_FIX_REGION") != "1":
		return
	var rm := get_tree().root.find_child("RegionMusic", true, false)
	if rm == null or rm.get("_region") == null:
		return
	_fixed = true
	for n in get_tree().root.find_children("*", "Node2D", true, false):
		if "music" in n and "horizon_y" in n and n.scene_file_path != "" and n.get("music") == null:
			var path := "res://resources/music/region_%s.tres" % n.scene_file_path.get_file().get_basename()
			if ResourceLoader.exists(path):
				n.set("music", load(path))
				print("[aud-ev] t=%.3f patched %s music=%s" % [_t(), n.name, path])
	var region: Node = rm.get("_region")
	var game := get_tree().root.find_child("Game", true, false)
	var room: Node = game.get("_current_room") if game else null
	rm.set("_region", null)
	region.disconnect("memory_changed", Callable(rm, "_on_memory_changed"))
	rm.call("on_room_changed", room)
	print("[aud-ev] t=%.3f re-entered %s" % [_t(), room])

func _reset() -> void:
	for b in BUSES:
		_peak[b] = -200.0

func _t() -> float:
	return (Time.get_ticks_msec() - _t0) / 1000.0

func _bus_db(b: String) -> float:
	var i := AudioServer.get_bus_index(b)
	if i < 0:
		return -999.0
	return maxf(AudioServer.get_bus_peak_volume_left_db(i, 0), AudioServer.get_bus_peak_volume_right_db(i, 0))

func _process(_d: float) -> void:
	_frame += 1
	for b in BUSES:
		_peak[b] = maxf(_peak[b], _bus_db(b))
	_hook()
	_fix_regions()
	if _perf_player != null and _perf_player.playing:
		print("[perf] t=%.3f f=%d pos=%.3f corr=%.3f notes=%.1f music=%.1f" % [_t(), _frame, _perf_player.get_playback_position(),
			_corr(_perf_player), _bus_db("Notes"), _bus_db("Music")])
	var now := Time.get_ticks_msec()
	if now < _next:
		return
	_next = now + WINDOW_MS
	print("[aud] t=%.2f %s %s" % [_t(), " ".join(BUSES.map(func(b: String) -> String: return "%s=%.1f" % [b, _peak[b]])), _music()])
	_reset()

func _corr(pl: AudioStreamPlayer) -> float:
	return pl.get_playback_position() + AudioServer.get_time_since_last_mix() - AudioServer.get_output_latency()

func _music() -> String:
	var m := get_tree().root.get_node_or_null("Music")
	if m == null:
		return "music=none"
	var live: Object = m.get("_live")
	var mix: Object = m.get("_mix")
	var s := "duck=%.1f hushed=%s" % [mix.call("duck_db"), m.get("_hushed")]
	var reqs: Object = m.get("_requests")
	s += " reqs=%d" % reqs.call("size")
	var decks: Array = m.get("_decks")
	for i in decks.size():
		var d: Object = decks[i]
		var pl: AudioStreamPlayer = d.get("player")
		var req: Object = d.get("request")
		var cue: Resource = req.get("cue") if req != null else null
		s += " | d%d%s %s play=%s sp=%s pos=%.2f vol=%.1f gain=%.2f" % [i, "*" if d == live else "", cue.resource_path.get_file().get_basename() if cue else "-",
			pl.playing, pl.stream_paused, pl.get_playback_position(), pl.volume_db, d.get("gain")]
		if d == live and cue != null:
			for st in cue.get("stems"):
				s += " %s=%.2f" % [st, mix.call("level", st)]
	var rm := get_tree().root.find_child("RegionMusic", true, false)
	if rm != null:
		var r: Node = rm.get("_region")
		if r != null and is_instance_valid(r):
			s += " | region=%s mem=%.3f rmusic=%s rreq=%s" % [r.name, r.call("current_baseline"), r.get("music"), rm.get("_request")]
	return s

func _hook() -> void:
	if not _hooked:
		_p = get_tree().root.find_child("Player", true, false)
		if _p != null and _p.has_signal("note_cue_reached"):
			_hooked = true
			_perf_player = _p.get_node("SongPerformance/AudioStreamPlayer")
			_p.connect("note_cue_reached", _on_cue)
			_p.connect("performance_started", _on_perf)
			_p.connect("call_note_sounded", _on_call_note)
	if not _g_hooked:
		_g = _find_guardian(get_tree().root)
		if _g != null:
			_g_hooked = true
			_g.connect("call_note_sung", _on_g_note)
			_g.connect("phase_changed", func(a: int, b: int) -> void: print("[aud-ev] t=%.3f f=%d phase %d->%d" % [_t(), _frame, a, b]))
			_g.connect("lucid_landed", func(_a: int, _b: bool) -> void: print("[aud-ev] t=%.3f f=%d lucid_landed" % [_t(), _frame]))
			_g.connect("call_ended", func() -> void: print("[aud-ev] t=%.3f f=%d call_ended" % [_t(), _frame]))
			_g.connect("restored", func(_x: Node) -> void: print("[aud-ev] t=%.3f f=%d restored" % [_t(), _frame]))

func _find_guardian(n: Node) -> Node:
	if n.has_signal("call_note_sung") and n.has_signal("lucid_landed"):
		return n
	for c in n.get_children():
		var f := _find_guardian(c)
		if f != null:
			return f
	return null

func _on_perf() -> void:
	_cues = PackedFloat32Array()
	var s: Variant = _p.get("_pending_performance")
	print("[aud-ev] t=%.3f f=%d performance_started stream=%s" % [_t(), _frame,
		_perf_player.stream.resource_path.get_file() if _perf_player.stream else "-"])

func _on_cue(i: int) -> void:
	print("[cue] t=%.3f f=%d idx=%d pos=%.3f corr=%.3f mix=%.4f lat=%.4f" % [_t(), _frame, i, _perf_player.get_playback_position(),
		_corr(_perf_player), AudioServer.get_time_since_last_mix(), AudioServer.get_output_latency()])

func _on_call_note(i: int) -> void:
	print("[call] t=%.3f f=%d player.call_note_sounded idx=%d" % [_t(), _frame, i])

func _on_g_note(i: int) -> void:
	var v := _g.find_child("Voice", true, false)
	var info := ""
	if v != null:
		for c in v.get_children():
			if c is AudioStreamPlayer and (c as AudioStreamPlayer).playing:
				var a := c as AudioStreamPlayer
				info += " %s:%s bus=%s pos=%.3f" % [a.name, a.stream.resource_path.get_file() if a.stream else "-", a.bus, a.get_playback_position()]
		if v is AudioStreamPlayer:
			var a := v as AudioStreamPlayer
			info += " self:%s bus=%s playing=%s" % [a.stream.resource_path.get_file() if a.stream else "-", a.bus, a.playing]
	print("[call] t=%.3f f=%d guardian.call_note_sung idx=%d voice:%s" % [_t(), _frame, i, info])
