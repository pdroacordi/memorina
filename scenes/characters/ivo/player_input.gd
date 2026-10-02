class_name PlayerInput
extends CharacterController
## Translates raw hardware input into player intent.
## Continuous state is exposed as read-only properties; discrete actions are
## signals inherited from CharacterController (see that class for the rule).
##
## The only node that knows what an InputEvent is. That includes WHICH keys a
## note was played with: the sheet draws the button actually under the thumb,
## so a note travels with its Enums.GlyphSet, derived here and nowhere else.

signal attack_pressed
signal jump_pressed
signal jump_canceled
signal roll_pressed
signal draw_memorina_pressed
## Down was pressed - the gesture that sits Ivo on a bench. The held axis is
## still look_direction; this is the press.
signal look_down_pressed
signal note_pressed(note: Enums.Note, glyph_set: Enums.GlyphSet)
## Debug builds only: teaches the next unknown song. Stands in for the guardian
## fights until they exist.
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

## Whether down was held as of the last event about it - any motion on its
## axis says, either way, so the opposite direction lets go of it too.
var _down_held: bool = false

# Camera-peek intent, deliberately player-only: enemies have no camera, so
# this stays an inline getter on PlayerInput rather than moving to the base.
var look_direction: float:
	get: return Input.get_axis("look_up", "look_down")

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

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		jump_pressed.emit()
	elif event.is_action_released("jump"):
		jump_canceled.emit()
	if event.is_action_pressed("roll"):
		roll_pressed.emit()
	if event.is_action_pressed("attack"):
		attack_pressed.emit()
	if event.is_action_pressed("draw_memorina"):
		draw_memorina_pressed.emit()
	# The press is the EDGE, not the event: a stick reports "pressed" on every
	# motion past its deadzone, so a held, wiggling stick would sit Ivo down
	# again the moment anything stood him up.
	if event.is_action("look_down"):
		var held := event.is_action_pressed("look_down")
		if held and not _down_held:
			look_down_pressed.emit()
		_down_held = held
	if OS.is_debug_build() and event.is_action_pressed("debug_learn_song"):
		debug_learn_song_pressed.emit()
	# Deliberately unconditional: this node reports what the hardware did and
	# never asks whether the instrument happens to be out. Notes arriving while
	# it is sheathed are dropped by MemorinaComponent, which is the node that
	# actually knows.
	for action: StringName in NOTE_ACTIONS:
		if event.is_action_pressed(action):
			note_pressed.emit(NOTE_ACTIONS[action], glyph_set_for(event, Input.get_joy_name(event.device)))

func _get_direction() -> float:
	return Input.get_axis("move_left", "move_right")
