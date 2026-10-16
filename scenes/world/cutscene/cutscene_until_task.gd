class_name CutsceneUntilTask
extends CutsceneTask
## Over once `until` answers true; `on_stop` runs if the scene stops it first.

var _until: Callable
var _on_stop: Callable


func _init(until: Callable, on_stop: Callable = Callable()) -> void:
	_until = until
	_on_stop = on_stop

func tick(_delta: float) -> bool:
	return not _until.is_valid() or bool(_until.call())

func stop() -> void:
	if _on_stop.is_valid():
		_on_stop.call()
