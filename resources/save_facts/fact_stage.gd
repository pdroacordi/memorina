class_name FactStage
extends Resource
## One way a FactStaging shows its scene: the child to show while its gates hold (systems/story).

@export var when: Array[SaveFact] = []
@export var unless: Array[SaveFact] = []
## The child shown; empty hides every child.
@export var show: StringName = &""
## Seconds of cross-fade into this stage when the save changes at runtime; 0 cuts.
@export var fade_seconds: float = 0.5


func holds(data: PlayerData) -> bool:
	return SaveFact.gates_pass(when, unless, data)
