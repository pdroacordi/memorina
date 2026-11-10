class_name NoteSheetTest extends GdUnitTestSuite

## A half-known song's unknown notes are drawn as blanks on the staff's middle (architecture/half-songs), and a note
## whose input has no glyph is the blank note key with the binding's name (systems/settings).

const ARROWS := Enums.GlyphSet.KEYBOARD_ARROWS
const BLANK := preload("res://assets/sprites/hud/memorina/note_blank.png")

func test_a_mask_draws_blanks() -> void:
	var sheet := auto_free(NoteSheet.new()) as NoteSheet
	sheet.blank_texture = BLANK
	sheet.size = Vector2(256, 128)
	add_child(sheet)
	var notes: Array[Enums.Note] = [Enums.Note.UP, Enums.Note.DOWN, Enums.Note.UP, Enums.Note.DOWN, Enums.Note.UP, Enums.Note.DOWN]
	sheet.show_notes(notes, ARROWS, -1, [true, true, true, false, false, false])
	var slots := sheet.get_children()
	assert_object((slots[0] as TextureRect).texture).is_same(sheet.glyphs.texture(Enums.Note.UP, ARROWS, false))
	assert_object((slots[3] as TextureRect).texture).is_same(BLANK)
	assert_float((slots[3] as TextureRect).position.y).is_equal((slots[5] as TextureRect).position.y)
	sheet.light(4)
	assert_object((slots[4] as TextureRect).texture).is_same(BLANK)

func after_test() -> void:
	Settings.reset_bindings(KeyBindings.Device.KEYBOARD)

## A note rebound to Q has no glyph: the slot shows the blank key named Q, and a rebinding redraws a shown slot.
func test_a_note_without_a_glyph_is_the_named_blank_key() -> void:
	var sheet := auto_free(NoteSheet.new()) as NoteSheet
	sheet.size = Vector2(256, 128)
	add_child(sheet)
	var notes: Array[Enums.Note] = [Enums.Note.UP]
	sheet.show_notes(notes, Enums.GlyphSet.KEYBOARD_WASD)
	assert_str(sheet.label_at(0)).is_empty()
	Settings.bind(KeyBindings.Device.KEYBOARD, &"note_up", KEY_Q)
	var slot := sheet.get_child(0) as TextureRect
	assert_object(slot.texture).is_same(sheet.glyphs.blank.normal)
	assert_str(sheet.label_at(0)).is_equal(BindingNames.key_text(KEY_Q))
