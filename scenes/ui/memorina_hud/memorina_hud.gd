class_name MemorinaHud extends Control

## The sheet the instrument is read from: appears when the Memorina is drawn,
## shows each note as it is pressed with the button it was pressed on, blinks
## on a mistake, lights up as a performance replays the song, and carries the
## lesson banner. An observer of Player's signals (wired in game.tscn) that
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
## Screen y of the frame's top edge while it shows a guardian's call. The
## call sheet sits at the top of the screen, not beside Ivo: he is not holding
## the instrument yet, and the camera has not eased in on him.
@export var call_frame_top: float = 12.0
@export var fade_in_time: float = 0.15

var _facing: int = 1
## Whether the instrument is out. A call closing while it is out leaves the
## frame to the sheathe that follows.
var _drawn: bool = false
var _fade_tween: Tween

@onready var _frame: TextureRect = $Frame
@onready var _sheet: NoteSheet = $Frame/NoteSheet
@onready var _banner: LearnBanner = $Frame/LearnBanner

func _ready() -> void:
	assert(glyph_sets.size() == Enums.GlyphSet.size(),
		"MemorinaHud has %d glyph sets for %d members of Enums.GlyphSet." % [glyph_sets.size(), Enums.GlyphSet.size()])
	if OS.is_debug_build():
		for glyphs: NoteGlyphSet in glyph_sets:
			glyphs.validate()
	hide()

func on_drawn(_known_songs: Array[Song], facing: int) -> void:
	_facing = facing
	_drawn = true
	# Cleared here as well as on sheathe, so the sheet never inherits what an
	# earlier session left behind however the HUD came to be open. A call's
	# phrase goes too: the answer is played from memory.
	_sheet.clear()
	_banner.dismiss()
	_frame.hide()
	show()

## The camera has settled; now the open side is known for certain.
func on_camera_focused(subject_screen_position: Vector2) -> void:
	if not visible or _frame.visible:
		return
	_place_frame(_facing, subject_screen_position)
	_frame.modulate.a = 0.0
	_frame.show()
	if _fade_tween:
		_fade_tween.kill()
	_fade_tween = create_tween()
	_fade_tween.tween_property(_frame, "modulate:a", 1.0, fade_in_time)

func on_sheathed() -> void:
	_drawn = false
	_sheet.clear()
	_banner.dismiss()
	hide()

## A guardian calls: the phrase's revealed notes appear at the top of the
## screen, unlit, and light up one by one as the guardian sounds them.
func on_call_opened(song: Song, revealed: int, glyph_set: Enums.GlyphSet) -> void:
	if _drawn:
		return
	_sheet.show_notes(song.notes, glyph_sets[glyph_set], revealed)
	_banner.dismiss()
	_frame.position = Vector2(roundf((size.x - _frame.size.x) / 2.0), call_frame_top)
	_frame.modulate.a = 1.0
	_frame.show()
	show()

func on_call_note_sounded(index: int) -> void:
	if _drawn:
		return
	_sheet.light(index)

func on_call_closed() -> void:
	if _drawn:
		return
	_sheet.clear()
	hide()

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

func on_lesson_started(song: Song, glyph_set: Enums.GlyphSet) -> void:
	_sheet.show_notes(song.notes, glyph_sets[glyph_set])
	_banner.show_for(song)

func on_song_played(_song: Song, _position: Vector2) -> void:
	_sheet.clear()
	_banner.dismiss()

## The frame goes to the side Ivo faces, unless he already stands in that half
## (the camera clamped against a room edge), in which case the room is behind
## him and so is the space.
func _place_frame(facing: int, screen_position: Vector2) -> void:
	var center_x := size.x / 2.0
	var ahead := facing if signf(screen_position.x - center_x) != signf(facing) else -facing
	var x := center_x + frame_gap if ahead > 0 else center_x - frame_gap - _frame.size.x
	var y := frame_center_y - _frame.size.y / 2.0
	_frame.position = Vector2(roundf(x), roundf(y))
