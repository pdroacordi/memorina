class_name NoteSheetTest extends GdUnitTestSuite

## A half-known song's unknown notes are drawn as blanks on the staff's middle (architecture/half-songs).

const ARROWS := preload("res://resources/ui/memorina/glyphs_keyboard_arrows.tres")
const BLANK := preload("res://assets/sprites/hud/memorina/note_blank.png")

func test_a_mask_draws_blanks() -> void:
	var sheet := auto_free(NoteSheet.new()) as NoteSheet
	sheet.blank_texture = BLANK
	sheet.size = Vector2(256, 128)
	add_child(sheet)
	var notes: Array[Enums.Note] = [Enums.Note.UP, Enums.Note.DOWN, Enums.Note.UP, Enums.Note.DOWN, Enums.Note.UP, Enums.Note.DOWN]
	sheet.show_notes(notes, ARROWS, -1, [true, true, true, false, false, false])
	var slots := sheet.get_children()
	assert_object((slots[0] as TextureRect).texture).is_same(ARROWS.texture(Enums.Note.UP, false))
	assert_object((slots[3] as TextureRect).texture).is_same(BLANK)
	assert_float((slots[3] as TextureRect).position.y).is_equal((slots[5] as TextureRect).position.y)
	sheet.light(4)
	assert_object((slots[4] as TextureRect).texture).is_same(BLANK)
