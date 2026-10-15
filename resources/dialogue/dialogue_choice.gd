class_name DialogueChoice
extends Resource
## One answer to a question: its text, its tone for the quiet tally, and the lines said in reply (systems/dialogue).

## How an answer leans, counted by DialogueTally (design 01 section 9). Append only: resources store the int.
enum Tone { NONE, HOLD_ON, LET_GO }

## Unique across the catalog; the save records it as the answer.
@export var id: StringName = &""
@export var text_key: String = ""
@export var tone: Tone = Tone.NONE
## Said after the choice, before the talk rejoins its own lines; never asks again.
@export var reply: Array[DialogueLine] = []
