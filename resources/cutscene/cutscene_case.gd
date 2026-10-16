class_name CutsceneCase
extends Resource
## One way a CutsceneBranch goes: its steps play while its gates hold when the branch is reached.

@export var when: Array[SaveFact] = []
@export var unless: Array[SaveFact] = []
@export var steps: Array[CutsceneStep] = []


func holds(data: PlayerData) -> bool:
	return SaveFact.gates_pass(when, unless, data)
