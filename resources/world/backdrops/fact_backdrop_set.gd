class_name FactBackdropSet
extends Resource
## One set a FactBackdrop gives its Backdrop while its gates hold (architecture/story-05-playable-flashbacks).

@export var when: Array[SaveFact] = []
@export var unless: Array[SaveFact] = []
@export var backdrop_set: BackdropSet


func holds(data: PlayerData) -> bool:
	return SaveFact.gates_pass(when, unless, data)
