class_name CutsceneTalk
extends CutsceneStep
## Runs the talker's current dialogue through the DialogueDirector; a skip lands up to it and never chooses for the player.

@export var talk: DialogueSet
## Where the box opens from and Ivo turns to: an actor, a mark or `&"ivo"`.
@export var speaker: StringName = &""
## False only as a scene's last step: the scene ends and the talk goes on.
@export var wait: bool = true


func begin(context: CutsceneContext) -> CutsceneTask:
	var task := context.talk(talk, context.point_of(speaker))
	return task if wait else CutsceneTask.new()

func names() -> Array[StringName]:
	return [speaker]
