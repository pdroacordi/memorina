class_name Fade
extends ColorRect

## Emitted when a fade reaches its target; a replacement fade completes interrupted awaiters.
signal faded

const CLEAR    : Color = Color(0,0,0,0)
const DURATION : float = 0.5

## Fades in real seconds; true for a fade shown under a menu hold, where the time scale is 0.
@export var real_time: bool = false

var _tween: Tween

func _ready() -> void:
	visible = true

func to_black() -> Signal:
	return _tween_color(Color.BLACK)
	
func to_clear() -> Signal:
	return _tween_color(CLEAR)
	
func _tween_color(final_color: Color) -> Signal:
	if _tween:
		_tween.kill()
	_tween = create_tween().set_ignore_time_scale(real_time)
	_tween.tween_property(self, "color", final_color, DURATION)
	_tween.finished.connect(faded.emit)
	return faded
