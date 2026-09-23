class_name Fade
extends ColorRect

## The screen reached the colour the latest fade asked for. What to_black() and
## to_clear() hand back to await: a fade started while another runs kills that
## tween, and a killed tween never emits its own `finished` - whoever awaited
## it would wait for ever. This fires for every fade that lands, so an
## interrupted awaiter resumes when the fade that replaced it does.
signal faded

const CLEAR    : Color = Color(0,0,0,0)
const DURATION : float = 0.5

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
	_tween = create_tween()
	_tween.tween_property(self, "color", final_color, DURATION)
	_tween.finished.connect(faded.emit)
	return faded
