class_name CutsceneWait
extends CutsceneStep
## Holds the scene still.

## Scaled seconds.
@export var seconds: float = 0.5


func begin(_context: CutsceneContext) -> CutsceneTask:
	return CutsceneWaitTask.new(seconds)
