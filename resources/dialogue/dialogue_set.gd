class_name DialogueSet
extends Resource
## One talker's dialogues in priority order (systems/dialogue).

@export var dialogues: Array[Dialogue] = []


## The first dialogue open under `data`; null when none is.
func current(data: PlayerData) -> Dialogue:
	for dialogue: Dialogue in dialogues:
		if dialogue.is_open_for(data):
			return dialogue
	return null

## `current` while it is not yet heard: what an auto start says.
func pending(data: PlayerData) -> Dialogue:
	var dialogue := current(data)
	if dialogue == null or data.dialogues_heard.has(dialogue.id):
		return null
	return dialogue
