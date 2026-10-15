class_name PhraseSheet
extends Control
## The staff a story beat plays on (the guitar, systems/story): the phrase dimmed in the encounter slot, each note lit
## as it sounds. Fed by the dialogue director's relays; pausable, so a hold stops its pops.

@export var glyph_sets: Array[NoteGlyphSet] = []

@onready var _frame: TextureRect = $Frame
@onready var _sheet: NoteSheet = $Frame/NoteSheet


func _ready() -> void:
	hide()

func show_phrase(notes: Array[Enums.Note], count: int, glyph_set: Enums.GlyphSet) -> void:
	show()
	_frame.position = Vector2(_sheet.encounter_x(size.x, 0, 0.0), _sheet.encounter_y())
	_sheet.show_notes(notes, glyph_sets[glyph_set], count)

func light(index: int) -> void:
	_sheet.light(index)
	_sheet.pop(index)

func close() -> void:
	_sheet.clear()
	hide()

## The notes shown, dimmed or lit; read by tests.
func sheet() -> NoteSheet:
	return _sheet
