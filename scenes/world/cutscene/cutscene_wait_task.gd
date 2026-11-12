class_name CutsceneWaitTask
extends CutsceneTask
## Over after a number of scaled seconds; `on_end` runs once, when they are up or the scene stops it.

var _left: float = 0.0
var _on_end: Callable


func _init(seconds: float, on_end: Callable = Callable()) -> void:
	_left = seconds
	_on_end = on_end

func tick(delta: float) -> bool:
	_left -= delta
	if _left > 0.0:
		return false
	_end()
	return true

func stop() -> void:
	_end()

func _end() -> void:
	if _on_end.is_valid():
		_on_end.call()
	_on_end = Callable()
