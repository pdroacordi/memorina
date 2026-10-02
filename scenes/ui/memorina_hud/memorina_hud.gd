class_name MemorinaHud extends Control

## Displays Memorina input, lessons, and guardian call answers.

const DRAW_ACTION := &"draw_memorina"
const SUCCESS_COLOR := Color(0.55, 1.0, 0.6)
## Dark bar color contrasts with the sheet's gold.
const BAR_COLOR := Color(0.3, 0.2, 0.13)
const BAR_LOW_COLOR := Color(0.72, 0.16, 0.12)
## Answer linger time in seconds.
const LINGER_TIME := 0.6
## Lesson sheet hold and fade durations in seconds.
const LESSON_SHEET_HOLD := 1.4
const LESSON_SHEET_FADE := 0.6

## Indexed by Enums.GlyphSet: which textures each input device draws with.
@export var glyph_sets: Array[NoteGlyphSet] = []
## Horizontal gap from screen center to the frame's near edge, in px.
@export var frame_gap: float = 16.0
## Screen y coordinate of the frame center, in px.
@export var frame_center_y: float = 224.0
@export var fade_in_time: float = 0.15

var _facing: int = 1
var _fade_tween: Tween
var _linger_tween: Tween
## True while a guardian call is staged.
var _call_staged: bool = false
## Notes to display during the answer.
var _call_notes: Array[Enums.Note] = []
## Encounter placement chosen for the guardian sheet.
var _call_side: int = 1
var _call_height: float = 0.0
var _call_glyphs: NoteGlyphSet
## True while the answer window is open.
var _answering: bool = false
var _drawn: bool = false
## Number of lesson notes that will light; zero when no lesson is active.
var _lesson_notes: int = 0
## Full time-bar width in px.
var _bar_width: float = 0.0

@onready var _frame: TextureRect = $Frame
@onready var _sheet: NoteSheet = $Frame/NoteSheet
@onready var _bar: ColorRect = $Frame/TimeBar
@onready var _key: KeyGlyph = $Frame/KeyPrompt

func _ready() -> void:
	assert(glyph_sets.size() == Enums.GlyphSet.size(),
		"MemorinaHud has %d glyph sets for %d members of Enums.GlyphSet." % [glyph_sets.size(), Enums.GlyphSet.size()])
	if OS.is_debug_build():
		for glyphs: NoteGlyphSet in glyph_sets:
			glyphs.validate()
	_bar_width = _bar.size.x
	hide()

#############################################
##  I V O ' S   O W N   S H E E T          ##
#############################################

func on_drawn(_known_songs: Array[Song], facing: int) -> void:
	_facing = facing
	_drawn = true
	if _answering:
		# The phrase is already shown during an answer.
		_key.stop_blink()
		_key.hide()
		return
	if _call_staged:
		# Preserve the staged lesson sheet when the instrument is drawn.
		return
	# Clear stale notes before showing a newly opened sheet.
	_sheet.clear()
	_frame.hide()
	show()

## Positions the frame after the camera settles; earlier placement can cover Ivo during camera look-ahead.
func on_camera_focused(subject_screen_position: Vector2) -> void:
	# Encounter placement is independent of camera focus.
	if not visible or _frame.visible or _call_staged:
		return
	_place_frame(_facing, subject_screen_position)
	_fade_frame_in()

func on_sheathed() -> void:
	_drawn = false
	_lesson_notes = 0
	if _answering:
		# Keep the answer sheet until the call closes.
		return
	_sheet.clear()
	hide()

func on_note_played(note: Enums.Note, glyph_set: Enums.GlyphSet) -> void:
	# Answer notes are lit by call progress.
	if _answering:
		return
	_sheet.push_note(note, glyph_sets[glyph_set])

func on_note_rejected(note: Enums.Note, glyph_set: Enums.GlyphSet) -> void:
	if _answering:
		return
	_sheet.push_note(note, glyph_sets[glyph_set])

func on_sequence_failed() -> void:
	_sheet.flash()

func on_sequence_reset() -> void:
	if _answering:
		return
	_sheet.clear()

func on_note_cue_reached(index: int) -> void:
	_sheet.light(index)
	if _lesson_notes > 0 and index >= _lesson_notes - 1:
		_close_lesson_sheet()

## Shows lesson notes; `LessonCinematic` owns the title card.
func on_lesson_started(song: Song, glyph_set: Enums.GlyphSet) -> void:
	_stop_linger()
	_leave_answer()
	modulate = Color.WHITE
	_lesson_notes = song.notes.size()
	_sheet.show_notes(song.notes, glyph_sets[glyph_set])
	show()
	_show_in_slot()

func on_song_played(_song: Song, _position: Vector2) -> void:
	_lesson_notes = 0
	_sheet.clear()

#############################################
##  A   G U A R D I A N ' S   C A L L      ##
#############################################

func on_call_staged() -> void:
	_call_staged = true
	_frame.hide()

func on_call_unstaged() -> void:
	_call_staged = false

## Stores the call phrase and placement while the guardian sings.
func on_call_opened(song: Song, _revealed: int, glyph_set: Enums.GlyphSet, _cure_done: int, _cure_total: int, side: int, caller_height: float) -> void:
	_call_notes = song.notes
	_call_glyphs = glyph_sets[glyph_set]
	_call_side = side
	_call_height = caller_height
	_stop_linger()
	_leave_answer()
	_frame.hide()

## Shows the dimmed phrase and answer controls in the encounter slot.
func on_call_window_opened() -> void:
	_stop_linger()
	_answering = true
	_sheet.modulate = Color.WHITE
	_sheet.show_notes(_call_notes, _call_glyphs)
	_sheet.dim_all()
	_bar.size.x = _bar_width
	_bar.color = BAR_COLOR
	_bar.show()
	_key.show_action(DRAW_ACTION)
	if _drawn:
		_key.hide()
	else:
		_key.show()
		_key.start_blink()
	modulate = Color.WHITE
	show()
	_show_in_slot()

## Mirrors the encounter clock; a local countdown would advance during pause.
func on_call_window_progress(fraction: float) -> void:
	if not _answering:
		return
	_bar.size.x = roundf(_bar_width * fraction)
	_bar.color = BAR_COLOR.lerp(BAR_LOW_COLOR, 1.0 - fraction)

## Lights the first `count` answer notes and emphasizes the newest.
func on_call_progress(count: int) -> void:
	if not _answering:
		return
	_sheet.dim_all()
	for i: int in count:
		_sheet.light(i)
	_sheet.pop(count - 1)

func on_call_answered(_song: Song) -> void:
	if not _answering:
		return
	_bar.hide()
	_sheet.modulate = SUCCESS_COLOR
	_stop_linger()
	_linger_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_linger_tween.tween_interval(LINGER_TIME)
	_linger_tween.tween_property(self, "modulate:a", 0.0, 0.2)
	_linger_tween.tween_callback(_on_linger_done)

## Closes the answer sheet unless its success linger is still running.
func on_call_closed() -> void:
	if _linger_tween != null and _linger_tween.is_valid():
		return
	_leave_answer()
	if not _drawn:
		_sheet.clear()
		hide()

func _on_linger_done() -> void:
	_linger_tween = null
	_leave_answer()
	_sheet.clear()
	hide()

## Fades the sheet after the final lesson note; pause-process keeps the tween running during the lesson freeze.
func _close_lesson_sheet() -> void:
	_lesson_notes = 0
	if _fade_tween:
		_fade_tween.kill()
	_fade_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_fade_tween.tween_interval(LESSON_SHEET_HOLD)
	_fade_tween.tween_property(_frame, "modulate:a", 0.0, LESSON_SHEET_FADE)
	_fade_tween.tween_callback(_frame.hide)

## Positions the frame in the encounter slot.
func _show_in_slot() -> void:
	_frame.position = Vector2(_sheet.encounter_x(size.x, _call_side, _call_height), _sheet.encounter_y())
	if _frame.visible:
		return
	_fade_frame_in()

func _fade_frame_in() -> void:
	_frame.modulate.a = 0.0
	_frame.show()
	if _fade_tween:
		_fade_tween.kill()
	_fade_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_fade_tween.tween_property(_frame, "modulate:a", 1.0, fade_in_time)

func _leave_answer() -> void:
	_answering = false
	_bar.hide()
	_key.stop_blink()
	_key.hide()
	_sheet.modulate = Color.WHITE

func _stop_linger() -> void:
	if _linger_tween != null:
		_linger_tween.kill()
		_linger_tween = null

## Places the frame ahead of Ivo, using the opposite side when the camera is clamped at a room edge.
func _place_frame(facing: int, screen_position: Vector2) -> void:
	var center_x := size.x / 2.0
	var ahead := facing if signf(screen_position.x - center_x) != signf(facing) else -facing
	var x := center_x + frame_gap if ahead > 0 else center_x - frame_gap - _frame.size.x
	var y := frame_center_y - _frame.size.y / 2.0
	_frame.position = Vector2(roundf(x), roundf(y))
