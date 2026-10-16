class_name NoticeToast
extends Control
## One notice at a time, top right beside the notebook quill: an item's icon and name, or the intent line. It slides in,
## holds and leaves; pausable and scaled, so it stops under a menu hold (systems/notices).

## The notice begins to slide out: from here it counts as told and is never withdrawn.
signal leaving
## The notice has left and its gap passed; the watcher may send the next.
signal finished

## Widest text the line holds, art px; the fit test measures every item name and intent against it.
const TEXT_WIDTH := 180.0

## Scaled seconds the notice takes to slide in.
@export var slide_in: float = 0.3
## Scaled seconds the notice stays fully shown.
@export var hold: float = 2.0
## Scaled seconds the notice takes to leave.
@export var slide_out: float = 0.5
## Scaled seconds after it leaves before the next may come.
@export var gap: float = 0.25
## Art px the notice travels from the right while it slides in and out.
@export var slide: float = 12.0

var _tween: Tween

@onready var _art: Control = $Art
@onready var _card: Control = $Art/Card
@onready var _icon: TextureRect = $Art/Card/Row/Icon
@onready var _text: Label = $Art/Card/Row/Text


func _ready() -> void:
	_art.modulate.a = 0.0
	_art.visible = false

## Shows `text_key` with `icon` (null hides the icon); a notice still showing is replaced.
func show_notice(text_key: String, icon: Texture2D) -> void:
	_stop()
	_text.text = tr(text_key)
	_icon.texture = icon
	_icon.visible = icon != null
	_card.position.x = slide
	_art.modulate.a = 0.0
	_art.show()
	_tween = create_tween().set_trans(Tween.TRANS_SINE)
	_tween.tween_property(_art, "modulate:a", 1.0, slide_in).set_ease(Tween.EASE_OUT)
	_tween.parallel().tween_property(_card, "position:x", 0.0, slide_in).set_ease(Tween.EASE_OUT)
	_tween.tween_interval(hold)
	_tween.tween_callback(leaving.emit)
	_tween.tween_property(_art, "modulate:a", 0.0, slide_out).set_ease(Tween.EASE_IN)
	_tween.parallel().tween_property(_card, "position:x", slide, slide_out).set_ease(Tween.EASE_IN)
	_tween.tween_callback(_art.hide)
	_tween.tween_interval(gap)
	_tween.tween_callback(finished.emit)

## Hides the notice at once, without `leaving` or `finished`: the watcher that withdrew it queues it again.
func withdraw() -> void:
	_stop()
	_art.hide()
	_art.modulate.a = 0.0

func is_showing() -> bool:
	return _art.visible and _art.modulate.a > 0.0

## The translated text shown or last shown.
func shown_text() -> String:
	return _text.text

func shows_icon() -> bool:
	return _icon.visible and _icon.texture != null

func _stop() -> void:
	if _tween != null:
		_tween.kill()
		_tween = null
