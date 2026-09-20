class_name LessonCinematic extends Control

## The moment a song is learned, staged: letterbox bars close in, the world
## dims, and the piece's title rises at the top while the whole track plays
## and the sheet beside Ivo lights up note by note. Everything eases back
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
@export var ease_in_time: float = 0.6
@export var ease_out_time: float = 0.4
## How far the title rises into place as it fades in.
@export var title_rise: float = 10.0

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

func on_lesson_started(song: Song, _glyph_set: Enums.GlyphSet) -> void:
	_title.text = song.title_key
	_reset()
	show()
	_kill()
	_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel(true) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_top_bar, "position:y", 0.0, ease_in_time)
	_tween.tween_property(_bottom_bar, "position:y", size.y - bar_height, ease_in_time)
	_tween.tween_property(_dim, "color:a", dim_alpha, ease_in_time)
	_tween.tween_property(_card, "modulate:a", 1.0, ease_in_time).set_delay(ease_in_time * 0.5)
	_tween.tween_property(_card, "position:y", _card_rest_y(), ease_in_time).set_delay(ease_in_time * 0.5)

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
