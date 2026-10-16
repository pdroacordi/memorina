class_name Letterbox
extends Control
## The two black bars a lesson and a cutscene bring in; ALWAYS with scaled tweens, so they slide through a performance's
## freeze and stop under a menu's hold (systems/cutscenes).

## Px of each bar.
@export var bar_height: float = 36.0

var _tween: Tween
var _open: bool = false

@onready var _top: ColorRect = $TopBar
@onready var _bottom: ColorRect = $BottomBar


func _ready() -> void:
	_place(0.0)
	hide()

## Slides the bars in over `seconds`; 0 cuts.
func open(seconds: float) -> void:
	_open = true
	_slide(1.0, seconds, Tween.EASE_OUT)

## Slides the bars out over `seconds`; 0 cuts.
func close(seconds: float) -> void:
	_open = false
	_slide(0.0, seconds, Tween.EASE_IN)

func is_open() -> bool:
	return _open

## 0 out of view .. 1 fully in.
func shown() -> float:
	return clampf(_top.position.y / bar_height + 1.0, 0.0, 1.0)

func _slide(to: float, seconds: float, ease_type: Tween.EaseType) -> void:
	if _tween != null:
		_tween.kill()
		_tween = null
	if to > 0.0:
		show()
	if seconds <= 0.0:
		_place(to)
		visible = to > 0.0
		return
	_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_trans(Tween.TRANS_CUBIC).set_ease(ease_type)
	_tween.tween_method(_place, shown(), to, seconds)
	if to <= 0.0:
		_tween.tween_callback(hide)

## `amount` 0..1 of the bars in view.
func _place(amount: float) -> void:
	_top.size = Vector2(size.x, bar_height)
	_bottom.size = Vector2(size.x, bar_height)
	_top.position = Vector2(0.0, -bar_height * (1.0 - amount))
	_bottom.position = Vector2(0.0, size.y - bar_height * amount)
