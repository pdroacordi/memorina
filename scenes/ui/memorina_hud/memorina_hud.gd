class_name MemorinaHud extends Control

## The sheet the instrument is read from: appears when the Memorina is drawn,
## shows each note as it is pressed with the button it was pressed on, blinks
## on a mistake, lights up as a performance replays the song, and carries the
## notes of a lesson as its track plays. An observer of Player's signals (wired in game.tscn) that
## decides nothing.
##
## process_mode is ALWAYS in the scene, because the world is frozen while a
## performance plays and the sheet has to keep lighting up through it.
##
## The sheet is laid out only once the camera reports `focused`: drawing right
## after a turn leaves the look-ahead still travelling, and a frame placed
## before it lands covers where Ivo is about to be. Notes played meanwhile
## are kept by the sheet and shown when it appears.

## Indexed by Enums.GlyphSet: which textures each input device draws with.
@export var glyph_sets: Array[NoteGlyphSet] = []
## Horizontal gap between the screen's centre line and the frame's near edge.
## The camera leads Ivo's facing, so the space ahead of him is the far half.
@export var frame_gap: float = 16.0
## Screen y the frame is centred on, roughly Ivo's body once the camera has
## eased in.
@export var frame_center_y: float = 224.0
@export var fade_in_time: float = 0.15

var _facing: int = 1
## While a guardian is staged its sheet at the top is the score for both
## sides, and this one stays out of the way; it comes back when the stage
## clears, if the instrument is still out.
var _call_staged: bool = false
var _fade_tween: Tween

@onready var _frame: TextureRect = $Frame
@onready var _sheet: NoteSheet = $Frame/NoteSheet

func _ready() -> void:
	assert(glyph_sets.size() == Enums.GlyphSet.size(),
		"MemorinaHud has %d glyph sets for %d members of Enums.GlyphSet." % [glyph_sets.size(), Enums.GlyphSet.size()])
	if OS.is_debug_build():
		for glyphs: NoteGlyphSet in glyph_sets:
			glyphs.validate()
	hide()

func on_drawn(_known_songs: Array[Song], facing: int) -> void:
	_facing = facing
	# Cleared here as well as on sheathe, so the sheet never inherits what an
	# earlier session left behind however the HUD came to be open.
	_sheet.clear()
	_frame.hide()
	show()

## The camera has settled; now the open side is known for certain.
func on_camera_focused(subject_screen_position: Vector2) -> void:
	if not visible or _frame.visible or _call_staged:
		return
	_place_frame(_facing, subject_screen_position)
	_frame.modulate.a = 0.0
	_frame.show()
	if _fade_tween:
		_fade_tween.kill()
	_fade_tween = create_tween()
	_fade_tween.tween_property(_frame, "modulate:a", 1.0, fade_in_time)

func on_sheathed() -> void:
	_sheet.clear()
	hide()

func on_call_staged() -> void:
	_call_staged = true
	_frame.hide()

func on_call_unstaged() -> void:
	_call_staged = false

func on_note_played(note: Enums.Note, glyph_set: Enums.GlyphSet) -> void:
	_sheet.push_note(note, glyph_sets[glyph_set])

func on_note_rejected(note: Enums.Note, glyph_set: Enums.GlyphSet) -> void:
	_sheet.push_note(note, glyph_sets[glyph_set])

func on_sequence_failed() -> void:
	_sheet.flash()

func on_sequence_reset() -> void:
	_sheet.clear()

func on_note_cue_reached(index: int) -> void:
	_sheet.light(index)

## The title card is LessonCinematic's; here only the notes to be lit.
func on_lesson_started(song: Song, glyph_set: Enums.GlyphSet) -> void:
	_sheet.show_notes(song.notes, glyph_sets[glyph_set])

func on_song_played(_song: Song, _position: Vector2) -> void:
	_sheet.clear()

## The frame goes to the side Ivo faces, unless he already stands in that half
## (the camera clamped against a room edge), in which case the room is behind
## him and so is the space.
func _place_frame(facing: int, screen_position: Vector2) -> void:
	var center_x := size.x / 2.0
	var ahead := facing if signf(screen_position.x - center_x) != signf(facing) else -facing
	var x := center_x + frame_gap if ahead > 0 else center_x - frame_gap - _frame.size.x
	var y := frame_center_y - _frame.size.y / 2.0
	_frame.position = Vector2(roundf(x), roundf(y))
