class_name PhraseSheetTest extends GdUnitTestSuite

## The phrase sheet shows a phrase's first notes dimmed, eight columns wide, lights them one by one and closes empty.

const SHEET := preload("res://scenes/ui/phrase_sheet/phrase_sheet.tscn")
const MORNING := preload("res://resources/story/morning_song.tres")

var _sheet: PhraseSheet


func before_test() -> void:
	_sheet = auto_free(SHEET.instantiate()) as PhraseSheet
	add_child(_sheet)

func _shown_slots() -> int:
	var count := 0
	for child: Node in _sheet.sheet().get_children():
		if (child as Control).visible:
			count += 1
	return count

func test_it_starts_hidden_with_eight_columns() -> void:
	assert_bool(_sheet.visible).is_false()
	assert_int(_sheet.sheet().get_child_count()).is_equal(8)

func test_it_shows_the_notes_up_to_the_gap_and_lights_them() -> void:
	var notes: Array[Enums.Note] = []
	notes.assign(MORNING.notes)
	_sheet.show_phrase(notes, 5, Enums.GlyphSet.KEYBOARD_ARROWS)
	assert_bool(_sheet.visible).is_true()
	assert_int(_shown_slots()).is_equal(5)
	var slot := _sheet.sheet().get_child(0) as TextureRect
	var dim := slot.texture
	_sheet.light(0)
	assert_object(slot.texture).is_not_same(dim)
	_sheet.close()
	assert_bool(_sheet.visible).is_false()
	assert_int(_shown_slots()).is_equal(0)
