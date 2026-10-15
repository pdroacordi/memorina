class_name DialogueLine
extends Resource
## One line of a talk: a speaker's text, or a question with its choices, or a cue for a scripted beat (systems/dialogue).

@export var speaker: Speaker
## Empty for a cue-only line.
@export var text_key: String = ""
## The line is skipped unless every `when` fact holds and no `unless` fact does.
@export var when: Array[SaveFact] = []
@export var unless: Array[SaveFact] = []
## The first variant that holds replaces `text_key`.
@export var variants: Array[LineVariant] = []
## The question's id in the save; set together with `choices`.
@export var ask_id: StringName = &""
## 2 to 3 answers; empty for a plain line.
@export var choices: Array[DialogueChoice] = []
## A DialogueBeat's cue, played after the line; empty for none.
@export var cue: StringName = &""
## An ITEM fact the director grants as the line shows; null for none.
@export var grants: SaveFact


func holds(data: PlayerData) -> bool:
	return SaveFact.gates_pass(when, unless, data)

func asks() -> bool:
	return not choices.is_empty()

## The text key said under `data`: the first variant that holds, else the line's own.
func text_for(data: PlayerData) -> String:
	for variant: LineVariant in variants:
		if variant.holds(data):
			return variant.text_key
	return text_key
