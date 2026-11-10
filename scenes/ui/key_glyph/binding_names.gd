class_name BindingNames
extends RefCounted
## The names a binding is written with where no glyph draws it: a key by the layout's label, a pad button by a
## translation key per family. Shared by KeyGlyph, the note HUDs and the Settings rows.

const XBOX_KEYS: Dictionary[int, String] = {
	JOY_BUTTON_A: "PAD_XBOX_A", JOY_BUTTON_B: "PAD_XBOX_B", JOY_BUTTON_X: "PAD_XBOX_X", JOY_BUTTON_Y: "PAD_XBOX_Y",
	JOY_BUTTON_LEFT_SHOULDER: "PAD_XBOX_LB", JOY_BUTTON_RIGHT_SHOULDER: "PAD_XBOX_RB", JOY_BUTTON_BACK: "PAD_XBOX_VIEW",
	JOY_BUTTON_LEFT_STICK: "PAD_L3", JOY_BUTTON_RIGHT_STICK: "PAD_R3",
}
const PLAYSTATION_KEYS: Dictionary[int, String] = {
	JOY_BUTTON_A: "PAD_PS_CROSS", JOY_BUTTON_B: "PAD_PS_CIRCLE", JOY_BUTTON_X: "PAD_PS_SQUARE",
	JOY_BUTTON_Y: "PAD_PS_TRIANGLE", JOY_BUTTON_LEFT_SHOULDER: "PAD_PS_L1", JOY_BUTTON_RIGHT_SHOULDER: "PAD_PS_R1",
	JOY_BUTTON_BACK: "PAD_PS_CREATE", JOY_BUTTON_LEFT_STICK: "PAD_L3", JOY_BUTTON_RIGHT_STICK: "PAD_R3",
}


## The current layout's label for a physical keycode, as the OS writes it ("Z", "Shift", "Space"); not translated.
static func key_text(physical_keycode: int) -> String:
	# The headless display server has no layout and errors on the lookup (gotchas/headless-has-no-keyboard-layout).
	if DisplayServer.get_name() == "headless":
		return OS.get_keycode_string(physical_keycode as Key)
	var label := DisplayServer.keyboard_get_label_from_physical(physical_keycode as Key)
	return OS.get_keycode_string(label if label != KEY_NONE else physical_keycode as Key)

## The translation key of a pad button's name in `glyph_set`'s family; empty for a button the game never binds.
static func button_key(button: int, glyph_set: Enums.GlyphSet) -> String:
	var family := PLAYSTATION_KEYS if glyph_set == Enums.GlyphSet.PLAYSTATION else XBOX_KEYS
	return family.get(button, "")

## The translated name of `code` on `device`; a pad button is named in `glyph_set`'s family.
static func code_text(code: int, device: KeyBindings.Device, glyph_set: Enums.GlyphSet) -> String:
	if code == KeyBindings.NONE:
		return ""
	if device == KeyBindings.Device.KEYBOARD:
		return key_text(code)
	var key := button_key(code, glyph_set)
	return TranslationServer.translate(key) if not key.is_empty() else ""

## The name of `event` as `glyph_set`'s device shows it; empty for a stick or no event.
static func event_text(event: InputEvent, glyph_set: Enums.GlyphSet) -> String:
	if event is InputEventKey:
		return code_text(KeyBindings.code_of(event, KeyBindings.Device.KEYBOARD), KeyBindings.Device.KEYBOARD, glyph_set)
	if event is InputEventJoypadButton:
		return code_text((event as InputEventJoypadButton).button_index, KeyBindings.Device.PAD, glyph_set)
	return ""
