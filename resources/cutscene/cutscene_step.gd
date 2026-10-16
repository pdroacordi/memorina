class_name CutsceneStep
extends Resource
## One step of a Cutscene: `begin` starts it and returns what it waits on, `land` puts its end state at once (a skip).

## The id that names Ivo in any step.
const IVO := &"ivo"


func begin(_context: CutsceneContext) -> CutsceneTask:
	return CutsceneTask.new()

func land(_context: CutsceneContext) -> void:
	pass

## What the step moves or poses; two steps of one CutsceneTogether never share one.
func subjects() -> Array[StringName]:
	return []

## Ids the step reads that must resolve in its host's contents (actors, marks, visuals).
func names() -> Array[StringName]:
	return subjects()
