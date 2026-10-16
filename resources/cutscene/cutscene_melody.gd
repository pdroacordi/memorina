class_name CutsceneMelody
extends CutsceneStep
## A Melody's notes through a MelodyPlayer, on the pausable scaled clock; a skip never plays it.

@export var melody: Melody
## Notes played; negative plays them all.
@export var count: int = -1
## One voice per Enums.Note.
@export var voices: Array[AudioStream] = []
@export var wait: bool = true


func begin(context: CutsceneContext) -> CutsceneTask:
	var task := context.melody(melody, count, voices)
	return task if wait else CutsceneTask.new()
