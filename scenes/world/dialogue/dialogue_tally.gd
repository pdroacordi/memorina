class_name DialogueTally
extends RefCounted
## The quiet tally of design 01 section 9: answers counted by tone. Derived from the save, never stored; read once, by
## Ivo's epilogue lines (architecture/story-07-epilogue, decision 7).


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

## The tone with more answers than every other non-NONE tone; NONE on a tie or with no answers.
static func leans(catalog: DialogueCatalog, data: PlayerData) -> DialogueChoice.Tone:
	var tally := count(catalog, data)
	var best := DialogueChoice.Tone.NONE
	var most := 0
	var tied := false
	for tone: int in tally:
		if tone == DialogueChoice.Tone.NONE:
			continue
		if tally[tone] > most:
			best = tone as DialogueChoice.Tone
			most = tally[tone]
			tied = false
		elif tally[tone] == most and most > 0:
			tied = true
	return DialogueChoice.Tone.NONE if tied else best
