class_name Intent
extends Resource
## Where Ivo means to go next, while its gates hold (systems/notices).

## Unique across the catalog.
@export var id: StringName = &""
@export var text_key: String = ""
## The intent holds while every `when` fact holds and no `unless` fact does.
@export var when: Array[SaveFact] = []
@export var unless: Array[SaveFact] = []


func holds(data: PlayerData) -> bool:
	return SaveFact.gates_pass(when, unless, data)

func facts() -> Array[SaveFact]:
	var all: Array[SaveFact] = []
	all.append_array(when)
	all.append_array(unless)
	return all
