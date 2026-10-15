class_name DialogueRunner
extends RefCounted
## Steps through one dialogue against a save: which line is said, with which text, and where a choice leads. Pure: it
## writes nothing to the save (architecture/dialogue-is-data-and-choices-are-save-facts).

## LINE shows a line; CHOICES offers the asking line's choices; CUE hands off to a scripted beat; END is the end and
## repeats.
enum Step { LINE, CHOICES, CUE, END }

var _dialogue: Dialogue
## The save as this run reads it: `data` plus the answers chosen in this run.
var _view: PlayerData
## Lines still to say, the next first.
var _queue: Array[DialogueLine] = []
## The line LINE, CHOICES or CUE is about; null at END.
var _line: DialogueLine
## What the current line still owes after LINE: CHOICES, CUE, or END for nothing.
var _owed: Step = Step.END
var _step: Step = Step.END
var _waiting_for_choice: bool = false


func _init(dialogue: Dialogue, data: PlayerData) -> void:
	_dialogue = dialogue
	_view = data.duplicate() as PlayerData
	_view.responses = data.responses.duplicate()
	_queue.assign(dialogue.lines)

func dialogue() -> Dialogue:
	return _dialogue

func advance() -> Step:
	if _waiting_for_choice:
		return Step.CHOICES
	if _owed != Step.END:
		_step = _owed
		_owed = Step.END
		_waiting_for_choice = _step == Step.CHOICES
		return _step
	while not _queue.is_empty():
		var line: DialogueLine = _queue.pop_front()
		if not line.holds(_view):
			continue
		_line = line
		_owed = Step.CHOICES if line.asks() else (Step.CUE if line.cue != &"" else Step.END)
		if line.text_key.is_empty():
			return advance()
		_step = Step.LINE
		return _step
	_line = null
	_step = Step.END
	return _step

func step() -> Step:
	return _step

func speaker() -> Speaker:
	return _line.speaker if _line != null else null

## The text key said on LINE, its variant resolved against this run's answers.
func text_key() -> String:
	return _line.text_for(_view) if _line != null else ""

## The ITEM fact granted now: on a LINE, or on the CUE of a cue-only line (as its beat starts); null for none.
func grant() -> SaveFact:
	if _line == null:
		return null
	if _step == Step.LINE or (_step == Step.CUE and _line.text_key.is_empty()):
		return _line.grants
	return null

## Whether the current line is a gesture: it asks with no question.
func silent() -> bool:
	return _line != null and _line.asks() and _line.text_key.is_empty()

## Whether the current line goes on to CHOICES.
func asks() -> bool:
	return _line != null and _line.asks()

func ask_id() -> StringName:
	return _line.ask_id if _line != null else &""

func choices() -> Array[DialogueChoice]:
	var offered: Array[DialogueChoice] = []
	if _step == Step.CHOICES:
		offered.assign(_line.choices)
	return offered

## Answers the question with choice `index`: its reply is said next, then the talk rejoins its lines.
func choose(index: int) -> DialogueChoice:
	assert(_waiting_for_choice, "choose() answers CHOICES")
	var picked: DialogueChoice = _line.choices[index]
	_waiting_for_choice = false
	_view.responses[_line.ask_id] = picked.id
	var next: Array[DialogueLine] = []
	next.assign(picked.reply)
	next.append_array(_queue)
	_queue = next
	return picked

func cue() -> StringName:
	return _line.cue if _step == Step.CUE else &""
