class_name MenuSoundsTest extends GdUnitTestSuite

## Menu sounds play under a WorldFreeze hold: the pause opens and closes with its cues, a focus grab is silent and a
## stepped focus moves, back steps back, the notebook opens, turns and shuts, the map is silent, a rebind capture
## stays quiet, and a button outside the scope never clicks (systems/sound-effects).

const SCREENS := preload("res://scenes/ui/screens/screens.tscn")
const TITLE := preload("res://scenes/ui/title/title.tscn")
const SOUNDS := preload("res://resources/audio/sfx/menu/menu_sounds.tres")

var _screens: Screens
var _menu_input: MenuInput
var _pause_menu: PauseMenu
var _sounds: MenuSounds
var _freeze: WorldFreeze
var _played: Array[SoundCue] = []


func before() -> void:
	SaveSystem.use_memory_only()

func before_test() -> void:
	SaveSystem.begin("", true)
	_played.clear()
	_freeze = auto_free(WorldFreeze.new()) as WorldFreeze
	add_child(_freeze)
	_screens = auto_free(SCREENS.instantiate()) as Screens
	add_child(_screens)
	_screens.hold_requested.connect(_freeze.hold)
	_screens.release_requested.connect(_freeze.release)
	_menu_input = _screens.get_node("MenuInput") as MenuInput
	_pause_menu = _screens.get_node("PauseMenu") as PauseMenu
	(_screens.get_node("Notebook") as Notebook).frame_seconds = 0.0
	_sounds = _screens.get_node("MenuSounds") as MenuSounds
	_sounds.emitter().cue_played.connect(func(cue: SoundCue) -> void: _played.append(cue))

func after_test() -> void:
	if WorldFreeze.is_held():
		_freeze.release()
	SaveSystem.begin("", true)

func _frames(count: int = 3) -> void:
	for i: int in count:
		await get_tree().process_frame

func _open_pause() -> void:
	_menu_input.pause_pressed.emit()
	await _frames()
	_played.clear()

func test_it_inherits_always_from_the_screens_root() -> void:
	assert_int(_sounds.process_mode).is_equal(Node.PROCESS_MODE_INHERIT)
	assert_int(_screens.process_mode).is_equal(Node.PROCESS_MODE_ALWAYS)
	assert_str(String((_sounds.emitter() as Node).get_class())).is_equal("Node2D")

func test_the_pause_opens_with_its_cue_heard_under_the_hold() -> void:
	_menu_input.pause_pressed.emit()
	await _frames()
	assert_bool(WorldFreeze.is_held()).is_true()
	assert_float(Engine.time_scale).is_equal(0.0)
	assert_array(_played).contains_exactly([SOUNDS.open])
	var player := _sounds.emitter().player_of(SOUNDS.open) as AudioStreamPlayer
	# The headless mixer can start a voice a buffer late, so the furthest position heard is what counts.
	var heard := 0.0
	var end := Time.get_ticks_usec() + 300_000
	while Time.get_ticks_usec() < end and heard <= 0.02:
		await get_tree().process_frame
		if player.playing:
			heard = maxf(heard, player.get_playback_position())
	assert_bool(get_tree().paused).is_true()
	assert_float(heard).is_greater(0.02)

func test_resume_plays_close_not_confirm() -> void:
	await _open_pause()
	(_pause_menu.find_child("Resume") as Button).pressed.emit()
	await _frames()
	assert_array(_played).contains_exactly([SOUNDS.close])

func test_a_focus_grab_is_silent_and_a_stepped_focus_moves() -> void:
	await _open_pause()
	(_pause_menu.find_child("Settings") as Button).grab_focus()
	await _frames()
	assert_array(_played).is_empty()
	_menu_input._input(_key(KEY_DOWN))
	(_pause_menu.find_child("QuitToTitle") as Button).grab_focus()
	await _frames()
	assert_array(_played).contains_exactly([SOUNDS.move])

## A press at the end of a list moves no focus.
func test_a_press_with_no_focus_change_is_silent() -> void:
	await _open_pause()
	_menu_input._input(_key(KEY_UP))
	await _frames()
	assert_array(_played).is_empty()

func test_a_question_confirms_and_back_steps_out_of_it() -> void:
	await _open_pause()
	var quit := _pause_menu.find_child("QuitGame") as Button
	quit.grab_focus()
	quit.pressed.emit()
	await _frames()
	assert_array(_played).contains_exactly([SOUNDS.confirm])
	_menu_input.back_pressed.emit()
	await _frames()
	assert_array(_played).contains_exactly([SOUNDS.confirm, SOUNDS.back])
	assert_int(_screens.showing()).is_equal(ScreenRouter.Kind.PAUSE)

## Esc gives a capture up inside MenuInput: no back, no close, the menu stays.
func test_a_rebind_capture_is_cancelled_silently() -> void:
	await _open_pause()
	var settings := _pause_menu.find_child("Settings") as Button
	settings.grab_focus()
	settings.pressed.emit()
	var screen := _pause_menu.find_child("SettingsScreen") as SettingsScreen
	(screen.find_child("KeyboardTab") as Control).grab_focus()
	var rows := screen.find_children("*", "Button", true, false).filter(func(node: Node) -> bool: return node is BindingRow)
	var row := rows[0] as BindingRow
	row.grab_focus()
	await _frames()
	_played.clear()
	row.pressed.emit()
	await _frames()
	assert_bool(screen.is_capturing()).is_true()
	assert_array(_played).contains_exactly([SOUNDS.confirm])
	_menu_input._input(_key(KEY_ESCAPE))
	await _frames()
	assert_bool(screen.is_capturing()).is_false()
	assert_int(_screens.showing()).is_equal(ScreenRouter.Kind.PAUSE)
	assert_array(_played).contains_exactly([SOUNDS.confirm])

## Left on the Effects row steps its volume: its preview sounds alone, the focus stays, so no MOVE.
func test_a_volume_step_plays_its_preview_and_no_menu_cue() -> void:
	await _open_pause()
	var settings := _pause_menu.find_child("Settings") as Button
	settings.grab_focus()
	settings.pressed.emit()
	var screen := _pause_menu.find_child("SettingsScreen") as SettingsScreen
	var row := screen.find_child("SoundPage").get_node("SettingsVolumeEffects") as Button
	row.grab_focus()
	await _frames()
	_played.clear()
	_menu_input.page_pressed.emit(-1)
	await _frames()
	assert_int(Settings.volume(AudioBuses.SFX)).is_equal(SettingsMath.VOLUME_STEPS - 1)
	assert_bool((screen.find_child("SfxPreview") as AudioStreamPlayer).playing).is_true()
	assert_array(_played).is_empty()
	Settings.set_volume(AudioBuses.SFX, SettingsMath.VOLUME_STEPS)

func test_the_notebook_opens_turns_and_shuts_with_the_book_cues() -> void:
	_menu_input.notebook_pressed.emit()
	await _frames(6)
	assert_array(_played).contains_exactly([SOUNDS.open])
	_menu_input.page_pressed.emit(1)
	await _frames(6)
	assert_array(_played).contains_exactly([SOUNDS.open, SOUNDS.page])
	_menu_input.notebook_pressed.emit()
	await _frames(6)
	assert_int(_screens.showing()).is_equal(ScreenRouter.Kind.NONE)
	assert_array(_played).contains_exactly([SOUNDS.open, SOUNDS.page, SOUNDS.close])

func test_the_map_is_silent() -> void:
	_sounds.on_screen_changed(ScreenRouter.Kind.NONE, ScreenRouter.Kind.MAP)
	await _frames()
	_sounds.on_screen_changed(ScreenRouter.Kind.MAP, ScreenRouter.Kind.NONE)
	await _frames()
	assert_array(_played).is_empty()

## The dialogue box's buttons live outside the Screens root.
func test_a_button_outside_the_scope_never_clicks() -> void:
	await _open_pause()
	var outside := auto_free(Button.new()) as Button
	add_child(outside)
	_menu_input._input(_key(KEY_DOWN))
	outside.grab_focus()
	outside.pressed.emit()
	await _frames()
	assert_array(_played).is_empty()

func test_the_title_steps_back_with_its_cue() -> void:
	var title := auto_free(TITLE.instantiate()) as Title
	add_child(title)
	var sounds := title.get_node("MenuSounds") as MenuSounds
	var heard: Array[SoundCue] = []
	sounds.emitter().cue_played.connect(func(cue: SoundCue) -> void: heard.append(cue))
	await _frames()
	var settings := title.find_child("Settings") as Button
	settings.grab_focus()
	settings.pressed.emit()
	await _frames()
	(title.get_node("MenuInput") as MenuInput).back_pressed.emit()
	await _frames()
	assert_array(heard).contains_exactly([SOUNDS.confirm, SOUNDS.back])
	var left := Music.playing()
	while left != null:
		Music.release(left, 0.0)
		left = Music.playing()

func _key(keycode: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.physical_keycode = keycode
	event.pressed = true
	return event
