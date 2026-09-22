class_name MemorinaHud extends Control

## The sheet the instrument is read from: appears when the Memorina is drawn,
## shows each note as it is pressed with the button it was pressed on, blinks
## on a mistake, lights up as a performance replays the song, and carries the
## notes of a lesson as its track plays. During a guardian's call it is where
## the ANSWER is given: while the guardian sings it stays out of the way (the
## phrase is on the guardian's own sheet at the top); when the window opens
## the same sheet stays put and becomes Ivo's: pre-filled with the phrase,
## dimmed, the time draining under the staff and the draw key blinking under
## the frame until the instrument is out, and the phrase lighting back up as
## the answer lands each note. The same sheet, in the same place, so the
## player knows what to do with it. An
## observer of Player's signals (wired in game.tscn) that decides nothing.
##
## An encounter has ONE slot for the sheet, authored and centred: the phrase
## the guardian sang, the answer and the lesson all happen in the same place,
## so the frame never hops across the screen between one beat and the next.
##
## process_mode is ALWAYS in the scene, because the world is frozen while a
## performance plays and the sheet has to keep lighting up through it.
##
## The sheet is laid out only once the camera reports `focused`: drawing right
## after a turn leaves the look-ahead still travelling, and a frame placed
## before it lands covers where Ivo is about to be. Notes played meanwhile
## are kept by the sheet and shown when it appears.

const DRAW_ACTION := &"draw_memorina"
const SUCCESS_COLOR := Color(0.55, 1.0, 0.6)
## Ink on parchment: the sheet's own gold is what the bar drains across, so a
## gold bar on it was invisible.
const BAR_COLOR := Color(0.3, 0.2, 0.13)
const BAR_LOW_COLOR := Color(0.72, 0.16, 0.12)
## Seconds the answered sheet lingers green before it goes.
const LINGER_TIME := 0.6
## A lesson's track runs far longer than its notes: once the last one has
## lit, the sheet has nothing left to show, so it holds a beat and goes,
## leaving the picture. Both in seconds.
const LESSON_SHEET_HOLD := 1.4
const LESSON_SHEET_FADE := 0.6

## Indexed by Enums.GlyphSet: which textures each input device draws with.
@export var glyph_sets: Array[NoteGlyphSet] = []
## Horizontal gap between the screen's centre line and the frame's near edge.
## The camera leads Ivo's facing, so the space ahead of him is the far half.
@export var frame_gap: float = 16.0
## Screen y the frame is centred on, roughly Ivo's body once the camera has
## eased in.
@export var frame_center_y: float = 224.0
@export var fade_in_time: float = 0.15
## Screen y of the frame's top edge in an encounter, where it is centred
## horizontally: the camera holds the pair in the lower band, so the sheet
## owns the upper one. Shared with GuardianCallHud, which must be the same
## number or the sheet jumps when the turn passes to Ivo.
@export var encounter_top: float = 40.0

var _facing: int = 1
var _fade_tween: Tween
var _linger_tween: Tween
## A guardian is staged: the sheet stays hidden while it sings.
var _call_staged: bool = false
## The phrase the guardian is calling, kept for the answer.
var _call_notes: Array[Enums.Note] = []
## The stage the call chose: which side the guardian stands on and how tall
## it is. Kept for the whole encounter, so the answer and the lesson land in
## the very slot the guardian's own sheet sang from.
var _call_side: int = 1
var _call_height: float = 0.0
var _call_glyphs: NoteGlyphSet
## The window is open: the sheet shows the phrase to be answered.
var _answering: bool = false
var _drawn: bool = false
var _window_total: float = 0.0
var _window_left: float = 0.0
## How many notes the lesson under way will light; 0 when none is.
var _lesson_notes: int = 0
## The bar's full width, read from the scene.
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

func _process(delta: float) -> void:
	if not _answering or _window_total <= 0.0 or get_tree().paused:
		return
	_window_left = maxf(_window_left - delta, 0.0)
	var fraction := _window_left / _window_total
	_bar.size.x = roundf(_bar_width * fraction)
	_bar.color = BAR_COLOR.lerp(BAR_LOW_COLOR, 1.0 - fraction)

#############################################
##  I V O ' S   O W N   S H E E T          ##
#############################################

func on_drawn(_known_songs: Array[Song], facing: int) -> void:
	_facing = facing
	_drawn = true
	if _answering:
		# The phrase is already on the sheet; only the ask to draw goes.
		_key.stop_blink()
		_key.hide()
		return
	if _call_staged:
		# The lesson takes the instrument out by itself; the sheet is already
		# in its slot and must not be cleared out from under the piece.
		return
	# Cleared here as well as on sheathe, so the sheet never inherits what an
	# earlier session left behind however the HUD came to be open.
	_sheet.clear()
	_frame.hide()
	show()

## The camera has settled; now the open side is known for certain.
func on_camera_focused(subject_screen_position: Vector2) -> void:
	# An encounter's sheet has a slot of its own and never waits for a camera.
	if not visible or _frame.visible or _call_staged:
		return
	_place_frame(_facing, subject_screen_position)
	_fade_frame_in()

func on_sheathed() -> void:
	_drawn = false
	_lesson_notes = 0
	if _answering:
		# Interrupted mid-answer: the failure has flashed; the call closing
		# takes the sheet away.
		return
	_sheet.clear()
	hide()

func on_note_played(note: Enums.Note, glyph_set: Enums.GlyphSet) -> void:
	# During an answer the sheet already holds the phrase; call_progress
	# lights it instead.
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

## The title card is LessonCinematic's; here only the notes to be lit.
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

## The guardian starts singing: remember the phrase, stay out of the way.
func on_call_opened(song: Song, _revealed: int, glyph_set: Enums.GlyphSet, _cure_done: int, _cure_total: int, side: int, caller_height: float) -> void:
	_call_notes = song.notes
	_call_glyphs = glyph_sets[glyph_set]
	_call_side = side
	_call_height = caller_height
	_stop_linger()
	_leave_answer()
	_frame.hide()

## Ivo's turn: the phrase comes to his sheet, dimmed, with the time to answer
## it and the key that takes the instrument out - in the encounter's slot,
## exactly where the guardian's own sheet just sang it.
func on_call_window_opened(seconds: float) -> void:
	_stop_linger()
	_answering = true
	_sheet.modulate = Color.WHITE
	_sheet.show_notes(_call_notes, _call_glyphs)
	_sheet.dim_all()
	_window_total = maxf(seconds, 0.001)
	_window_left = seconds
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

## `count` notes of the answer are right so far: light them back up, the
## newest with a beat.
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

## The call is over, answered or not. A verdict still lingering finishes on
## its own; otherwise the sheet goes now (a failure has flashed already).
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

## The sheet has shown the whole piece: it bows out, and the scene is the
## guardian, Ivo and the title alone for the rest of the track. Pause-process,
## like everything else in a lesson.
func _close_lesson_sheet() -> void:
	_lesson_notes = 0
	if _fade_tween:
		_fade_tween.kill()
	_fade_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_fade_tween.tween_interval(LESSON_SHEET_HOLD)
	_fade_tween.tween_property(_frame, "modulate:a", 0.0, LESSON_SHEET_FADE)
	_fade_tween.tween_callback(_frame.hide)

## The encounter's slot: centred, under the letterbox a lesson closes in.
func _show_in_slot() -> void:
	_frame.position = Vector2(_sheet.encounter_x(size.x, _call_side, _call_height), roundf(encounter_top))
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
	_window_total = 0.0
	_bar.hide()
	_key.stop_blink()
	_key.hide()
	_sheet.modulate = Color.WHITE

func _stop_linger() -> void:
	if _linger_tween != null:
		_linger_tween.kill()
		_linger_tween = null

## The frame goes to the side Ivo faces, unless he already stands in that half
## (the camera clamped against a room edge), in which case the room is behind
## him and so is the space.
func _place_frame(facing: int, screen_position: Vector2) -> void:
	var center_x := size.x / 2.0
	var ahead := facing if signf(screen_position.x - center_x) != signf(facing) else -facing
	var x := center_x + frame_gap if ahead > 0 else center_x - frame_gap - _frame.size.x
	var y := frame_center_y - _frame.size.y / 2.0
	_frame.position = Vector2(roundf(x), roundf(y))
