class_name LineVariant
extends Resource
## Another text for a line, said while its gates hold: how a later line follows an earlier answer (systems/dialogue).

@export var when: Array[SaveFact] = []
@export var unless: Array[SaveFact] = []
@export var text_key: String = ""


func holds(data: PlayerData) -> bool:
	return SaveFact.gates_pass(when, unless, data)
