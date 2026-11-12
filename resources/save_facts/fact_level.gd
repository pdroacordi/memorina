class_name FactLevel
extends Resource
## One strength a FactWell gives its source while its gates hold (architecture/story-05-playable-flashbacks).

@export var when: Array[SaveFact] = []
@export var unless: Array[SaveFact] = []
## The source's strength, -1..1; 0 hides the source.
@export_range(-1.0, 1.0) var strength: float = 0.0


func holds(data: PlayerData) -> bool:
	return SaveFact.gates_pass(when, unless, data)
