class_name CutsceneYear
extends CutsceneStep
## Passes the region's year once round over `seconds`, ending on the season it began on; a skip or the scene's end
## settles it there (architecture/story-07-epilogue, decision 4).

const SUBJECT := &"year"

## Scaled seconds for the whole year.
@export var seconds: float = 60.0


func begin(context: CutsceneContext) -> CutsceneTask:
	context.run_year(seconds)
	return CutsceneWaitTask.new(seconds)

func land(context: CutsceneContext) -> void:
	context.settle_year()

func subjects() -> Array[StringName]:
	return [SUBJECT]

func names() -> Array[StringName]:
	return []
