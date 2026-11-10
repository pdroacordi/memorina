class_name NoteGlyph extends TextureRect

## One note slot: the note's glyph for the device, or the blank note key with the binding's name on it.

const FONT := preload("res://assets/fonts/memorina_text_font_size_8.ttf")
const INK := Color(0.96, 0.9, 0.72, 1)
const OUTLINE := Color(0.13, 0.08, 0.05, 1)

var _label: Label


func _init() -> void:
	_label = Label.new()
	_label.name = "Name"
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_override(&"font", FONT)
	_label.add_theme_font_size_override(&"font_size", 8)
	_label.add_theme_color_override(&"font_color", INK)
	_label.add_theme_color_override(&"font_outline_color", OUTLINE)
	_label.add_theme_constant_override(&"outline_size", 2)
	_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_label, false, Node.INTERNAL_MODE_FRONT)

func show_note(glyphs: NoteGlyphs, note: Enums.Note, glyph_set: Enums.GlyphSet, lit: bool) -> void:
	texture = glyphs.texture(note, glyph_set, lit)
	_label.text = glyphs.label(note, glyph_set)

## A texture with no name: a half-known song's blank note.
func show_texture(shown: Texture2D) -> void:
	texture = shown
	_label.text = ""

## The binding's name on the blank key; empty while a glyph draws it.
func label_text() -> String:
	return _label.text
