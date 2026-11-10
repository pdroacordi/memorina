class_name NoteGlyphs extends Resource

## The note glyph each bound input is drawn with, and the blank note key for an input that has none; built by
## tools/ui/build_note_glyphs.gd from assets/sprites/hud/memorina/ (systems/settings).

const DEFAULT_PATH := "res://resources/ui/memorina/note_glyphs.tres"
const NOTE_ACTIONS: Dictionary[Enums.Note, StringName] = {
	Enums.Note.UP: &"note_up",
	Enums.Note.DOWN: &"note_down",
	Enums.Note.LEFT: &"note_left",
	Enums.Note.RIGHT: &"note_right",
}

## By physical keycode: the arrows and W A S D.
@export var keys: Dictionary[int, ButtonGlyph] = {}
## By JoyButton, per pad family: the four face buttons.
@export var xbox_buttons: Dictionary[int, ButtonGlyph] = {}
@export var playstation_buttons: Dictionary[int, ButtonGlyph] = {}
## A note key with no symbol; the HUD writes the binding's name on it.
@export var blank: ButtonGlyph


## The glyph of `note`'s binding on a `glyph_set` device, or null when the art has none.
func glyph_for(note: Enums.Note, glyph_set: Enums.GlyphSet) -> ButtonGlyph:
	var event := PlayerInput.binding_for(NOTE_ACTIONS[note], glyph_set)
	if event is InputEventKey:
		return keys.get(KeyBindings.code_of(event, KeyBindings.Device.KEYBOARD))
	if event is InputEventJoypadButton:
		var family := playstation_buttons if glyph_set == Enums.GlyphSet.PLAYSTATION else xbox_buttons
		return family.get((event as InputEventJoypadButton).button_index)
	return null

func texture(note: Enums.Note, glyph_set: Enums.GlyphSet, lit: bool) -> Texture2D:
	var glyph := glyph_for(note, glyph_set)
	if glyph == null:
		glyph = blank
	return glyph.selected if lit else glyph.normal

## The binding's name for the blank key; empty while a glyph draws it.
func label(note: Enums.Note, glyph_set: Enums.GlyphSet) -> String:
	if glyph_for(note, glyph_set) != null:
		return ""
	return BindingNames.event_text(PlayerInput.binding_for(NOTE_ACTIONS[note], glyph_set), glyph_set)
