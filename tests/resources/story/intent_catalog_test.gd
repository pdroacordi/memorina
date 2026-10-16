class_name IntentCatalogTest extends GdUnitTestSuite

## The shipped intents are sound, follow the opening's talks one at a time, and every text has both languages
## (systems/notices).

const SHIPPED := "res://resources/story/intent_catalog.tres"
const DIALOGUES := "res://resources/dialogue/dialogue_catalog.tres"
const CSV := "res://i18n/translations.csv"


func _catalog() -> IntentCatalog:
	return load(SHIPPED) as IntentCatalog

func _intent(id: StringName, key: String, when: Array[SaveFact] = [], unless: Array[SaveFact] = []) -> Intent:
	var intent := Intent.new()
	intent.id = id
	intent.text_key = key
	intent.when = when
	intent.unless = unless
	return intent

func _heard(id: StringName) -> SaveFact:
	var fact := SaveFact.new()
	fact.kind = SaveFact.Kind.DIALOGUE_HEARD
	fact.id = id
	return fact

func _current_id(data: PlayerData) -> StringName:
	var intent := _catalog().current(data)
	return intent.id if intent != null else &""

func test_the_shipped_catalog_is_sound() -> void:
	assert_object(_catalog()).is_not_null()
	assert_array(Array(_catalog().validate())).is_empty()

func test_a_duplicate_or_empty_id_is_reported() -> void:
	var catalog := IntentCatalog.new()
	catalog.intents = [_intent(&"a", "A"), _intent(&"a", "B"), _intent(&"", "C")]
	assert_int(catalog.validate().size()).is_equal(2)

func test_a_missing_or_spaced_text_key_is_reported() -> void:
	var catalog := IntentCatalog.new()
	catalog.intents = [_intent(&"a", ""), _intent(&"b", "TWO WORDS")]
	assert_int(catalog.validate().size()).is_equal(2)

func test_a_heard_fact_with_no_id_is_reported() -> void:
	var catalog := IntentCatalog.new()
	catalog.intents = [_intent(&"a", "A", [_heard(&"")])]
	assert_str(", ".join(catalog.validate())).contains("a reads a fact with no id")

## The first that holds, as DialogueSet.current picks a talk.
func test_the_current_intent_is_the_first_that_holds() -> void:
	var catalog := IntentCatalog.new()
	catalog.intents = [_intent(&"late", "L", [_heard(&"x")]), _intent(&"always", "A"), _intent(&"never", "N", [_heard(&"y")])]
	var data := PlayerData.new()
	assert_str(String(catalog.current(data).id)).is_equal("always")
	data.dialogues_heard.append(&"x")
	assert_str(String(catalog.current(data).id)).is_equal("late")
	assert_object(IntentCatalog.new().current(data)).is_null()

## The opening's flow (design 05, draft 3): none until she asks, then the bread, home, the elder's story, the lighthouse
## east, back to the village; then none until the next is written.
func test_the_intent_follows_the_opening() -> void:
	var data := PlayerData.new()
	assert_str(String(_current_id(data))).is_equal("")
	data.dialogues_heard.append(&"daughter_errand")
	assert_str(String(_current_id(data))).is_equal("bread")
	data.dialogues_heard.append(&"baker_errand")
	assert_str(String(_current_id(data))).is_equal("home")
	data.dialogues_heard.append(&"daughter_song")
	assert_str(String(_current_id(data))).is_equal("elder")
	data.dialogues_heard.append(&"elder_story")
	assert_str(String(_current_id(data))).is_equal("east")
	data.dialogues_heard.append(&"mentor_gift")
	assert_str(String(_current_id(data))).is_equal("village")
	data.dialogues_heard.append(&"elder_return")
	assert_str(String(_current_id(data))).is_equal("")

## The intents read talks, as the house does (systems/story): owning the items early (a playtest's kit) changes nothing.
func test_owned_items_do_not_move_the_intent() -> void:
	var data := PlayerData.new()
	data.owned_items.fill(true)
	assert_str(String(_current_id(data))).is_equal("")
	data.dialogues_heard.append(&"daughter_errand")
	assert_str(String(_current_id(data))).is_equal("bread")

func test_at_most_one_intent_holds_at_each_step_of_the_opening() -> void:
	var data := PlayerData.new()
	for heard: StringName in [&"", &"daughter_errand", &"baker_errand", &"daughter_song", &"elder_story", &"mentor_gift", &"elder_return"]:
		if heard != &"":
			data.dialogues_heard.append(heard)
		var holding := _catalog().intents.filter(func(intent: Intent) -> bool: return intent.holds(data))
		assert_int(holding.size()).override_failure_message("after %s: %d intents hold" % [heard, holding.size()]).is_less_equal(1)

func test_every_fact_names_a_catalog_dialogue() -> void:
	var known: Array[StringName] = []
	for dialogue: Dialogue in (load(DIALOGUES) as DialogueCatalog).dialogues():
		known.append(dialogue.id)
	for intent: Intent in _catalog().intents:
		for fact: SaveFact in intent.facts():
			if fact.kind == SaveFact.Kind.DIALOGUE_HEARD:
				assert_bool(known.has(fact.id)).override_failure_message("%s reads heard '%s'" % [intent.id, fact.id]).is_true()

func test_every_text_has_both_languages() -> void:
	var rows: Dictionary[String, PackedStringArray] = {}
	var file := FileAccess.open(CSV, FileAccess.READ)
	file.get_csv_line()
	while not file.eof_reached():
		var row := file.get_csv_line()
		if row.size() >= 3:
			rows[row[0]] = row
	for intent: Intent in _catalog().intents:
		assert_bool(rows.has(intent.text_key)).override_failure_message("%s has no row" % intent.text_key).is_true()
		assert_str(rows[intent.text_key][1]).is_not_empty()
		assert_str(rows[intent.text_key][2]).is_not_empty()
