class_name DialogueRunnerTest extends GdUnitTestSuite

## The runner says lines in order, skips gated ones, resolves variants by the save and by this run's answers, says a
## reply then rejoins, yields LINE then CHOICES or CUE, grants on LINE, repeats END, and writes nothing.

const F := preload("res://tests/resources/dialogue/dialogue_fixture.gd")


func _run(lines: Array[DialogueLine], data: PlayerData = PlayerData.new()) -> DialogueRunner:
	return DialogueRunner.new(F.dialogue(&"talk", lines), data)

## The text keys a run says, answering every question with `pick`.
func _said(runner: DialogueRunner, pick: int = 0) -> PackedStringArray:
	var said := PackedStringArray()
	for i: int in 50:
		match runner.advance():
			DialogueRunner.Step.LINE:
				said.append(runner.text_key())
			DialogueRunner.Step.CHOICES:
				said.append("?%s" % runner.choices()[pick].id)
				runner.choose(pick)
			DialogueRunner.Step.CUE:
				said.append("!%s" % runner.cue())
			DialogueRunner.Step.END:
				return said
	return said

func test_lines_are_said_in_order_then_end_repeats() -> void:
	var runner := _run([F.line("A"), F.line("B")])
	assert_int(runner.advance()).is_equal(DialogueRunner.Step.LINE)
	assert_str(runner.text_key()).is_equal("A")
	assert_object(runner.speaker()).is_same(F.voice())
	assert_int(runner.advance()).is_equal(DialogueRunner.Step.LINE)
	assert_str(runner.text_key()).is_equal("B")
	assert_int(runner.advance()).is_equal(DialogueRunner.Step.END)
	assert_int(runner.advance()).is_equal(DialogueRunner.Step.END)
	assert_object(runner.speaker()).is_null()

func test_when_and_unless_skip_a_line() -> void:
	var gated := F.line("GATED")
	gated.when = [F.fact(SaveFact.Kind.ITEM, &"", Enums.PlayerItem.SWORD)]
	var barred := F.line("BARRED")
	barred.unless = [F.fact(SaveFact.Kind.ITEM, &"", Enums.PlayerItem.SWORD)]
	var lines: Array[DialogueLine] = [F.line("A"), gated, barred]
	assert_array(Array(_said(_run(lines)))).is_equal(["A", "BARRED"])
	var data := PlayerData.new()
	data.owned_items[Enums.PlayerItem.SWORD] = true
	assert_array(Array(_said(_run(lines, data)))).is_equal(["A", "GATED"])

func test_a_variant_follows_the_save() -> void:
	var said := F.line("PLAIN")
	said.variants = [
		F.variant("V_HOLD", [F.fact(SaveFact.Kind.RESPONSE_CHOSEN, &"keep_hold")]),
		F.variant("V_LET_GO", [F.fact(SaveFact.Kind.RESPONSE_CHOSEN, &"keep_let_go")]),
	]
	assert_array(Array(_said(_run([said])))).is_equal(["PLAIN"])
	var data := PlayerData.new()
	data.responses[&"keep"] = &"keep_let_go"
	assert_array(Array(_said(_run([said], data)))).is_equal(["V_LET_GO"])

## A line after the question already follows the answer given in this same talk.
func test_a_variant_follows_a_choice_made_earlier_in_the_run() -> void:
	var after := F.line("PLAIN")
	after.variants = [F.variant("V_HOLD", [F.fact(SaveFact.Kind.RESPONSE_CHOSEN, &"keep_hold")])]
	var lines: Array[DialogueLine] = [F.keep_question(), after]
	assert_array(Array(_said(_run(lines), 0))).is_equal(["ASK", "?keep_hold", "REPLY_HOLD", "V_HOLD"])
	assert_array(Array(_said(_run(lines), 1))).is_equal(["ASK", "?keep_let_go", "REPLY_LET_GO", "PLAIN"])

func test_a_choice_says_its_reply_then_rejoins() -> void:
	var lines: Array[DialogueLine] = [F.line("A"), F.keep_question(), F.line("Z")]
	var runner := _run(lines)
	runner.advance()
	assert_int(runner.advance()).is_equal(DialogueRunner.Step.LINE)
	assert_bool(runner.asks()).is_true()
	assert_str(String(runner.ask_id())).is_equal("keep")
	assert_array(runner.choices()).is_empty()
	assert_int(runner.advance()).is_equal(DialogueRunner.Step.CHOICES)
	assert_int(runner.choices().size()).is_equal(2)
	# Unanswered, the question waits.
	assert_int(runner.advance()).is_equal(DialogueRunner.Step.CHOICES)
	assert_str(String(runner.choose(1).id)).is_equal("keep_let_go")
	assert_int(runner.advance()).is_equal(DialogueRunner.Step.LINE)
	assert_str(runner.text_key()).is_equal("REPLY_LET_GO")
	assert_int(runner.advance()).is_equal(DialogueRunner.Step.LINE)
	assert_str(runner.text_key()).is_equal("Z")
	assert_int(runner.advance()).is_equal(DialogueRunner.Step.END)

func test_a_line_with_a_cue_yields_line_then_cue() -> void:
	var cued := F.line("A")
	cued.cue = &"guitar"
	assert_array(Array(_said(_run([cued, F.line("B")])))).is_equal(["A", "!guitar", "B"])

func test_a_cue_only_line_yields_only_the_cue() -> void:
	var runner := _run([F.cue_line(&"guitar"), F.line("B")])
	assert_int(runner.advance()).is_equal(DialogueRunner.Step.CUE)
	assert_str(String(runner.cue())).is_equal("guitar")
	assert_int(runner.advance()).is_equal(DialogueRunner.Step.LINE)
	assert_str(String(runner.cue())).is_empty()

func test_a_grant_is_offered_on_its_line_only() -> void:
	var giving := F.line("A")
	giving.grants = F.fact(SaveFact.Kind.ITEM, &"", Enums.PlayerItem.MEMORINA)
	giving.cue = &"guitar"
	var runner := _run([giving])
	runner.advance()
	assert_object(runner.grant()).is_same(giving.grants)
	runner.advance()
	assert_object(runner.grant()).is_null()

func test_the_run_writes_nothing_to_the_save() -> void:
	var data := PlayerData.new()
	_said(_run([F.keep_question()], data))
	assert_bool(data.responses.is_empty()).is_true()
	assert_array(data.dialogues_heard).is_empty()
