class_name CutsceneCredits
extends CutsceneStep
## Rolls a credits sheet on the CreditsRoll and waits until the logo has held at its end (architecture/story-07-epilogue,
## "The credits").

const SUBJECT := &"credits"

@export var sheet: CreditsSheet


func begin(context: CutsceneContext) -> CutsceneTask:
	context.roll_credits(sheet)
	return CutsceneUntilTask.new(context.credits_done)

func land(context: CutsceneContext) -> void:
	context.land_credits()

func subjects() -> Array[StringName]:
	return [SUBJECT]

func names() -> Array[StringName]:
	return []
