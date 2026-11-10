class_name KeyBindings
extends RefCounted
## One device's managed input per rebindable action as plain ints (a physical keycode or a JoyButton), beside the
## fixed inputs the rules check it against (systems/settings).

enum Device { KEYBOARD, PAD }

const REBINDABLE: Array[StringName] = [
	&"jump", &"attack", &"roll", &"draw_memorina",
	&"note_up", &"note_down", &"note_left", &"note_right",
	&"map", &"notebook",
]
const NOTE_ACTIONS: Array[StringName] = [&"note_up", &"note_down", &"note_left", &"note_right"]
## Fixed actions a rebindable action may share an input with.
const ACCEPT := &"ui_accept"
const CANCEL := &"ui_cancel"
## Fixed actions whose inputs can never be bound.
const RESERVED_ACTIONS: Array[StringName] = [
	&"pause", &"move_left", &"move_right", &"look_up", &"look_down",
	&"debug_learn_song", &"debug_learn_song_half", &"debug_trials",
]
## A note keeps the arrows beside its managed key: they are move and look too.
const ARROW_KEYS: Array[int] = [KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT]
## The only pad buttons a binding may take; Guide, Start, the D-pad, the misc and paddle buttons are refused.
const PAD_BUTTONS: Array[int] = [
	JOY_BUTTON_A, JOY_BUTTON_B, JOY_BUTTON_X, JOY_BUTTON_Y, JOY_BUTTON_BACK,
	JOY_BUTTON_LEFT_STICK, JOY_BUTTON_RIGHT_STICK, JOY_BUTTON_LEFT_SHOULDER, JOY_BUTTON_RIGHT_SHOULDER,
]
const NONE := -1
## The device id of an action event that answers every device.
const ALL_DEVICES := -1

var device: Device = Device.KEYBOARD
## Action -> code; an action missing here has no managed input.
var codes: Dictionary[StringName, int] = {}
## Codes of `ui_accept` and `ui_cancel` on this device.
var accept: Array[int] = []
var cancel: Array[int] = []
## Codes of the reserved actions on this device.
var reserved: Array[int] = []


func _init(for_device: Device = Device.KEYBOARD) -> void:
	device = for_device

## Today's InputMap as one device's table; Settings captures it once at boot, before any override.
static func from_input_map(for_device: Device) -> KeyBindings:
	var table := KeyBindings.new(for_device)
	for action: StringName in REBINDABLE:
		var found := managed_code(action, for_device)
		if found != NONE:
			table.codes[action] = found
	table.accept = _codes_of(ACCEPT, for_device)
	table.cancel = _codes_of(CANCEL, for_device)
	for action: StringName in RESERVED_ACTIONS:
		table.reserved.append_array(_codes_of(action, for_device))
	return table

## The code of `action`'s managed event on `for_device`, or NONE: its first key that is not an arrow, or its first
## pad button.
static func managed_code(action: StringName, for_device: Device) -> int:
	if not InputMap.has_action(action):
		return NONE
	for event: InputEvent in InputMap.action_get_events(action):
		var found := code_of(event, for_device)
		if found != NONE and not (for_device == Device.KEYBOARD and ARROW_KEYS.has(found)):
			return found
	return NONE

## `event`'s code on `for_device`, or NONE when the event belongs to another device. A key without a physical
## keycode answers its keycode.
static func code_of(event: InputEvent, for_device: Device) -> int:
	if for_device == Device.KEYBOARD and event is InputEventKey:
		var key := event as InputEventKey
		return key.physical_keycode if key.physical_keycode != KEY_NONE else key.keycode
	if for_device == Device.PAD and event is InputEventJoypadButton:
		return (event as InputEventJoypadButton).button_index
	return NONE

## A new event that `for_device` reads as `code`, for every device as the project's events are
## (gotchas/a-new-inputevent-is-not-for-all-devices).
static func event_for(code: int, for_device: Device) -> InputEvent:
	var event: InputEvent
	if for_device == Device.KEYBOARD:
		var key := InputEventKey.new()
		key.physical_keycode = code as Key
		event = key
	else:
		var button := InputEventJoypadButton.new()
		button.button_index = code as JoyButton
		event = button
	event.device = ALL_DEVICES
	return event

func code(action: StringName) -> int:
	return codes.get(action, NONE)

## The rebindable actions holding `code`, in REBINDABLE order.
func holders(of_code: int) -> Array[StringName]:
	var found: Array[StringName] = []
	for action: StringName in REBINDABLE:
		if codes.get(action, NONE) == of_code:
			found.append(action)
	return found

## The fixed actions holding `code`: ui_accept, then ui_cancel.
func fixed_holders(of_code: int) -> Array[StringName]:
	var found: Array[StringName] = []
	if accept.has(of_code):
		found.append(ACCEPT)
	if cancel.has(of_code):
		found.append(CANCEL)
	return found

func copy() -> KeyBindings:
	var made := KeyBindings.new(device)
	made.codes = codes.duplicate()
	made.accept = accept.duplicate()
	made.cancel = cancel.duplicate()
	made.reserved = reserved.duplicate()
	return made

func equals(other: KeyBindings) -> bool:
	return other != null and other.device == device and other.codes == codes

static func _codes_of(action: StringName, for_device: Device) -> Array[int]:
	var found: Array[int] = []
	if not InputMap.has_action(action):
		return found
	for event: InputEvent in InputMap.action_get_events(action):
		var code := code_of(event, for_device)
		if code != NONE and not found.has(code):
			found.append(code)
	return found
