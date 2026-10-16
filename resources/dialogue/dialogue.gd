class_name Dialogue
extends Resource
## One conversation: its lines in order, and when it may be said (systems/dialogue).

## Unique across the catalog; the save marks it heard by this id.
@export var id: StringName = &""
## Skipped once heard.
@export var once: bool = false
@export var when: Array[SaveFact] = []
@export var unless: Array[SaveFact] = []
@export var lines: Array[DialogueLine] = []
## The camera frames the speaker and Ivo at this zoom while the talk runs (STORY-16); 0 leaves the frame alone.
@export var zoom: float = 0.0


## Its gates hold, and it is not a heard `once` dialogue.
func is_open_for(data: PlayerData) -> bool:
	if once and data.dialogues_heard.has(id):
		return false
	return SaveFact.gates_pass(when, unless, data)
