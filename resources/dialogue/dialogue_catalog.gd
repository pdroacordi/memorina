class_name DialogueCatalog
extends Resource
## Every dialogue set in the game; `validate()` holds the rules a set's data must keep (systems/dialogue).

const MIN_CHOICES := 2
const MAX_CHOICES := 3

@export var sets: Array[DialogueSet] = []


## A loaded set is the cached instance of its file, so the same path is the same object.
func has_set(dialogue_set: DialogueSet) -> bool:
	return dialogue_set != null and sets.has(dialogue_set)

func dialogues() -> Array[Dialogue]:
	var found: Array[Dialogue] = []
	for dialogue_set: DialogueSet in sets:
		if dialogue_set != null:
			for dialogue: Dialogue in dialogue_set.dialogues:
				if dialogue != null:
					found.append(dialogue)
	return found

## Every line of every dialogue, replies included, in order.
func lines() -> Array[DialogueLine]:
	var found: Array[DialogueLine] = []
	for dialogue: Dialogue in dialogues():
		_collect(dialogue.lines, found)
	return found

func choices() -> Array[DialogueChoice]:
	var found: Array[DialogueChoice] = []
	for line: DialogueLine in lines():
		for choice: DialogueChoice in line.choices:
			if choice != null:
				found.append(choice)
	return found

## The choice with `id`; null when no line offers it.
func choice(id: StringName) -> DialogueChoice:
	for found: DialogueChoice in choices():
		if found.id == id:
			return found
	return null

## The problems found, one line each; empty when the catalog is sound.
func validate() -> PackedStringArray:
	var problems := PackedStringArray()
	var dialogue_ids: Dictionary[StringName, bool] = {}
	for dialogue_set: DialogueSet in sets:
		if dialogue_set == null or dialogue_set.dialogues.is_empty():
			problems.append("an empty set")
			continue
		for dialogue: Dialogue in dialogue_set.dialogues:
			if dialogue == null:
				problems.append("an empty dialogue slot")
				continue
			if dialogue.id == &"" or dialogue_ids.has(dialogue.id):
				problems.append("dialogue id '%s' is empty or not unique" % dialogue.id)
			dialogue_ids[dialogue.id] = true
			if dialogue.lines.is_empty():
				problems.append("%s has no lines" % dialogue.id)
	var choice_ids: Dictionary[StringName, bool] = {}
	var ask_ids: Dictionary[StringName, bool] = {}
	for line: DialogueLine in lines():
		if line.asks():
			if line.ask_id == &"" or ask_ids.has(line.ask_id):
				problems.append("ask id '%s' is empty or not unique" % line.ask_id)
			ask_ids[line.ask_id] = true
			for answer: DialogueChoice in line.choices:
				if answer == null or answer.id == &"" or choice_ids.has(answer.id):
					problems.append("%s: a choice id is empty or not unique" % line.ask_id)
					continue
				choice_ids[answer.id] = true
	for dialogue: Dialogue in dialogues():
		problems.append_array(_facts_problems(dialogue.when, dialogue.unless, dialogue.id, dialogue_ids, choice_ids))
		problems.append_array(_lines_problems(dialogue.lines, dialogue.id, false, dialogue_ids, choice_ids))
	return problems

func _collect(from: Array[DialogueLine], into: Array[DialogueLine]) -> void:
	for line: DialogueLine in from:
		if line == null:
			continue
		into.append(line)
		for answer: DialogueChoice in line.choices:
			if answer != null:
				_collect(answer.reply, into)

func _lines_problems(from: Array[DialogueLine], where: StringName, in_reply: bool,
		dialogue_ids: Dictionary[StringName, bool], choice_ids: Dictionary[StringName, bool]) -> PackedStringArray:
	var problems := PackedStringArray()
	for i: int in from.size():
		var line := from[i]
		var at := "%s line %d" % [where, i]
		if line == null:
			problems.append("%s is empty" % at)
			continue
		if line.text_key.is_empty() and line.cue == &"" and not line.asks():
			problems.append("%s has no text and no cue" % at)
		if not line.text_key.is_empty() and line.speaker == null:
			problems.append("%s has text and no speaker" % at)
		var keys: Array[String] = [line.text_key]
		for variant: LineVariant in line.variants:
			if variant == null or variant.text_key.is_empty():
				problems.append("%s has a variant with no text" % at)
				continue
			keys.append(variant.text_key)
			problems.append_array(_facts_problems(variant.when, variant.unless, at, dialogue_ids, choice_ids))
		if not line.variants.is_empty() and line.text_key.is_empty():
			problems.append("%s has variants but no text" % at)
		problems.append_array(_facts_problems(line.when, line.unless, at, dialogue_ids, choice_ids))
		if line.grants != null:
			if line.grants.kind != SaveFact.Kind.ITEM:
				problems.append("%s grants a fact that is not an ITEM" % at)
			if line.text_key.is_empty() and line.cue == &"":
				problems.append("%s grants with no text and no cue" % at)
		if line.asks():
			if in_reply:
				problems.append("%s asks inside a reply" % at)
			if line.choices.size() < MIN_CHOICES or line.choices.size() > MAX_CHOICES:
				problems.append("%s offers %d choices, not %d..%d" % [at, line.choices.size(), MIN_CHOICES, MAX_CHOICES])
			# A silent ask (a gesture) has no question, no speaker and no variants.
			if line.text_key.is_empty() and line.speaker != null:
				problems.append("%s asks silently but names a speaker" % at)
			if line.cue != &"":
				problems.append("%s both asks and cues" % at)
			for answer: DialogueChoice in line.choices:
				if answer == null:
					continue
				keys.append(answer.text_key)
				if answer.text_key.is_empty():
					problems.append("%s: choice %s has no text" % [at, answer.id])
				if not answer.tone in DialogueChoice.Tone.values():
					problems.append("%s: choice %s has tone %d" % [at, answer.id, answer.tone])
				problems.append_array(_lines_problems(answer.reply, answer.id, true, dialogue_ids, choice_ids))
		elif line.ask_id != &"":
			problems.append("%s has an ask id and no choices" % at)
		for key: String in keys:
			if key.contains("\n") or key.contains(" "):
				problems.append("%s: key '%s' is not one token" % [at, key.c_escape()])
	return problems

func _facts_problems(when: Array[SaveFact], unless: Array[SaveFact], at: String,
		dialogue_ids: Dictionary[StringName, bool], choice_ids: Dictionary[StringName, bool]) -> PackedStringArray:
	var problems := PackedStringArray()
	var facts: Array[SaveFact] = []
	facts.append_array(when)
	facts.append_array(unless)
	for fact: SaveFact in facts:
		if fact == null:
			problems.append("%s has an empty fact" % at)
		elif fact.kind == SaveFact.Kind.DIALOGUE_HEARD and not dialogue_ids.has(fact.id):
			problems.append("%s reads heard '%s', no such dialogue" % [at, fact.id])
		elif fact.kind == SaveFact.Kind.RESPONSE_CHOSEN and not choice_ids.has(fact.id):
			problems.append("%s reads choice '%s', no such choice" % [at, fact.id])
	return problems
