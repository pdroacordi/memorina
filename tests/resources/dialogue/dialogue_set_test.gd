class_name DialogueSetTest extends GdUnitTestSuite

## A set's current dialogue is the first open one in priority order; a once dialogue closes when heard; pending is
## current only while unheard.

const F := preload("res://tests/resources/dialogue/dialogue_fixture.gd")
const TRIAL := "res://resources/dialogue/trials/trial_talk.tres"


func _first_then_after() -> DialogueSet:
	var after := F.dialogue(&"after", [F.line("AFTER")])
	after.when = [F.fact(SaveFact.Kind.DIALOGUE_HEARD, &"first")]
	var dialogues: Array[Dialogue] = [F.dialogue(&"first", [F.line("FIRST")], true), after]
	return F.dialogue_set(dialogues)

func test_the_first_open_dialogue_is_current() -> void:
	var data := PlayerData.new()
	assert_str(String(_first_then_after().current(data).id)).is_equal("first")

func test_a_heard_once_dialogue_gives_way_to_the_next() -> void:
	var data := PlayerData.new()
	data.dialogues_heard.append(&"first")
	assert_str(String(_first_then_after().current(data).id)).is_equal("after")

func test_pending_is_current_only_while_unheard() -> void:
	var data := PlayerData.new()
	var dialogue_set := _first_then_after()
	assert_str(String(dialogue_set.pending(data).id)).is_equal("first")
	data.dialogues_heard.append(&"first")
	assert_object(dialogue_set.pending(data)).is_not_null()
	data.dialogues_heard.append(&"after")
	assert_str(String(dialogue_set.current(data).id)).is_equal("after")
	assert_object(dialogue_set.pending(data)).is_null()

func test_nothing_open_is_null() -> void:
	var gated := F.dialogue(&"gated", [F.line("A")])
	gated.unless = [F.fact(SaveFact.Kind.ITEM, &"", Enums.PlayerItem.SWORD)]
	var dialogues: Array[Dialogue] = [gated]
	var data := PlayerData.new()
	data.owned_items[Enums.PlayerItem.SWORD] = true
	assert_object(F.dialogue_set(dialogues).current(data)).is_null()

## The trial fixture: the question first, then the line that answers back.
func test_the_trial_set_asks_then_remembers() -> void:
	var trial := load(TRIAL) as DialogueSet
	var data := PlayerData.new()
	assert_str(String(trial.current(data).id)).is_equal("trial_first")
	data.dialogues_heard.append(&"trial_first")
	data.responses[&"trial_keep"] = &"trial_keep_let_go"
	var after := trial.current(data)
	assert_str(String(after.id)).is_equal("trial_after")
	assert_str(after.lines[0].text_for(data)).is_equal("DIALOGUE_TRIAL_AFTER_01_V2")
