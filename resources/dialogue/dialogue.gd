class_name Dialogue
extends Resource
## One conversation: its lines in order, and when it may be said (systems/dialogue).

## Unique across the catalog; the save marks it heard by this id.
@export var id: StringName = &""
## Skipped once heard.
@export var once: bool = false
## An auto start says it on every approach, heard or not (STORY-33's turn-back).
@export var repeats: bool = false
@export var when: Array[SaveFact] = []
@export var unless: Array[SaveFact] = []
@export var lines: Array[DialogueLine] = []
## The camera frames the speaker and Ivo at this zoom while the talk runs (STORY-16); 0 leaves the frame alone.
@export var zoom: float = 0.0
## The frame cuts to the talk's pair and zoom instead of easing there; read only when `zoom` is set.
@export var cut: bool = false
## Px the framed talk's centre rises above Ivo's framing, to keep what stands over the pair in view; read only when
## `zoom` is set.
@export var frame_lift: float = 0.0


## Its gates hold, and it is not a heard `once` dialogue.
func is_open_for(data: PlayerData) -> bool:
	if once and data.dialogues_heard.has(id):
		return false
	return SaveFact.gates_pass(when, unless, data)
