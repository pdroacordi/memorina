class_name DialogueFixture extends RefCounted

## Builds dialogue data in code for the dialogue suites.

static var _voice: Speaker


static func voice() -> Speaker:
	if _voice == null:
		_voice = Speaker.new()
		_voice.id = &"voice"
		_voice.name_key = "SPEAKER_ELDER"
	return _voice

static func fact(kind: SaveFact.Kind, id: StringName = &"", index: int = 0) -> SaveFact:
	var made := SaveFact.new()
	made.kind = kind
	made.id = id
	made.index = index
	return made

static func line(text_key: String, who: Speaker = null) -> DialogueLine:
	var made := DialogueLine.new()
	made.speaker = who if who != null else voice()
	made.text_key = text_key
	return made

static func cue_line(cue: StringName) -> DialogueLine:
	var made := DialogueLine.new()
	made.cue = cue
	return made

static func ask(text_key: String, ask_id: StringName, offered: Array[DialogueChoice]) -> DialogueLine:
	var made := line(text_key)
	made.ask_id = ask_id
	made.choices = offered
	return made

static func choice(id: StringName, text_key: String, tone: DialogueChoice.Tone,
		reply: Array[DialogueLine] = []) -> DialogueChoice:
	var made := DialogueChoice.new()
	made.id = id
	made.text_key = text_key
	made.tone = tone
	made.reply = reply
	return made

static func variant(text_key: String, when: Array[SaveFact]) -> LineVariant:
	var made := LineVariant.new()
	made.text_key = text_key
	made.when = when
	return made

static func dialogue(id: StringName, lines: Array[DialogueLine], once: bool = false) -> Dialogue:
	var made := Dialogue.new()
	made.id = id
	made.lines = lines
	made.once = once
	return made

static func dialogue_set(dialogues: Array[Dialogue]) -> DialogueSet:
	var made := DialogueSet.new()
	made.dialogues = dialogues
	return made

static func catalog(sets: Array[DialogueSet]) -> DialogueCatalog:
	var made := DialogueCatalog.new()
	made.sets = sets
	return made

## A question with a HOLD_ON and a LET_GO answer, each with one reply line.
static func keep_question() -> DialogueLine:
	var hold_reply: Array[DialogueLine] = [line("REPLY_HOLD")]
	var let_reply: Array[DialogueLine] = [line("REPLY_LET_GO")]
	var offered: Array[DialogueChoice] = [
		choice(&"keep_hold", "CHOICE_HOLD", DialogueChoice.Tone.HOLD_ON, hold_reply),
		choice(&"keep_let_go", "CHOICE_LET_GO", DialogueChoice.Tone.LET_GO, let_reply),
	]
	return ask("ASK", &"keep", offered)
