class_name NoteSheet extends Control

## Draws a song's notes on the HUD staff.

const ICON_SIZE := 16.0

const SOURCE_WIDTH := 128.0
const STAFF_LEFT := 48.0
const STAFF_RIGHT := 114.0
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

## Glyph scale in multiples of 16px art; controls note legibility.
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

func push_note(note: Enums.Note, glyphs: NoteGlyphSet) -> void:
	var index := _notes.size()
	if index >= _slots.size():
		return
	_notes.append(note)
	_glyphs.append(glyphs)
	_show(index, false)

func show_notes(notes: Array[Enums.Note], glyphs: NoteGlyphSet, count: int = -1) -> void:
	clear()
	var shown := notes.size() if count < 0 else mini(count, notes.size())
	for i: int in shown:
		push_note(notes[i], glyphs)

func light(index: int) -> void:
	if index < _notes.size():
		_show(index, true)

func pop(index: int) -> void:
	if index >= _notes.size():
		return
	var slot := _slots[index]
	slot.pivot_offset = slot.size / 2.0
	slot.scale = Vector2.ONE * POP_SCALE
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(slot, "scale", Vector2.ONE, POP_TIME)

func dim_all() -> void:
	for i: int in _notes.size():
		_show(i, false)

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

## The frame-pixel x coordinate at the staff's center.
func staff_center() -> float:
	return _to_frame((STAFF_LEFT + STAFF_RIGHT) / 2.0)

const CENTRE_CLEARANCE := 140.0
const SIDE_MARGIN := 24.0
const ENCOUNTER_TOP := 40.0

## Keeps the sheet at one position for an encounter so it does not jump between turns.
func encounter_x(screen_width: float, guardian_side: int, guardian_height: float) -> float:
	if guardian_height <= CENTRE_CLEARANCE:
		return roundf(screen_width / 2.0 - staff_center())
	return SIDE_MARGIN if guardian_side > 0 else roundf(screen_width - size.x - SIDE_MARGIN)

func encounter_y() -> float:
	return ENCOUNTER_TOP

func _layout() -> void:
	var icon := roundf(ICON_SIZE * icon_scale)
	for i: int in _slots.size():
		_slots[i].size = Vector2(icon, icon)
		_slots[i].position.x = _slot_x(i)
	for i: int in _notes.size():
		_slots[i].position.y = _slot_y(_notes[i])

func _slot_x(index: int) -> float:
	var column_width := (STAFF_RIGHT - STAFF_LEFT) / Song.NOTE_COUNT
	return roundf(_to_frame(STAFF_LEFT + (index + 0.5) * column_width) - ICON_SIZE * icon_scale / 2.0)

func _slot_y(note: Enums.Note) -> float:
	return roundf(_to_frame(LINE_Y[note]) - ICON_SIZE * icon_scale / 2.0)

func _to_frame(source_px: float) -> float:
	return roundf(source_px * size.x / SOURCE_WIDTH)
