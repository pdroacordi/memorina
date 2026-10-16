class_name DialogueCatalogTest extends GdUnitTestSuite

## The shipped catalog is sound, and validate() names each broken rule.

const F := preload("res://tests/resources/dialogue/dialogue_fixture.gd")
const SHIPPED := "res://resources/dialogue/dialogue_catalog.tres"
const CSV := "res://i18n/translations.csv"
const SPEAKERS := "res://resources/dialogue/speakers/"


func _one(lines: Array[DialogueLine], id: StringName = &"talk") -> DialogueCatalog:
	var dialogues: Array[Dialogue] = [F.dialogue(id, lines)]
	var sets: Array[DialogueSet] = [F.dialogue_set(dialogues)]
	return F.catalog(sets)

func _problems(lines: Array[DialogueLine]) -> String:
	return "\n".join(_one(lines).validate())

func test_the_shipped_catalog_is_sound() -> void:
	var catalog := load(SHIPPED) as DialogueCatalog
	assert_object(catalog).is_not_null()
	assert_array(Array(catalog.validate())).is_empty()

## Every text key the catalog says, and every speaker's name, has a row in the CSV.
func test_every_shipped_key_has_a_row() -> void:
	var catalog := load(SHIPPED) as DialogueCatalog
	var rows: Dictionary[String, bool] = {}
	var file := FileAccess.open(CSV, FileAccess.READ)
	file.get_csv_line()
	while not file.eof_reached():
		var row := file.get_csv_line()
		if row.size() > 0 and not row[0].is_empty():
			rows[row[0]] = true
	var keys: Array[String] = []
	for line: DialogueLine in catalog.lines():
		keys.append(line.text_key)
		for variant: LineVariant in line.variants:
			keys.append(variant.text_key)
		for answer: DialogueChoice in line.choices:
			keys.append(answer.text_key)
		if line.speaker != null:
			keys.append(line.speaker.name_key)
	for key: String in keys:
		if not key.is_empty():
			assert_bool(rows.has(key)).override_failure_message("%s has no row" % key).is_true()

## UI-13: everyone who speaks on screen has a portrait; only the voice from offscreen has none.
func test_every_shipped_speaker_has_a_portrait_but_the_offscreen_voice() -> void:
	var files := Array(ResourceLoader.list_directory(SPEAKERS)).filter(func(f: String) -> bool: return f.ends_with(".tres"))
	assert_array(files).is_not_empty()
	for file: String in files:
		var speaker := load(SPEAKERS + file) as Speaker
		var offscreen := speaker.id == &"elder_offscreen"
		assert_bool(speaker.portrait == null).override_failure_message(file).is_equal(offscreen)

func test_a_sound_dialogue_has_no_problems() -> void:
	assert_str(_problems([F.line("A"), F.keep_question(), F.cue_line(&"guitar")])).is_empty()

func test_duplicate_dialogue_ids_are_named() -> void:
	var dialogues: Array[Dialogue] = [F.dialogue(&"talk", [F.line("A")]), F.dialogue(&"talk", [F.line("B")])]
	var sets: Array[DialogueSet] = [F.dialogue_set(dialogues)]
	assert_str("\n".join(F.catalog(sets).validate())).contains("not unique")

func test_duplicate_choice_ids_are_named() -> void:
	var sets: Array[DialogueSet] = [
		F.dialogue_set([F.dialogue(&"one", [F.keep_question()])]),
		F.dialogue_set([F.dialogue(&"two", [F.keep_question()])]),
	]
	var problems := "\n".join(F.catalog(sets).validate())
	assert_str(problems).contains("ask id 'keep'")
	assert_str(problems).contains("a choice id is empty or not unique")

func test_one_choice_or_four_are_refused() -> void:
	var one: Array[DialogueChoice] = [F.choice(&"a", "A", DialogueChoice.Tone.NONE)]
	assert_str(_problems([F.ask("ASK", &"q", one)])).contains("offers 1 choices")
	var four: Array[DialogueChoice] = []
	for id: StringName in [&"a", &"b", &"c", &"d"]:
		four.append(F.choice(id, "X", DialogueChoice.Tone.NONE))
	assert_str(_problems([F.ask("ASK", &"q", four)])).contains("offers 4 choices")

func test_a_question_inside_a_reply_is_refused() -> void:
	var nested: Array[DialogueLine] = [F.keep_question()]
	var offered: Array[DialogueChoice] = [
		F.choice(&"x", "X", DialogueChoice.Tone.NONE, nested),
		F.choice(&"y", "Y", DialogueChoice.Tone.NONE),
	]
	assert_str(_problems([F.ask("ASK", &"outer", offered)])).contains("asks inside a reply")

func test_a_grant_must_be_an_item_on_a_text_or_cue_line() -> void:
	var song := F.line("A")
	song.grants = F.fact(SaveFact.Kind.SONG, &"", Enums.Song.ROOT)
	assert_str(_problems([song])).contains("not an ITEM")
	var gift := F.cue_line(&"mentor_gift")
	gift.grants = F.fact(SaveFact.Kind.ITEM, &"", Enums.PlayerItem.MEMORINA)
	assert_str(_problems([gift])).is_empty()

## A gesture is a silent ask: no question, no speaker, no variants; its choices only (systems/story).
func test_a_silent_ask_is_valid_and_a_named_one_is_not() -> void:
	var gesture := F.ask("", &"morning_song", [
		F.choice(&"try_again", "TRY", DialogueChoice.Tone.HOLD_ON),
		F.choice(&"lower", "LOWER", DialogueChoice.Tone.LET_GO),
	])
	gesture.speaker = null
	assert_str(_problems([gesture])).is_empty()
	var named := F.ask("", &"named", [
		F.choice(&"a", "A", DialogueChoice.Tone.NONE),
		F.choice(&"b", "B", DialogueChoice.Tone.NONE),
	])
	assert_str(_problems([named])).contains("asks silently but names a speaker")

func test_facts_must_name_known_dialogues_and_choices() -> void:
	var gated := F.line("A")
	gated.when = [F.fact(SaveFact.Kind.DIALOGUE_HEARD, &"nobody"), F.fact(SaveFact.Kind.RESPONSE_CHOSEN, &"nothing")]
	var problems := _problems([gated])
	assert_str(problems).contains("no such dialogue")
	assert_str(problems).contains("no such choice")
	var known := F.line("B")
	known.when = [F.fact(SaveFact.Kind.DIALOGUE_HEARD, &"talk"), F.fact(SaveFact.Kind.RESPONSE_CHOSEN, &"keep_hold")]
	assert_str(_problems([F.keep_question(), known])).is_empty()

func test_a_line_needs_text_or_a_cue_and_a_speaker_for_its_text() -> void:
	var empty := DialogueLine.new()
	assert_str(_problems([empty])).contains("no text and no cue")
	var mute := F.line("A")
	mute.speaker = null
	assert_str(_problems([mute])).contains("no speaker")

func test_a_key_with_a_newline_is_refused() -> void:
	assert_str(_problems([F.line("A\nB")])).contains("not one token")

func test_choice_finds_by_id() -> void:
	var catalog := _one([F.keep_question()])
	assert_str(catalog.choice(&"keep_let_go").text_key).is_equal("CHOICE_LET_GO")
	assert_object(catalog.choice(&"missing")).is_null()
	assert_int(catalog.lines().size()).is_equal(3)
