class_name LessonCinematic extends Control

## The encounter's stage lights. A guardian's call dims the world a little
## under the creature pass, so Ivo and the guardian stand lit in it, for as
## long as the guardian is staged. The moment a song is learned goes further:
## letterbox bars close in, the dim deepens, and the piece's title rises at
## the top while the whole track plays and the sheet beside Ivo lights up note
## by note. Everything eases back out when the performance ends. An observer
## of Player's signals (wired in game.tscn) that decides nothing.
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
## Seconds the title card holds before it fades, leaving the picture alone:
## the world remembering is the scene, the card only names it.
@export var title_hold: float = 4.0
@export var title_fade_time: float = 1.0

var _tween: Tween

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
	_title.text = song.title_key
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
	_tween.tween_property(_card, "modulate:a", 1.0, ease_in_time).set_delay(ease_in_time * 0.5)
	_tween.tween_property(_card, "position:y", _card_rest_y(), ease_in_time).set_delay(ease_in_time * 0.5)
	_tween.tween_property(_card, "modulate:a", 0.0, title_fade_time).set_delay(ease_in_time * 1.5 + title_hold)

## The performance is over, whichever way: the frame opens back up.
func on_lesson_finished() -> void:
	if not visible:
		return
	_kill()
	_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel(true) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_tween.tween_property(_top_bar, "position:y", -bar_height, ease_out_time)
	_tween.tween_property(_bottom_bar, "position:y", size.y, ease_out_time)
	_tween.tween_property(_dim, "color:a", 0.0, ease_out_time)
	_tween.tween_property(_card, "modulate:a", 0.0, ease_out_time * 0.6)
	_tween.chain().tween_callback(hide)

## A guardian went lucid: the lights come down on it and Ivo.
func on_call_staged() -> void:
	show()
	_kill()
	_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_dim, "color:a", call_dim_alpha, ease_in_time)

## The relapse has run its course, or the guardian was restored (in which
## case the lesson takes the stage right after this, and its own tween wins).
func on_call_unstaged() -> void:
	if not visible:
		return
	_kill()
	_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_tween.tween_property(_dim, "color:a", 0.0, ease_out_time)
	_tween.tween_callback(hide)

func _reset() -> void:
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
