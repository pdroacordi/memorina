class_name GuardianCallHud extends Control

## The guardian's side of the call-and-response, on screen: a sheet at the
## top, tinted in the guardian's season, that says what is happening and what
## to do - "Listen" while the phrase sounds (its revealed notes lighting one by
## one), then "Answer on the Memorina" with the time draining under the staff,
## the notes lighting again as the answer gets each one right. Distinct from
## MemorinaHud on purpose: that sheet beside Ivo is what HE is playing; this
## one is what the guardian asked for. An observer of Player's signals (wired
## in game.tscn) that decides nothing.
##
## Both Labels are given translation KEYS (a Label auto-translates its text).

const LISTEN_KEY := "GUARDIAN_CALL_LISTEN"
const ANSWER_KEY := "GUARDIAN_CALL_ANSWER"
const FAIL_COLOR := Color(1.0, 0.35, 0.3)
const SUCCESS_COLOR := Color(0.55, 1.0, 0.6)
## Seconds the sheet lingers on its verdict before going away.
const LINGER_TIME := 0.45

## Indexed by Enums.GlyphSet, same resources as MemorinaHud's.
@export var glyph_sets: Array[NoteGlyphSet] = []
## Screen y of the frame's top edge.
@export var frame_top: float = 12.0
## Full width of the time bar, in frame pixels, and where it starts.
@export var bar_left: float = 96.0
@export var bar_width: float = 132.0

var _window_total: float = 0.0
var _window_left: float = 0.0
var _counting: bool = false
var _linger_tween: Tween

@onready var _frame: TextureRect = $Frame
@onready var _sheet: NoteSheet = $Frame/NoteSheet
@onready var _message: Label = $Frame/Message
@onready var _bar: ColorRect = $Frame/TimeBar

func _ready() -> void:
	assert(glyph_sets.size() == Enums.GlyphSet.size(),
		"GuardianCallHud has %d glyph sets for %d members of Enums.GlyphSet." % [glyph_sets.size(), Enums.GlyphSet.size()])
	_bar.hide()
	hide()

func _process(delta: float) -> void:
	if not _counting or get_tree().paused:
		return
	_window_left = maxf(_window_left - delta, 0.0)
	_bar.size.x = roundf(bar_width * (_window_left / _window_total if _window_total > 0.0 else 0.0))

## The guardian starts calling: the sheet appears in its season's colour with
## the notes it is willing to show, unlit, and asks the player to listen.
func on_call_opened(song: Song, revealed: int, glyph_set: Enums.GlyphSet) -> void:
	_stop_linger()
	_counting = false
	_frame.modulate = song.tint().lerp(Color.WHITE, 0.45)
	_sheet.modulate = Color.WHITE
	_sheet.show_notes(song.notes, glyph_sets[glyph_set], revealed)
	_message.text = LISTEN_KEY
	_bar.hide()
	_frame.position = Vector2(roundf((size.x - _frame.size.x) / 2.0), frame_top)
	modulate = Color.WHITE
	show()

func on_call_note_sounded(index: int) -> void:
	_sheet.light(index)

## The phrase is over: the slots dim, the bar fills, and the ask changes.
func on_call_window_opened(seconds: float) -> void:
	_sheet.dim_all()
	_message.text = ANSWER_KEY
	_window_total = seconds
	_window_left = seconds
	_bar.position.x = bar_left
	_bar.size.x = bar_width
	_bar.show()
	_counting = true

## `count` notes of the answer are right so far: light them back up.
func on_call_progress(count: int) -> void:
	_sheet.dim_all()
	for i: int in count:
		_sheet.light(i)

func on_call_answered(_song: Song) -> void:
	_counting = false
	_bar.hide()
	_sheet.modulate = SUCCESS_COLOR
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
	hide()

func _linger_then_hide() -> void:
	_stop_linger()
	_linger_tween = create_tween()
	_linger_tween.tween_interval(LINGER_TIME)
	_linger_tween.tween_property(self, "modulate:a", 0.0, 0.2)
	_linger_tween.tween_callback(hide)

func _stop_linger() -> void:
	if _linger_tween != null:
		_linger_tween.kill()
		_linger_tween = null
