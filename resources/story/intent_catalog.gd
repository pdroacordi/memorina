class_name IntentCatalog
extends Resource
## Every intent in priority order; the current one is the first that holds, as `DialogueSet.current` picks a talk
## (systems/notices).

@export var intents: Array[Intent] = []


## The first intent that holds under `data`; null when none does.
func current(data: PlayerData) -> Intent:
	for intent: Intent in intents:
		if intent.holds(data):
			return intent
	return null

## The problems found, one line each; empty when the catalog is sound.
func validate() -> PackedStringArray:
	var problems := PackedStringArray()
	var ids: Dictionary[StringName, bool] = {}
	for intent: Intent in intents:
		if intent == null:
			problems.append("an empty slot")
			continue
		if intent.id == &"" or ids.has(intent.id):
			problems.append("id '%s' is empty or not unique" % intent.id)
		ids[intent.id] = true
		if intent.text_key.is_empty() or intent.text_key.contains(" ") or intent.text_key.contains("\n"):
			problems.append("%s has no usable text key ('%s')" % [intent.id, intent.text_key])
		for fact: SaveFact in intent.facts():
			if fact == null:
				problems.append("%s has an empty fact" % intent.id)
			elif fact.kind in [SaveFact.Kind.DIALOGUE_HEARD, SaveFact.Kind.RESPONSE_CHOSEN, SaveFact.Kind.SCENE_SEEN] \
					and fact.id == &"":
				problems.append("%s reads a fact with no id" % intent.id)
	return problems
