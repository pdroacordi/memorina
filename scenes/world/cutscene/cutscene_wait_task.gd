class_name CutsceneWaitTask
extends CutsceneTask
## Over after a number of scaled seconds.

var _left: float = 0.0


func _init(seconds: float) -> void:
	_left = seconds

func tick(delta: float) -> bool:
	_left -= delta
	return _left <= 0.0
