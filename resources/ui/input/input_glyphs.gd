class_name InputGlyphs extends Resource

## How every binding is drawn on screen, keyed by what the binding IS - a
## keyboard key, a pad button, a direction of the left stick - so a prompt
## finds its glyph from an action's event and the player's device, and no
## script names a glyph PNG. Built by tools/ui/build_input_glyphs.gd from
## assets/sprites/hud/input/ (Franuka's RPG UI pack).

## By physical keycode.
@export var keys: Dictionary[int, ButtonGlyph] = {}
## By JoyButton, for buttons every pad draws alike: the D-pad.
@export var pad_buttons: Dictionary[int, ButtonGlyph] = {}
## By JoyButton, where the families differ: face buttons, shoulders.
@export var xbox_buttons: Dictionary[int, ButtonGlyph] = {}
@export var playstation_buttons: Dictionary[int, ButtonGlyph] = {}
## By stick_key(axis, value): the left stick pushed one way.
@export var left_stick: Dictionary[int, ButtonGlyph] = {}


## The left stick's direction as one key: axis 0 left/right is 0/1, axis 1
## up/down is 2/3.
static func stick_key(axis: int, value: float) -> int:
	return axis * 2 + (1 if value > 0.0 else 0)

## The glyph `event` is drawn with on a `glyph_set` device, or null when the
## art has none (a key without a symbol of its own: the prompt writes its name
## on a blank key instead).
func glyph_for(event: InputEvent, glyph_set: Enums.GlyphSet) -> ButtonGlyph:
	if event is InputEventKey:
		return keys.get((event as InputEventKey).physical_keycode)
	if event is InputEventJoypadButton:
		var button := (event as InputEventJoypadButton).button_index
		if pad_buttons.has(button):
			return pad_buttons[button]
		var family := playstation_buttons if glyph_set == Enums.GlyphSet.PLAYSTATION else xbox_buttons
		return family.get(button)
	if event is InputEventJoypadMotion:
		var motion := event as InputEventJoypadMotion
		return left_stick.get(stick_key(motion.axis, motion.axis_value))
	return null
