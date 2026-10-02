extends Node

## Which device the player is holding - the keyboard, an Xbox-style pad or a
## PlayStation one - as the Enums.GlyphSet every prompt draws with, so a key
## on screen is always the one under the player's hand.
##
## An autoload because it is genuinely global: prompts live in the world (a
## bench), on the HUD and, one day, in menus, and none of them belongs to Ivo.
## Thin on purpose: the judgement of which set an event means is
## PlayerInput.glyph_set_for (pure, tested); this only remembers the last one.

## The player picked up another device (or moved from the arrows to WASD).
## Discrete: emitted on the switch, never per frame.
signal device_changed(glyph_set: Enums.GlyphSet)

## A stick must be pushed this far before it counts as picking the pad up, so
## a resting stick's drift never flips the prompts away from the keyboard.
const STICK_THRESHOLD := 0.5

var glyph_set: Enums.GlyphSet = Enums.GlyphSet.KEYBOARD_ARROWS


func _input(event: InputEvent) -> void:
	if not _is_deliberate(event):
		return
	var found := PlayerInput.glyph_set_for(event, Input.get_joy_name(event.device))
	if found == glyph_set:
		return
	glyph_set = found
	device_changed.emit(glyph_set)

func is_pad() -> bool:
	return glyph_set in [Enums.GlyphSet.XBOX, Enums.GlyphSet.PLAYSTATION]

## The binding of `action` the player's device would press: on the keyboard
## the key of the set under the hand (S rather than the down arrow for a WASD
## player, where the action has both), else its first key; on a pad its
## button, or else its stick. Null when the device has no binding for it.
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
