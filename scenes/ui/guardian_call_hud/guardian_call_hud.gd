class_name GuardianCallHud extends Control

## The guardian's side of the call-and-response, on screen: a sheet that
## slides down from the top on the side away from the guardian, tinted in its
## season, asking the player to listen while the phrase sounds - its revealed
## notes lighting and popping one by one - with one pip per answer the cure
## needs under the message, the ones already given lit. When the phrase is
## over it slides away: the ANSWER is given on Ivo's own sheet beside him
## (MemorinaHud), the one the player already knows. An observer of Player's
## signals (wired in game.tscn) that decides nothing.
##
## The Label is given a translation KEY (a Label auto-translates its text).

const LISTEN_KEY := "GUARDIAN_CALL_LISTEN"
const SLIDE_TIME := 0.35

## Indexed by Enums.GlyphSet, same resources as MemorinaHud's.
@export var glyph_sets: Array[NoteGlyphSet] = []
## Screen y of the frame's top edge once it has slid in, and its gap from the
## screen edge on the side away from the guardian: a tall guardian's head
## reaches the top of the frame, and the sheet must not cover the one singing.
@export var frame_top: float = 12.0
@export var frame_margin: float = 16.0

var _slide_tween: Tween
## Which side of Ivo the guardian stands on; the sheet takes the other.
var _guardian_side: int = 1

@onready var _frame: TextureRect = $Frame
@onready var _sheet: NoteSheet = $Frame/NoteSheet
@onready var _message: Label = $Frame/Message
@onready var _pips: CurePips = $Frame/CurePips

func _ready() -> void:
	assert(glyph_sets.size() == Enums.GlyphSet.size(),
		"GuardianCallHud has %d glyph sets for %d members of Enums.GlyphSet." % [glyph_sets.size(), Enums.GlyphSet.size()])
	_message.text = LISTEN_KEY
	hide()

## The guardian starts calling: the sheet slides in on the side away from it,
## wearing its season's colour, the notes it is willing to show unlit, the
## cure's pips under the ask to listen.
func on_call_opened(song: Song, revealed: int, glyph_set: Enums.GlyphSet, cure_done: int, cure_total: int, side: int) -> void:
	_guardian_side = side
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
func on_call_window_opened(_seconds: float) -> void:
	_slide(false)

## The guardian was interrupted before its phrase was heard out.
func on_call_closed() -> void:
	if visible:
		_slide(false)

## In: from above the screen's edge to `frame_top`. Out: back up, then hidden.
func _slide(in_: bool) -> void:
	if _slide_tween != null:
		_slide_tween.kill()
	var x := frame_margin if _guardian_side > 0 else size.x - _frame.size.x - frame_margin
	var hidden_y := -_frame.size.y - 4.0
	if in_:
		_frame.position = Vector2(x, hidden_y)
	_slide_tween = create_tween().set_trans(Tween.TRANS_CUBIC) \
		.set_ease(Tween.EASE_OUT if in_ else Tween.EASE_IN)
	_slide_tween.tween_property(_frame, "position", Vector2(x, frame_top if in_ else hidden_y), SLIDE_TIME)
	if not in_:
		_slide_tween.tween_callback(hide)
