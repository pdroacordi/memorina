class_name PlayerInput
extends CharacterController
## Translates hardware events into player intent and derives the glyph set used to display pressed controls.

signal attack_pressed
signal jump_pressed
signal jump_canceled
signal roll_pressed
signal draw_memorina_pressed
## Emitted on the down press edge used to sit at a bench.
signal look_down_pressed
signal note_pressed(note: Enums.Note, glyph_set: Enums.GlyphSet)
## Debug-build action for teaching the next unknown song.
signal debug_learn_song_pressed

## Which action plays which note. A dictionary rather than four branches
## because the mapping is data, and every entry behaves identically.
const NOTE_ACTIONS: Dictionary = {
	&"note_up": Enums.Note.UP,
	&"note_down": Enums.Note.DOWN,
	&"note_left": Enums.Note.LEFT,
	&"note_right": Enums.Note.RIGHT,
}

## The keyboard has two sets of note keys; any of these means the WASD set.
const WASD_KEYS: Array[Key] = [KEY_W, KEY_A, KEY_S, KEY_D]
## Substrings of joypad names that mean a PlayStation layout. Lower-case.
const PLAYSTATION_NAME_FRAGMENTS: Array[String] = [
	"ps3", "ps4", "ps5", "playstation", "dualsense", "dualshock", "sony",
]
## A DualShock 4 on Windows reports exactly this and nothing more - but "Xbox
## Wireless Controller" contains it, so it must be an exact match.
const PLAYSTATION_EXACT_NAMES: Array[String] = ["wireless controller"]

## While true, no press reaches Ivo and every axis reads 0. Disabling the node keeps `_input` off; re-enabling resyncs.
var blocked: bool = false:
	set(value):
		blocked = value
		process_mode = Node.PROCESS_MODE_DISABLED if value else Node.PROCESS_MODE_INHERIT

## Whether down was held as of the last event about it - any motion on its
## axis says, either way, so the opposite direction lets go of it too.
var _down_held: bool = false
## Whether jump was held as of the last event about it, so a release missed while paused still cuts.
var _jump_held: bool = false

# Camera-peek intent, deliberately player-only: enemies have no camera, so
# this stays an inline getter on PlayerInput rather than moving to the base.
var look_direction: float:
	get: return 0.0 if blocked else Input.get_axis("look_up", "look_down")

## Which icons `event` should be drawn with. Pure so it can be tested with a
## constructed event and a made-up joypad name; `_input` supplies the real
## name from Input.
static func glyph_set_for(event: InputEvent, joy_name: String) -> Enums.GlyphSet:
	# A stick is the pad as much as a button is.
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		return Enums.GlyphSet.PLAYSTATION if is_playstation_name(joy_name) else Enums.GlyphSet.XBOX
	if event is InputEventKey and WASD_KEYS.has((event as InputEventKey).physical_keycode):
		return Enums.GlyphSet.KEYBOARD_WASD
	return Enums.GlyphSet.KEYBOARD_ARROWS

static func is_playstation_name(joy_name: String) -> bool:
	var lowered := joy_name.to_lower().strip_edges()
	if PLAYSTATION_EXACT_NAMES.has(lowered):
		return true
	for fragment: String in PLAYSTATION_NAME_FRAGMENTS:
		if lowered.contains(fragment):
			return true
	return false

# A paused or disabled node receives no events, so held state is re-read when it runs again.
# See docs/knowledge/bugs/player-input-edge-state-goes-stale-across-a-pause-menu.md.
func _notification(what: int) -> void:
	if what == NOTIFICATION_UNPAUSED or what == NOTIFICATION_ENABLED:
		resync(Input.is_action_pressed("jump"), Input.is_action_pressed("look_down"))

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		_jump_held = true
		jump_pressed.emit()
	elif event.is_action_released("jump"):
		_jump_held = false
		jump_canceled.emit()
	if event.is_action_pressed("roll"):
		roll_pressed.emit()
	if event.is_action_pressed("attack"):
		attack_pressed.emit()
	if event.is_action_pressed("draw_memorina"):
		draw_memorina_pressed.emit()
	# Use the press edge because analog sticks report pressed on every motion past the deadzone.
	if event.is_action("look_down"):
		var held := event.is_action_pressed("look_down")
		if held and not _down_held:
			look_down_pressed.emit()
		_down_held = held
	if OS.is_debug_build() and event.is_action_pressed("debug_learn_song"):
		debug_learn_song_pressed.emit()
	# MemorinaComponent decides whether notes are accepted while the instrument is sheathed.
	for action: StringName in NOTE_ACTIONS:
		if event.is_action_pressed(action):
			note_pressed.emit(NOTE_ACTIONS[action], glyph_set_for(event, Input.get_joy_name(event.device)))

## Adopts the held state the events missed: a jump released meanwhile is cut, and down is not a new edge.
func resync(jump_held: bool, down_held: bool) -> void:
	if _jump_held and not jump_held:
		jump_canceled.emit()
	_jump_held = jump_held
	_down_held = down_held

func _get_direction() -> float:
	return 0.0 if blocked else Input.get_axis("move_left", "move_right")
