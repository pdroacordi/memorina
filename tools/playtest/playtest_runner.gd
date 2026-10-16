extends Node

## Windowed playtest capture harness — needs real rendering, so it must NOT be run with
## --headless (headless has no rendering device, so viewport screenshots come back blank).
## Runs scripted timelines from tools/playtest/scripts/ and captures screenshots.
##
## Run from the project root:
##   "<godot>" --path . res://tools/playtest/playtest_runner.tscn -- \
##       --script=res://tools/playtest/scripts/<name>.json --out=<absolute output dir>
##
## --out must be an absolute filesystem path so captured PNGs can be read directly.
##
## Timeline actions are dispatched through InputEventAction to exercise gameplay input.

const DEFAULT_MAX_DURATION := 60.0
## Real-time watchdog: a run that outlives `max_duration * WATCHDOG_FACTOR + WATCHDOG_SLACK` real seconds is hung.
const WATCHDOG_FACTOR := 3.0
const WATCHDOG_SLACK := 30.0
## Enemies and guardians farther than this from Ivo, in px, are left out of `log` and `trace` lines.
const FOE_RADIUS := 600.0

var _steps: Array = []
var _step_index := 0
## Timeline clock in seconds: unpaused game time, or real time when the timeline sets "clock": "real".
var _elapsed := 0.0
var _real_clock := false
## Real msec at load, for the watchdog; `max_duration` is measured on the timeline clock.
var _start_msec := 0
var _out_dir := ""
var _max_duration := DEFAULT_MAX_DURATION
var _pending_captures := 0
## While true, every physics frame prints one `trace` line (a `"trace"` step sets it).
var _tracing := false
## `as_text()` of every event the timeline sent, so `_input` can tell them from the OS's.
var _sent: PackedStringArray = PackedStringArray()

func _ready() -> void:
	var args := _parse_args()
	if not args.has("script") or not args.has("out"):
		push_error("playtest_runner requires --script=res://... and --out=<absolute dir>")
		quit_now()
		return

	_out_dir = args["out"]
	DirAccess.make_dir_recursive_absolute(_out_dir)

	var timeline := _load_timeline(args["script"])
	if timeline.is_empty():
		quit_now()
		return

	_steps = timeline.get("steps", [])
	_max_duration = float(timeline.get("max_duration", DEFAULT_MAX_DURATION))
	_real_clock = String(timeline.get("clock", "")) == "real"
	if timeline.has("locale"):
		TranslationServer.set_locale(String(timeline["locale"]))

	# Keep runs isolated from disk saves and commit setup so deaths rewind to this timeline's start.
	SaveSystem.use_memory_only()
	SaveSystem.begin("", true)
	for song_id: Variant in timeline.get("known_songs", []):
		SaveSystem.learn_song(int(song_id) as Enums.Song)
	for skill_id: Variant in timeline.get("skills", []):
		SaveSystem.unlock_skill(int(skill_id) as Enums.PlayerSkill)
	for guardian_id: Variant in timeline.get("met_guardians", []):
		SaveSystem.meet_guardian(int(guardian_id) as Enums.Guardian)
	for guardian_id: Variant in timeline.get("restored_guardians", []):
		SaveSystem.restore_guardian(int(guardian_id) as Enums.Guardian)
	for entry_id: Variant in timeline.get("notebook_read", []):
		SaveSystem.mark_notebook_read(StringName(entry_id))
	for dialogue_id: Variant in timeline.get("dialogues_heard", []):
		SaveSystem.mark_dialogue_heard(StringName(str(dialogue_id)))
	for scene_id: Variant in timeline.get("scenes_seen", []):
		SaveSystem.mark_scene_seen(StringName(str(scene_id)))
	var responses: Dictionary = timeline.get("responses", {})
	for ask_id: Variant in responses:
		SaveSystem.record_response(StringName(str(ask_id)), StringName(str(responses[ask_id])))
	# Exactly these items; a timeline without `owned_items` gets the runner's kit, the sword and the Memorina, because
	# a new game owns nothing (STORY-14) and most timelines were written for that kit.
	var owned: Array = timeline.get("owned_items", [Enums.PlayerItem.SWORD, Enums.PlayerItem.MEMORINA])
	for item: int in Enums.PlayerItem.values():
		SaveSystem.set_item_owned(item as Enums.PlayerItem, owned.has(item) or owned.has(float(item)))
	SaveSystem.commit()

	var scene_path: String = timeline.get("scene", "res://scenes/world/game.tscn")
	var packed: PackedScene = load(scene_path)
	assert(packed != null, "Could not load playtest scene %s" % scene_path)
	add_child(packed.instantiate())
	if timeline.has("player_position"):
		_place_player(timeline["player_position"])

	_start_msec = Time.get_ticks_msec()
	print("[playtest] loaded %s, %d steps, capturing to %s" % [scene_path, _steps.size(), _out_dir])

func _process(delta: float) -> void:
	var real_elapsed := (Time.get_ticks_msec() - _start_msec) / 1000.0
	if _real_clock:
		_elapsed = real_elapsed
	elif not get_tree().paused:
		_elapsed += delta

	while _step_index < _steps.size() and float(_steps[_step_index].get("t", 0.0)) <= _elapsed:
		_run_step(_steps[_step_index])
		_step_index += 1

	if _pending_captures == 0 and (_step_index >= _steps.size() or _elapsed >= _max_duration):
		quit_now()
	elif real_elapsed >= _max_duration * WATCHDOG_FACTOR + WATCHDOG_SLACK:
		push_error("[playtest] watchdog: %.0f real s with %d steps left; a menu timeline needs \"clock\": \"real\"" % [real_elapsed, _steps.size() - _step_index])
		get_tree().quit(1)

func _run_step(step: Dictionary) -> void:
	if step.has("screenshot"):
		_capture(String(step["screenshot"]))
	if step.has("action"):
		## Input.action_press()/action_release() only set the state that Input.is_action_pressed()/
		## get_axis() poll - they never dispatch an InputEvent, so a node whose _input() checks
		## event.is_action_pressed() (PlayerInput's jump/roll/attack/notes) never sees them.
		## parse_input_event() with a real InputEventAction drives both: the _input() callback
		## chain AND the polled action state, so it works for continuous and discrete alike.
		var event := InputEventAction.new()
		event.action = StringName(step["action"])
		event.pressed = bool(step.get("pressed", true))
		event.strength = 1.0 if event.pressed else 0.0
		_send(event)
	# Raw device events: an action event matches only its own action, so a key bound to
	# two actions (Z is jump and ui_accept) needs the real key to reproduce the overlap.
	if step.has("key"):
		var key := InputEventKey.new()
		var code := OS.find_keycode_from_string(String(step["key"]))
		key.keycode = code
		key.physical_keycode = code
		key.pressed = bool(step.get("pressed", true))
		_send(key)
	if step.has("joy_button"):
		var button := InputEventJoypadButton.new()
		button.button_index = int(step["joy_button"]) as JoyButton
		button.pressed = bool(step.get("pressed", true))
		button.pressure = 1.0 if button.pressed else 0.0
		_send(button)
	if step.has("joy_axis"):
		var motion := InputEventJoypadMotion.new()
		motion.axis = int(step["joy_axis"][0]) as JoyAxis
		motion.axis_value = float(step["joy_axis"][1])
		_send(motion)
	if step.has("teleport"):
		_place_player(step["teleport"])
	if step.has("log"):
		_log_state(String(step["log"]))
	if step.has("trace"):
		_tracing = bool(step["trace"])

# An unexplained F10 once moved Ivo to the song trials mid-run (playtests/2026-10-16-story15-cutscenes): every
# `debug_trials` press is logged with where it came from.
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_trials"):
		var source := "timeline" if _sent.has(event.as_text()) else "not the timeline"
		print("[playtest] debug_trials t=%.2f event='%s' class=%s device=%d echo=%s source=%s focus=%s" % [_elapsed,
				event.as_text(), event.get_class(), event.device, event.is_echo(), source,
				DisplayServer.window_is_focused()])

func _physics_process(_delta: float) -> void:
	if _tracing:
		_trace()

## One line per physics frame: Ivo's position, velocity, floor, helix ride and progress, the camera's centre, hp and nearby foes.
func _send(event: InputEvent) -> void:
	if not _sent.has(event.as_text()):
		_sent.append(event.as_text())
	Input.parse_input_event(event)

func _trace() -> void:
	var player := get_tree().get_first_node_in_group(Player.GROUP) as Player
	if player == null:
		return
	var rider := player.get_node_or_null("HelixRider") as HelixRiderComponent
	var line := "[playtest] trace t=%.3f pos=(%.2f,%.2f) vel=(%.1f,%.1f) floor=%s riding=%s moving=%s u=%.4f" % [
		_elapsed, player.global_position.x, player.global_position.y, player.velocity.x, player.velocity.y,
		player.is_on_floor(), player.is_riding_stair(), player.is_stair_moving(),
		rider.progress() if rider != null else -1.0,
	]
	var game := get_tree().root.find_child("Game", true, false)
	var camera := game.get("_camera") as GameCamera if game != null else null
	if camera != null:
		line += " cam_centre=(%.1f,%.1f)" % [camera.get_screen_center_position().x, camera.get_screen_center_position().y]
	line += " hp=%d" % player.health.current_hp
	line += _foes_state(player)
	print(line)

## Every enemy and guardian within FOE_RADIUS of Ivo: its offset from him, hp or fight phase, and what it is doing.
func _foes_state(player: Player) -> String:
	if player == null:
		return ""
	var foes: PackedStringArray = []
	for node: Node in get_tree().get_nodes_in_group(Character.CHARACTERS_GROUP):
		var foe := node as Character
		if foe == null or foe == player or not foe.is_visible_in_tree():
			continue
		var offset := foe.global_position - player.global_position
		if offset.length() > FOE_RADIUS:
			continue
		var state := ""
		if foe is Guardian:
			var guardian := foe as Guardian
			state = "%s hits=%.2f %s" % [GuardianFight.Phase.keys()[guardian.phase()], guardian.pressure_progress(),
				"swing" if guardian.is_swinging() else ("telegraph" if guardian.is_telegraphing() else "-")]
		elif foe is BruteShadow:
			var brute := foe as BruteShadow
			state = "hp=%d %s%s" % [brute.health.current_hp, "swing" if brute.is_attacking() else "-",
				" knocked" if brute.is_in_knockback() else ""]
		foes.append("%s dx=%.1f dy=%.1f %s" % [foe.name, offset.x, offset.y, state])
	return " foes=[%s]" % ", ".join(foes)

## Prints what a screenshot cannot show: pause, focus and Ivo's motion.
func _log_state(label: String) -> void:
	var focus := get_viewport().gui_get_focus_owner()
	var player := get_tree().get_first_node_in_group(Player.GROUP) as Player
	var line := "[playtest] log %s t=%.2f paused=%s scale=%.2f focus=%s" % [
		label, _elapsed, get_tree().paused, Engine.time_scale, focus.name if focus else "none",
	]
	if player:
		var voice := player.get_node("MemorinaVoice/AudioStreamPlayer") as AudioStreamPlayer
		line += " voice_playing=%s voice_paused=%s voice_pos=%.3f" % [voice.playing, voice.stream_paused, voice.get_playback_position()]
		var tree := player.get_node("AnimationTree") as AnimationTree
		var playback := tree.get("parameters/playback") as AnimationNodeStateMachinePlayback
		line += " pos=(%.1f,%.1f) vel=(%.1f,%.1f) floor=%s roll=%s jump=%s sit=%s state=%s pos_in_clip=%.3f" % [
			player.global_position.x, player.global_position.y, player.velocity.x, player.velocity.y,
			player.is_on_floor(), player.is_rolling(), player.is_jumping(), player.is_sitting(),
			playback.get_current_node() if playback else "?",
			playback.get_current_play_position() if playback else -1.0,
		]
		line += " hp=%d attack=%s climb=%s drawn=%s blocked=%s" % [
			player.health.current_hp, player.is_attacking(), player.is_climbing(),
			player.is_memorina_drawn(), player.get_node("PlayerInput").get("blocked"),
		]
	line += _room_state(player)
	line += _foes_state(player)
	line += _map_state()
	line += _notebook_state()
	line += _notice_state()
	print(line)

## The current room and its camera bounds, Ivo's facing, the fade's alpha, the weather and every loaded door.
func _room_state(player: Player) -> String:
	var game := get_tree().root.find_child("Game", true, false)
	if game == null:
		return ""
	var line := ""
	var room := game.get("_current_room") as Room
	if room != null:
		line += " room=%s interior=%s" % [room.id(), room.interior]
	var camera := game.get("_camera") as GameCamera
	if camera != null:
		var b := camera.bounds()
		line += " cam=(%.0f,%.0f %.0fx%.0f) cam_centre=(%.0f,%.0f)" % [b.position.x, b.position.y, b.size.x, b.size.y,
			camera.get_screen_center_position().x, camera.get_screen_center_position().y]
	var fade := game.get("_fade") as ColorRect
	if fade != null:
		line += " fade=%.2f" % fade.color.a
	line += " transitioning=%s" % game.get("_is_transitioning")
	if player != null:
		line += " facing=%d pmode=%d" % [player.facing, player.process_mode]
	var weather := get_tree().root.find_child("RegionWeather", true, false) as CanvasItem
	if weather != null:
		var particles := weather.get("_particles") as CPUParticles2D
		line += " weather_visible=%s particles=%s" % [weather.is_visible_in_tree(), particles != null and particles.emitting]
	var doors: PackedStringArray = []
	for node: Node in get_tree().get_nodes_in_group(&"doors"):
		var door := node as Door
		if door == null:
			continue
		doors.append("%s@%.0f:%s%s%s" % [door.link, door.global_position.x,
			"open" if door.is_open() else "sealed",
			"+prompt" if (door.get_node("Prompt") as CanvasItem).visible else "",
			" shake=%.1f" % (door.get_node("Sprite2D") as Node2D).position.x])
	line += " doors=[%s]" % ", ".join(doors)
	var title := get_tree().root.find_child("RegionTitle", true, false) as RegionTitle
	if title != null:
		line += " title=%.2f '%s' announced=%d" % [title.alpha(), title.shown_name(),
			SaveSystem.player_data.announced_regions.size()]
	return line

## Which screen is open, the map's centre and zoom, and the seen cells per room key in the live save.
func _map_state() -> String:
	var screens := get_tree().root.find_child("Screens", true, false)
	if screens == null:
		return ""
	var line := " screen=%s" % ScreenRouter.Kind.keys()[int(screens.get("_open"))]
	var map := screens.get_node_or_null("MapScreen")
	if map != null:
		line += " map_visible=%s map_centre=(%.0f,%.0f) cell_px=%d" % [map.visible, map.centre().x, map.centre().y, map.cell_px()]
	var seen: PackedStringArray = []
	for key: String in SaveSystem.player_data.map_seen:
		var bytes: PackedByteArray = SaveSystem.player_data.map_seen[key]
		var count := 0
		for i: int in range(4, bytes.size()):
			var b := bytes[i]
			while b:
				count += b & 1
				b >>= 1
		seen.append("%s:%d" % [key.get_file(), count])
	return line + " seen=[%s]" % ", ".join(seen)

## The notebook's phase, section and page, its rows (">" focused, "*" unread, "()" hidden), cues, tab marks,
## the read ids, the HUD quill's alpha and the watcher's queue.
func _notebook_state() -> String:
	var notebook := get_tree().root.find_child("Notebook", true, false) as Notebook
	if notebook == null:
		return ""
	var marks: PackedStringArray = []
	for row: NotebookRow in notebook.rows():
		var mark := String(row.entry.id) if row.entry != null else "?"
		if row.is_unread():
			mark += "*"
		if row.modulate.a == 0.0:
			mark = "(%s)" % mark
		if row.has_focus():
			mark = ">" + mark
		marks.append(mark)
	var tabs: PackedStringArray = []
	for tab: Node in notebook.get_node("%Tabs").get_children():
		tabs.append("%s%s" % [tab.name, "*" if (tab.get_node("Mark") as CanvasItem).visible else ""])
	var showing: NotebookEntry = notebook.get("_showing")
	var line := " nb=%s sec=%s page=%s rows=[%s] above=%s below=%s tabs=[%s] read=%s" % [
		Notebook.Phase.keys()[notebook.phase()], NotebookEntry.Section.keys()[notebook.section()],
		showing.id if showing != null else "-", ", ".join(marks),
		notebook.get_node("%MoreAbove").visible, notebook.get_node("%MoreBelow").visible,
		", ".join(tabs), SaveSystem.player_data.notebook_read,
	]
	var toast := get_tree().root.find_child("NotebookToast", true, false) as CanvasItem
	if toast != null:
		line += " quill=%.2f" % toast.modulate.a
	var watcher := get_tree().root.find_child("NotebookWatcher", true, false) as NotebookWatcher
	if watcher != null:
		line += " waiting=%s holding=%s" % [watcher.waiting(), watcher.is_holding()]
	return line

## The notice showing (its text and alpha), the notices waiting, and the current intent's key (systems/notices).
func _notice_state() -> String:
	var watcher := get_tree().root.find_child("NoticeWatcher", true, false) as NoticeWatcher
	var toast := get_tree().root.find_child("NoticeToast", true, false) as NoticeToast
	if watcher == null or toast == null:
		return ""
	var waiting: PackedStringArray = []
	for notice: Notice in watcher.waiting():
		waiting.append("item %d" % notice.item if notice.is_item() else "intent %s" % notice.intent_id)
	return " notice=%.2f '%s' waiting=[%s] intent=%s" % [
		(toast.get_node("Art") as CanvasItem).modulate.a if toast.is_showing() else 0.0, toast.shown_text(),
		", ".join(waiting), watcher.intent_key(),
	]

func _capture(screenshot_name: String) -> void:
	## get_viewport().get_texture() reflects the last COMPLETED render, not the frame
	## _process is currently building — capturing synchronously here would save the
	## previous frame. Waiting for the next process_frame guarantees the frame that
	## reflects everything _run_step has already applied this tick.
	_pending_captures += 1
	await get_tree().process_frame
	await get_tree().process_frame
	var image := get_viewport().get_texture().get_image()
	var path := "%s/%s.png" % [_out_dir, screenshot_name]
	var err := image.save_png(path)
	if err != OK:
		push_error("Could not save screenshot %s (error %d)" % [path, err])
	else:
		print("[playtest] wrote %s" % path)
	_pending_captures -= 1

## Optionally positions Ivo before the first timeline step.
func _place_player(at: Array) -> void:
	var player := get_tree().get_first_node_in_group(Player.GROUP) as Character
	assert(player != null, "player_position given but no node is in group %s" % Player.GROUP)
	player.teleport(Vector2(float(at[0]), float(at[1])))

func _load_timeline(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("Playtest script not found: %s" % path)
		return {}
	var text := FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Playtest script %s is not a JSON object" % path)
		return {}
	return parsed

func _parse_args() -> Dictionary:
	var result: Dictionary = {}
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--") and arg.contains("="):
			var parts := arg.substr(2).split("=", true, 1)
			result[parts[0]] = parts[1]
	return result

func quit_now() -> void:
	get_tree().quit()
