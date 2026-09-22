class_name GuardianCallHud extends Control

## The guardian's side of the call-and-response, on screen: a sheet that
## slides down from the top into the encounter's slot - centred, above the
## pair the camera is holding - tinted in its season, asking the player to
## listen while the phrase sounds, its revealed notes lighting and popping one
## by one, with one pip per answer the cure needs under the message, the ones
## already given lit. When the phrase is over it slides away and Ivo's own
## sheet (MemorinaHud) takes THE SAME SLOT: the turn passes without the sheet
## moving an inch. Where that slot IS belongs to NoteSheet - both HUDs ask it
## for the x and the y - not to a number typed into each of them. An observer
## of Player's signals (wired in game.tscn) that decides nothing.
##
## The Label is given a translation KEY (a Label auto-translates its text).

const LISTEN_KEY := "GUARDIAN_CALL_LISTEN"
const SLIDE_TIME := 0.35

## Indexed by Enums.GlyphSet, same resources as MemorinaHud's.
@export var glyph_sets: Array[NoteGlyphSet] = []
var _slide_tween: Tween
## The stage: which side the guardian stands on and how tall it is.
var _guardian_side: int = 1
var _guardian_height: float = 0.0

@onready var _frame: TextureRect = $Frame
@onready var _sheet: NoteSheet = $Frame/NoteSheet
@onready var _message: Label = $Frame/Message
@onready var _pips: CurePips = $Frame/CurePips

func _ready() -> void:
	assert(glyph_sets.size() == Enums.GlyphSet.size(),
		"GuardianCallHud has %d glyph sets for %d members of Enums.GlyphSet." % [glyph_sets.size(), Enums.GlyphSet.size()])
	_message.text = LISTEN_KEY
	hide()

## The guardian starts calling: the sheet slides into the slot wearing its
## season's colour, the notes it is willing to show unlit, the cure's pips
## under the ask to listen.
func on_call_opened(song: Song, revealed: int, glyph_set: Enums.GlyphSet, cure_done: int, cure_total: int, side: int, caller_height: float) -> void:
	_guardian_side = side
	_guardian_height = caller_height
	_frame.modulate = song.tint().lerp(Color.WHITE, 0.45)
	_sheet.modulate = Color.WHITE
	_sheet.show_notes(song.notes, glyph_sets[glyph_set], revealed)
	_pips.show_cure(cure_done, cure_total, song.tint())
	modulate = Color.WHITE
	show()
	_slide(true)

func on_call_note_sounded(index: int) -> void:
	_sheet.light(index)
	_sheet.pop(index)

## The phrase is over: the sheet goes, and Ivo's takes over.
func on_call_window_opened() -> void:
	_slide(false)

## The guardian was interrupted before its phrase was heard out.
func on_call_closed() -> void:
	if visible:
		_slide(false)

## In: from above the screen's edge down into the slot. Out: back up, then
## hidden - and Ivo's sheet appears in the same place.
func _slide(in_: bool) -> void:
	if _slide_tween != null:
		_slide_tween.kill()
	var x := _sheet.encounter_x(size.x, _guardian_side, _guardian_height)
	var hidden_y := -_frame.size.y - 4.0
	if in_:
		_frame.position = Vector2(x, hidden_y)
	_slide_tween = create_tween().set_trans(Tween.TRANS_CUBIC) \
		.set_ease(Tween.EASE_OUT if in_ else Tween.EASE_IN)
	_slide_tween.tween_property(_frame, "position", Vector2(x, _sheet.encounter_y() if in_ else hidden_y), SLIDE_TIME)
	if not in_:
		_slide_tween.tween_callback(hide)
