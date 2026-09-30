extends Node

## Windowed playtest capture harness — needs real rendering, so it must NOT be run with
## --headless (headless has no rendering device, so viewport screenshots come back blank).
## Drives a scene through a scripted input timeline (see tools/playtest/scripts/*.json)
## and saves viewport screenshots at chosen timestamps, then quits on its own.
##
## Run from the project root:
##   "<godot>" --path . res://tools/playtest/playtest_runner.tscn -- \
##       --script=res://tools/playtest/scripts/<name>.json --out=<absolute output dir>
##
## --out must be an absolute filesystem path, not res://, so the calling agent can Read
## the resulting PNGs back without guessing where user:// resolves to on this machine.
##
## This drives Input.action_press/action_release, which PlayerInput reads exactly like a
## live keyboard/pad, so the played-back run exercises real gameplay code, not a mock.

const DEFAULT_MAX_DURATION := 60.0

var _steps: Array = []
var _step_index := 0
var _elapsed := 0.0
var _out_dir := ""
var _max_duration := DEFAULT_MAX_DURATION
var _pending_captures := 0

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

	var scene_path: String = timeline.get("scene", "res://scenes/world/game.tscn")
	var packed: PackedScene = load(scene_path)
	assert(packed != null, "Could not load playtest scene %s" % scene_path)
	add_child(packed.instantiate())
	if timeline.has("player_position"):
		_place_player(timeline["player_position"])
	# Optional `"known_songs": [Enums.Song ids]`: taught through the save before
	# step 0, so a timeline can PLAY a song without first sitting its lesson.
	for song_id: Variant in timeline.get("known_songs", []):
		SaveSystem.learn_song(int(song_id) as Enums.Song)

	print("[playtest] loaded %s, %d steps, capturing to %s" % [scene_path, _steps.size(), _out_dir])

func _process(delta: float) -> void:
	_elapsed += delta

	while _step_index < _steps.size() and float(_steps[_step_index].get("t", 0.0)) <= _elapsed:
		_run_step(_steps[_step_index])
		_step_index += 1

	if _pending_captures == 0 and (_step_index >= _steps.size() or _elapsed >= _max_duration):
		quit_now()

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
		Input.parse_input_event(event)

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

## Optional `"player_position": [x, y]` teleports Ivo before the first step, so a
## timeline can start beside the thing it tests instead of walking there.
func _place_player(at: Array) -> void:
	var player := get_tree().get_first_node_in_group(Player.GROUP) as Node2D
	assert(player != null, "player_position given but no node is in group %s" % Player.GROUP)
	player.global_position = Vector2(float(at[0]), float(at[1]))

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
