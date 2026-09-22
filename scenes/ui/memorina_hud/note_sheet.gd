class_name NoteSheet extends Control

## The staff: six slots across the frame's lines, each showing the button a
## note was pressed with, on the line of its pitch. Knows geometry and
## textures and nothing about songs - it draws what it is handed.
##
## Geometry is authored in the pixels of memorina_hud.png (128x64) and scaled
## by however large the frame is actually drawn, so the frame's size in the
## scene is the only place that decides 1x or 2x. Icons have their own scale:
## at the frame's 2x they crowd the staff, at 1x they vanish.

## The glyph PNGs' native size.
const ICON_SIZE := 16.0

## The source sheet, which every constant below is measured in.
const SOURCE_WIDTH := 128.0
## Where the staff lines begin and end in the source.
const STAFF_LEFT := 48.0
const STAFF_RIGHT := 114.0
## The staff line each pitch sits on: G4 on top, then E4, D4, C4 at the
## bottom (source lines y 23, 32, 37, 41; line 27 carries no note).
const LINE_Y: Dictionary[Enums.Note, float] = {
	Enums.Note.UP: 23.0,
	Enums.Note.RIGHT: 32.0,
	Enums.Note.LEFT: 37.0,
	Enums.Note.DOWN: 41.0,
}
const FLASH_COLOR := Color(0.85, 0.4, 0.4)
const FLASH_TIME := 0.25
const POP_SCALE := 1.3
const POP_TIME := 0.18

## How large the glyphs are drawn, in multiples of their 16px art. Non-integer
## values draw uneven pixels; 1.5 was judged the best trade against legibility.
@export_range(1.0, 2.0, 0.25) var icon_scale: float = 1.5

var _slots: Array[TextureRect] = []
## What each filled slot shows, so light() can fetch the lit texture.
var _notes: Array[Enums.Note] = []
var _glyphs: Array[NoteGlyphSet] = []
var _flash_tween: Tween

func _ready() -> void:
	for i: int in Song.NOTE_COUNT:
		var slot := TextureRect.new()
		slot.stretch_mode = TextureRect.STRETCH_SCALE
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.hide()
		add_child(slot)
		_slots.append(slot)
	resized.connect(_layout)
	_layout()

## Draws `note` in the next free slot. A seventh note is ignored: the sheet is
## exactly one song long.
func push_note(note: Enums.Note, glyphs: NoteGlyphSet) -> void:
	var index := _notes.size()
	if index >= _slots.size():
		return
	_notes.append(note)
	_glyphs.append(glyphs)
	_show(index, false)

## Fills the sheet at once, unlit: the whole song for a lesson, or only the
## first `count` notes of a guardian's fragmented call. Negative means all.
func show_notes(notes: Array[Enums.Note], glyphs: NoteGlyphSet, count: int = -1) -> void:
	clear()
	var shown := notes.size() if count < 0 else mini(count, notes.size())
	for i: int in shown:
		push_note(notes[i], glyphs)

## Swaps the slot at `index` to its lit texture.
func light(index: int) -> void:
	if index < _notes.size():
		_show(index, true)

## A beat on the slot at `index`: it swells and settles, for a note that has
## just sounded or just landed.
func pop(index: int) -> void:
	if index >= _notes.size():
		return
	var slot := _slots[index]
	slot.pivot_offset = slot.size / 2.0
	slot.scale = Vector2.ONE * POP_SCALE
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(slot, "scale", Vector2.ONE, POP_TIME)

## Puts every slot back to its unlit texture, keeping the notes.
func dim_all() -> void:
	for i: int in _notes.size():
		_show(i, false)

## The failure blink: the sheet tints and settles back, notes left in place
## for the caller to clear when the mistake has been heard.
func flash() -> void:
	if _flash_tween != null:
		_flash_tween.kill()
	modulate = FLASH_COLOR
	_flash_tween = create_tween()
	_flash_tween.tween_property(self, "modulate", Color.WHITE, FLASH_TIME)

func clear() -> void:
	_notes.clear()
	_glyphs.clear()
	for slot: TextureRect in _slots:
		slot.hide()

func _show(index: int, lit: bool) -> void:
	var note := _notes[index]
	var slot := _slots[index]
	slot.texture = _glyphs[index].texture(note, lit)
	slot.position.y = _slot_y(note)
	slot.show()

## Places and sizes every slot for the frame's current size; re-run whenever
## it changes.
func _layout() -> void:
	var icon := roundf(ICON_SIZE * icon_scale)
	for i: int in _slots.size():
		_slots[i].size = Vector2(icon, icon)
		_slots[i].position.x = _slot_x(i)
	for i: int in _notes.size():
		_slots[i].position.y = _slot_y(_notes[i])

## Slots are spread evenly across the staff, centred in their columns.
func _slot_x(index: int) -> float:
	var column_width := (STAFF_RIGHT - STAFF_LEFT) / Song.NOTE_COUNT
	return roundf(_to_frame(STAFF_LEFT + (index + 0.5) * column_width) - ICON_SIZE * icon_scale / 2.0)

## Centred on the pitch's staff line.
func _slot_y(note: Enums.Note) -> float:
	return roundf(_to_frame(LINE_Y[note]) - ICON_SIZE * icon_scale / 2.0)

## Source pixel -> frame pixel, by how much larger than the sheet the frame is.
## Rounded so an icon never lands between pixels.
func _to_frame(source_px: float) -> float:
	return roundf(source_px * size.x / SOURCE_WIDTH)
