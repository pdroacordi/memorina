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

## `seconds` of fade; 0 cuts.
func to_black(seconds: float = DURATION) -> Signal:
	return _tween_color(Color.BLACK, seconds)

func to_clear(seconds: float = DURATION) -> Signal:
	return _tween_color(CLEAR, seconds)

func is_black() -> bool:
	return color.a > 0.0

func _tween_color(final_color: Color, seconds: float) -> Signal:
	if _tween:
		_tween.kill()
	if seconds <= 0.0:
		color = final_color
		faded.emit.call_deferred()
		return faded
	_tween = create_tween().set_ignore_time_scale(real_time)
	_tween.tween_property(self, "color", final_color, seconds)
	_tween.finished.connect(faded.emit)
	return faded
