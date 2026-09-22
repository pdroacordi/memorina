class_name GuardianCallHud extends Control

## The guardian's side of the call-and-response, on screen: a sheet that
## slides down from the top, tinted in the guardian's season, and says what
## is happening and what to do - "Listen" while the phrase sounds (its
## revealed notes lighting and popping one by one), then "Answer on the
## Memorina" with the time draining under the staff, the notes lighting
## again as the answer gets each one right. Under the message, one pip per
## answer the cure needs, the ones already given lit: the fight's progress
## without a number. Green linger on success (the next pip filling), red on
## any failure, then the sheet slides away. While a guardian is staged this
## is the only sheet on screen: Ivo's answer is read here, not beside him.
## An observer of Player's signals (wired in game.tscn) that decides nothing.
##
## Both Labels are given translation KEYS (a Label auto-translates its text).

const LISTEN_KEY := "GUARDIAN_CALL_LISTEN"
const ANSWER_KEY := "GUARDIAN_CALL_ANSWER"
const FAIL_COLOR := Color(1.0, 0.35, 0.3)
const SUCCESS_COLOR := Color(0.55, 1.0, 0.6)
const BAR_COLOR := Color(0.96, 0.9, 0.72)
const BAR_LOW_COLOR := Color(0.95, 0.4, 0.3)
## Seconds the sheet lingers on its verdict before going away.
const LINGER_TIME := 0.6
const SLIDE_TIME := 0.35

## Indexed by Enums.GlyphSet, same resources as MemorinaHud's.
@export var glyph_sets: Array[NoteGlyphSet] = []
## Screen y of the frame's top edge once it has slid in, and its gap from the
## screen edge on the side away from the guardian: a tall guardian's head
## reaches the top of the frame, and the sheet must not cover the one singing.
@export var frame_top: float = 12.0
@export var frame_margin: float = 16.0
## Full width of the time bar, in frame pixels, and where it starts.
@export var bar_left: float = 96.0
@export var bar_width: float = 132.0

var _window_total: float = 0.0
var _window_left: float = 0.0
var _counting: bool = false
var _linger_tween: Tween
var _slide_tween: Tween
## Which side of Ivo the guardian stands on; the sheet takes the other.
var _guardian_side: int = 1

@onready var _frame: TextureRect = $Frame
@onready var _sheet: NoteSheet = $Frame/NoteSheet
@onready var _message: Label = $Frame/Message
@onready var _bar: ColorRect = $Frame/TimeBar
@onready var _pips: CurePips = $Frame/CurePips

func _ready() -> void:
	assert(glyph_sets.size() == Enums.GlyphSet.size(),
		"GuardianCallHud has %d glyph sets for %d members of Enums.GlyphSet." % [glyph_sets.size(), Enums.GlyphSet.size()])
	_bar.hide()
	hide()

func _process(delta: float) -> void:
	if not _counting or get_tree().paused:
		return
	_window_left = maxf(_window_left - delta, 0.0)
	var fraction := _window_left / _window_total if _window_total > 0.0 else 0.0
	_bar.size.x = roundf(bar_width * fraction)
	_bar.color = BAR_COLOR.lerp(BAR_LOW_COLOR, 1.0 - fraction)

## The guardian starts calling: the sheet slides in on the side away from it,
## wearing its season's colour, the notes it is willing to show unlit, the
## cure's pips under the ask to listen.
func on_call_opened(song: Song, revealed: int, glyph_set: Enums.GlyphSet, cure_done: int, cure_total: int, side: int) -> void:
	_stop_linger()
	_guardian_side = side
	_counting = false
	_frame.modulate = song.tint().lerp(Color.WHITE, 0.45)
	_sheet.modulate = Color.WHITE
	_sheet.show_notes(song.notes, glyph_sets[glyph_set], revealed)
	_message.text = LISTEN_KEY
	_bar.hide()
	_pips.show_cure(cure_done, cure_total, song.tint())
	modulate = Color.WHITE
	show()
	_slide(true)

func on_call_note_sounded(index: int) -> void:
	_sheet.light(index)
	_sheet.pop(index)

## The phrase is over: the slots dim, the bar fills, and the ask changes.
func on_call_window_opened(seconds: float) -> void:
	_sheet.dim_all()
	_message.text = ANSWER_KEY
	_window_total = seconds
	_window_left = seconds
	_bar.position.x = bar_left
	_bar.size.x = bar_width
	_bar.color = BAR_COLOR
	_bar.show()
	_counting = true

## `count` notes of the answer are right so far: light them back up, the
## newest with a beat.
func on_call_progress(count: int) -> void:
	_sheet.dim_all()
	for i: int in count:
		_sheet.light(i)
	_sheet.pop(count - 1)

func on_call_answered(_song: Song) -> void:
	_counting = false
	_bar.hide()
	_sheet.modulate = SUCCESS_COLOR
	_pips.fill_next()
	_linger_then_hide()

## A wrong note, a hit, a step, or the time running out. Whatever the reason
## it reads the same way, as the design asks: the sheet reddens and goes.
func on_sequence_failed() -> void:
	if not visible or not _counting:
		return
	_counting = false
	_bar.hide()
	_sheet.modulate = FAIL_COLOR
	_linger_then_hide()

func on_call_closed() -> void:
	# A close that follows a verdict lets the verdict linger; any other close
	# (the guardian was interrupted before the window opened) is immediate.
	if _linger_tween != null and _linger_tween.is_valid():
		return
	_counting = false
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

func _linger_then_hide() -> void:
	_stop_linger()
	_linger_tween = create_tween()
	_linger_tween.tween_interval(LINGER_TIME)
	_linger_tween.tween_callback(_slide.bind(false))
	_linger_tween.tween_interval(SLIDE_TIME)
	_linger_tween.tween_callback(_on_linger_done)

func _on_linger_done() -> void:
	_linger_tween = null

func _stop_linger() -> void:
	if _linger_tween != null:
		_linger_tween.kill()
		_linger_tween = null
