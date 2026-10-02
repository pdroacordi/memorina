class_name LessonCinematic extends Control

## Displays guardian calls and song lessons; lesson tweens continue while the world is paused.

const LEARNED_KEY := "MEMORINA_LEARNED"

@export var bar_height: float = 36.0
## Dim overlay opacity during a lesson, 0..1.
@export var dim_alpha: float = 0.45
## The lighter dim of a call, where the player still has to play.
@export var call_dim_alpha: float = 0.28
## Fade durations in seconds.
@export var ease_in_time: float = 0.6
@export var ease_out_time: float = 0.4
## Title rise distance in pixels.
@export var title_rise: float = 10.0
## Delay in seconds after the final note cue before the title appears.
@export var card_delay: float = 2.2

var _tween: Tween
## Title tween, independent of the frame tween.
var _card_tween: Tween
## Final phrase cue index and title pending state.
var _cue_target: int = 0
var _card_pending: bool = false
## Remains true until the lesson frame closes, even if the guardian call unstages.
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

## Preserve current dim across the call-to-lesson transition to avoid a one-frame flash.
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

## Shows the lesson title after the final note cue; ordinary performances do not show it.
func on_note_cue_reached(index: int) -> void:
	if not _lesson_active or not _card_pending or index < _cue_target:
		return
	_card_pending = false
	_kill_card()
	_card_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel(true) 		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_card_tween.tween_property(_card, "modulate:a", 1.0, ease_in_time).set_delay(card_delay)
	_card_tween.tween_property(_card, "position:y", _card_rest_y(), ease_in_time).set_delay(card_delay)

## Closes the frame when the performance ends.
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

## Dims the scene for a guardian call and clears any previous title.
func on_call_staged() -> void:
	_card.modulate.a = 0.0
	show()
	_kill()
	_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_dim, "color:a", call_dim_alpha, ease_in_time)

## Fades out a call unless a lesson owns the layer; see docs/knowledge/bugs/lesson-title-card-survives-a-cut-fade.md.
func on_call_unstaged() -> void:
	if _lesson_active or not visible:
		return
	_kill()
	_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_tween.tween_property(_dim, "color:a", 0.0, ease_out_time)
	_tween.tween_callback(_finish)

## Hides the layer and resets it for the next event.
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
