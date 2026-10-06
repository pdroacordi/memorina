class_name NotebookToast
extends TextureRect
## The quill that tells the notebook has something new; pausable, so it waits out a lesson and stops under a menu.

## Seconds the quill takes to appear.
@export var fade_in: float = 0.4
## Seconds the quill stays fully shown.
@export var hold: float = 3.0
## Seconds the quill takes to disappear.
@export var fade_out: float = 0.8

var _tween: Tween


func _ready() -> void:
	modulate.a = 0.0

## Fades the quill in, holds it, and fades it out; a second call restarts it.
func show_hint(_ids: Array[StringName] = []) -> void:
	if _tween != null:
		_tween.kill()
	_tween = create_tween().set_trans(Tween.TRANS_SINE)
	_tween.tween_property(self, "modulate:a", 1.0, fade_in * (1.0 - modulate.a)).set_ease(Tween.EASE_OUT)
	_tween.tween_interval(hold)
	_tween.tween_property(self, "modulate:a", 0.0, fade_out).set_ease(Tween.EASE_IN)

func is_showing() -> bool:
	return modulate.a > 0.0
