extends Node

## Tracks the active input device for prompt glyphs; PlayerInput determines the glyph set.

## The player picked up another device (or moved from the arrows to WASD).
## Discrete: emitted on the switch, never per frame.
signal device_changed(glyph_set: Enums.GlyphSet)

## Minimum stick magnitude that switches prompts to the gamepad.
const STICK_THRESHOLD := 0.5

var glyph_set: Enums.GlyphSet = Enums.GlyphSet.KEYBOARD_ARROWS


# The window hears every event before dispatch, so a press a menu marks handled
# (Esc, Start, B) and a press made while paused still switch the prompts.
func _ready() -> void:
	get_tree().root.window_input.connect(_on_window_input)

func _on_window_input(event: InputEvent) -> void:
	if not _is_deliberate(event):
		return
	var found := PlayerInput.glyph_set_for(event, Input.get_joy_name(event.device))
	if found == glyph_set:
		return
	glyph_set = found
	device_changed.emit(glyph_set)

func is_pad() -> bool:
	return glyph_set in [Enums.GlyphSet.XBOX, Enums.GlyphSet.PLAYSTATION]

## Returns the current device's binding for `action`, or null if none exists.
func event_for(action: StringName) -> InputEvent:
	return binding_for(action, glyph_set)

## Pure over the InputMap, for tests.
static func binding_for(action: StringName, for_set: Enums.GlyphSet) -> InputEvent:
	if not InputMap.has_action(action):
		return null
	var pad := for_set in [Enums.GlyphSet.XBOX, Enums.GlyphSet.PLAYSTATION]
	var fallback: InputEvent = null
	for event: InputEvent in InputMap.action_get_events(action):
		if pad:
			if event is InputEventJoypadButton:
				return event
			if event is InputEventJoypadMotion and fallback == null:
				fallback = event
		elif event is InputEventKey:
			if PlayerInput.glyph_set_for(event, "") == for_set:
				return event
			if fallback == null:
				fallback = event
	return fallback

static func _is_deliberate(event: InputEvent) -> bool:
	if event is InputEventKey or event is InputEventJoypadButton:
		return event.is_pressed() and not event.is_echo()
	if event is InputEventJoypadMotion:
		return absf((event as InputEventJoypadMotion).axis_value) >= STICK_THRESHOLD
	return false
