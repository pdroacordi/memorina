class_name DialogueTallyTest extends GdUnitTestSuite

## The tally counts recorded answers by tone, once per question, from the save alone.

const F := preload("res://tests/resources/dialogue/dialogue_fixture.gd")


func _catalog() -> DialogueCatalog:
	var other_hold: Array[DialogueChoice] = [
		F.choice(&"stay", "STAY", DialogueChoice.Tone.HOLD_ON),
		F.choice(&"shrug", "SHRUG", DialogueChoice.Tone.NONE),
	]
	var lines: Array[DialogueLine] = [F.keep_question(), F.ask("ASK_2", &"stay_or_go", other_hold)]
	var dialogues: Array[Dialogue] = [F.dialogue(&"talk", lines)]
	var sets: Array[DialogueSet] = [F.dialogue_set(dialogues)]
	return F.catalog(sets)

func test_nothing_answered_counts_zero_for_every_tone() -> void:
	var tally := DialogueTally.count(_catalog(), PlayerData.new())
	assert_int(tally.size()).is_equal(DialogueChoice.Tone.size())
	for tone: int in DialogueChoice.Tone.values():
		assert_int(tally[tone]).is_equal(0)

func test_answers_count_by_tone() -> void:
	var data := PlayerData.new()
	data.responses[&"keep"] = &"keep_hold"
	data.responses[&"stay_or_go"] = &"stay"
	var tally := DialogueTally.count(_catalog(), data)
	assert_int(tally[DialogueChoice.Tone.HOLD_ON]).is_equal(2)
	assert_int(tally[DialogueChoice.Tone.LET_GO]).is_equal(0)

func test_a_question_asked_again_counts_once() -> void:
	var data := PlayerData.new()
	data.responses[&"keep"] = &"keep_hold"
	data.responses[&"keep"] = &"keep_let_go"
	var tally := DialogueTally.count(_catalog(), data)
	assert_int(tally[DialogueChoice.Tone.HOLD_ON]).is_equal(0)
	assert_int(tally[DialogueChoice.Tone.LET_GO]).is_equal(1)

func test_an_answer_the_catalog_no_longer_has_is_not_counted() -> void:
	var data := PlayerData.new()
	data.responses[&"gone"] = &"removed_choice"
	var tally := DialogueTally.count(_catalog(), data)
	for tone: int in DialogueChoice.Tone.values():
		assert_int(tally[tone]).is_equal(0)
