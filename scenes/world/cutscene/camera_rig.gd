class_name CameraRig
extends Node2D
## The point the camera follows during a cutscene. It moves only on the physics clock, like every camera tween
## (bugs/the-canvas-passes-draw-one-frame-behind-a-camera-zoom-tween).

var _tween: Tween


## Eases to `point` over `seconds` scaled seconds; 0 cuts.
func move_to(point: Vector2, seconds: float) -> void:
	stop()
	if seconds <= 0.0:
		global_position = point
		return
	_tween = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_property(self, "global_position", point, seconds)

func stop() -> void:
	if _tween != null:
		_tween.kill()
		_tween = null

func is_moving() -> bool:
	return _tween != null and _tween.is_valid() and _tween.is_running()
