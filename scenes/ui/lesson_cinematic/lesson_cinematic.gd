class_name LessonCinematic extends Control

## The encounter's stage lights. A guardian's call dims the world a little
## under the creature pass, so Ivo and the guardian stand lit in it, for as
## long as the guardian is staged. The moment a song is learned goes further:
## letterbox bars close in, the dim deepens, and the sheet in the encounter's
## slot lights up note by note. The piece is NAMED once it has been heard: the
## title waits for the last note cue and the sheet's own exit, then rises into
## the slot the sheet has just left and STAYS for the rest of the track -
## naming the piece is the point of the moment, and it leaves with the
## letterbox. Hear it, then learn what it is called; the two never share the
## screen, which is what made the frame look crowded. Everything eases back
## out when the performance ends. An observer of Player's signals (wired in
## game.tscn) that decides nothing.
##
## process_mode is ALWAYS in the scene: the world is frozen for the whole
## lesson, and every tween here runs through the pause.
##
## Both Labels are given translation KEYS (a Label auto-translates its text).

const LEARNED_KEY := "MEMORINA_LEARNED"

@export var bar_height: float = 36.0
@export var dim_alpha: float = 0.45
## The lighter dim of a call, where the player still has to play.
@export var call_dim_alpha: float = 0.28
@export var ease_in_time: float = 0.6
@export var ease_out_time: float = 0.4
## How far the title rises into place as it fades in.
@export var title_rise: float = 10.0
## Seconds after the piece's last note cue before its name rises: long enough
## for MemorinaHud's sheet to hold its last note and bow out.
@export var card_delay: float = 2.2

var _tween: Tween
## The title's own tween, which runs long after the frame's has finished.
var _card_tween: Tween
## The cue index that ends the phrase, and whether the name is still owed.
var _cue_target: int = 0
var _card_pending: bool = false
## True from a lesson's first frame to the moment its frame has closed. The
## lesson OWNS the layer while it is set: a guardian unstages its call when
## the performance ends, and that must not cut the lesson's own way out.
var _lesson_active: bool = false

@onready var _top_bar: ColorRect = $TopBar
@onready var _bottom_bar: ColorRect = $BottomBar
@onready var _dim: ColorRect = $Dim
@onready var _card: Control = $Card
@onready var _message: Label = $Card/Message
@onready var _title: Label = $Card/Title

func _ready() -> void:
	_message.text = LEARNED_KEY
	_reset()
	hide()

## The dim is not reset first: restoration unstages the call and starts the
## lesson in the same breath, and the light must not flicker up between.
func on_lesson_started(song: Song, _glyph_set: Enums.GlyphSet) -> void:
	_lesson_active = true
	_title.text = song.title_key
	_cue_target = song.notes.size() - 1
	_card_pending = true
	var dim := _dim.color.a
	_reset()
	_dim.color.a = dim
	show()
	_kill()
	_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel(true) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_top_bar, "position:y", 0.0, ease_in_time)
	_tween.tween_property(_bottom_bar, "position:y", size.y - bar_height, ease_in_time)
	_tween.tween_property(_dim, "color:a", dim_alpha, ease_in_time)

## The phrase has been heard out: the sheet bows away and the piece's name
## takes its place. Ordinary performances cue too; only a lesson names one.
func on_note_cue_reached(index: int) -> void:
	if not _lesson_active or not _card_pending or index < _cue_target:
		return
	_card_pending = false
	_kill_card()
	_card_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel(true) 		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_card_tween.tween_property(_card, "modulate:a", 1.0, ease_in_time).set_delay(card_delay)
	_card_tween.tween_property(_card, "position:y", _card_rest_y(), ease_in_time).set_delay(card_delay)

## The performance is over, whichever way: the frame opens back up.
func on_lesson_finished() -> void:
	if not visible:
		return
	_card_pending = false
	_kill_card()
	_kill()
	_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel(true) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_tween.tween_property(_top_bar, "position:y", -bar_height, ease_out_time)
	_tween.tween_property(_bottom_bar, "position:y", size.y, ease_out_time)
	_tween.tween_property(_dim, "color:a", 0.0, ease_out_time)
	_tween.tween_property(_card, "modulate:a", 0.0, ease_out_time * 0.6)
	_tween.chain().tween_callback(_finish)

## A guardian went lucid: the lights come down on it and Ivo. A call names no
## piece, so the card starts hidden - never inherited from the last lesson.
func on_call_staged() -> void:
	_card.modulate.a = 0.0
	show()
	_kill()
	_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_dim, "color:a", call_dim_alpha, ease_in_time)

## The relapse has run its course, or the guardian was restored. In the second
## case the lesson has the layer - it is started in the same breath, and a
## guardian also unstages when the track ENDS, which is mid-way through the
## lesson's own way out. Cutting that short left the title card at full alpha
## on a hidden node, and the next call put the last song's name back on
## screen (docs/knowledge/bugs/lesson-title-card-survives-a-cut-fade.md).
func on_call_unstaged() -> void:
	if _lesson_active or not visible:
		return
	_kill()
	_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_tween.tween_property(_dim, "color:a", 0.0, ease_out_time)
	_tween.tween_callback(_finish)

## Off screen and back to the authored state. Every way out ends here, so no
## half-finished fade can leave something visible for the next moment to show.
func _finish() -> void:
	_lesson_active = false
	_card_pending = false
	hide()
	_reset()

func _reset() -> void:
	_kill_card()
	_top_bar.size = Vector2(size.x, bar_height)
	_top_bar.position = Vector2(0.0, -bar_height)
	_bottom_bar.size = Vector2(size.x, bar_height)
	_bottom_bar.position = Vector2(0.0, size.y)
	_dim.color.a = 0.0
	_card.modulate.a = 0.0
	_card.position = Vector2((size.x - _card.size.x) / 2.0, _card_rest_y() + title_rise)

func _card_rest_y() -> float:
	return bar_height + 12.0

func _kill() -> void:
	if _tween != null:
		_tween.kill()
		_tween = null

func _kill_card() -> void:
	if _card_tween != null:
		_card_tween.kill()
		_card_tween = null
