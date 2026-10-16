class_name CutsceneBranch
extends CutsceneStep
## Plays the first case that holds, read when the branch is reached (the DialogueSet.current idiom); none plays nothing.

@export var cases: Array[CutsceneCase] = []


## The steps of the first case that holds under `data`; empty when none does.
func pick(data: PlayerData) -> Array[CutsceneStep]:
	for case: CutsceneCase in cases:
		if case != null and case.holds(data):
			return case.steps
	return []
