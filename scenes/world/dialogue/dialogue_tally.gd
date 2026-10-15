class_name DialogueTally
extends RefCounted
## The quiet tally of design 01 section 9: answers counted by tone. Derived from the save, never stored; STORY-07
## decides how it is read.


## Recorded answers per `DialogueChoice.Tone`; an answer whose choice the catalog no longer holds is not counted.
static func count(catalog: DialogueCatalog, data: PlayerData) -> Dictionary[int, int]:
	var tally: Dictionary[int, int] = {}
	for tone: int in DialogueChoice.Tone.values():
		tally[tone] = 0
	for ask_id: StringName in data.responses:
		var answer := catalog.choice(data.responses[ask_id])
		if answer != null:
			tally[answer.tone] += 1
	return tally
