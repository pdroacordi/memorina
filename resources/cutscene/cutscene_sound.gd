class_name CutsceneSound
extends CutsceneStep
## A scene voice; the scene's end and CutsceneSilence stop it, and a skip never plays it.

@export var stream: AudioStream
## Waits until it has played out.
@export var wait: bool = false


func begin(context: CutsceneContext) -> CutsceneTask:
	var task := context.sound(stream)
	return task if wait else CutsceneTask.new()
