class_name SaveFactTest extends GdUnitTestSuite

## SaveFact reads one flag of the save, all guardians at once, a count of them, or a dialogue heard or answered.


func _fact(kind: SaveFact.Kind, index: int, id: StringName = &"") -> SaveFact:
	var fact := SaveFact.new()
	fact.kind = kind
	fact.index = index
	fact.id = id
	return fact

func test_each_kind_follows_its_flag() -> void:
	var data := PlayerData.new()
	var skill := _fact(SaveFact.Kind.SKILL, Enums.PlayerSkill.ROLL)
	var song := _fact(SaveFact.Kind.SONG, Enums.Song.RAIN)
	var item := _fact(SaveFact.Kind.ITEM, Enums.PlayerItem.MEMORINA)
	var restored := _fact(SaveFact.Kind.GUARDIAN_RESTORED, Enums.Guardian.FROST)
	for fact: SaveFact in [skill, song, item, restored]:
		assert_bool(fact.holds(data)).is_false()
	data.unlocked_player_skills[Enums.PlayerSkill.ROLL] = true
	data.learned_songs[Enums.Song.RAIN] = true
	data.owned_items[Enums.PlayerItem.MEMORINA] = true
	data.restored_guardians[Enums.Guardian.FROST] = true
	for fact: SaveFact in [skill, song, item, restored]:
		assert_bool(fact.holds(data)).is_true()

func test_a_restored_guardian_was_met() -> void:
	var met := _fact(SaveFact.Kind.GUARDIAN_MET, Enums.Guardian.BLOOM)
	var data := PlayerData.new()
	assert_bool(met.holds(data)).is_false()
	data.restored_guardians[Enums.Guardian.BLOOM] = true
	assert_bool(met.holds(data)).is_true()

func test_all_guardians_restored_needs_every_one_and_ignores_index() -> void:
	var all := _fact(SaveFact.Kind.ALL_GUARDIANS_RESTORED, 99)
	var data := PlayerData.new()
	var guardians: Array = Enums.Guardian.values()
	for guardian: int in guardians.slice(0, guardians.size() - 1):
		data.restored_guardians[guardian] = true
	assert_bool(all.holds(data)).is_false()
	data.restored_guardians[guardians.back()] = true
	assert_bool(all.holds(data)).is_true()

func test_the_shipped_facts_load() -> void:
	var memorina := load("res://resources/save_facts/owns_memorina.tres") as SaveFact
	var everyone := load("res://resources/save_facts/all_guardians_restored.tres") as SaveFact
	assert_int(memorina.kind).is_equal(SaveFact.Kind.ITEM)
	assert_int(memorina.index).is_equal(Enums.PlayerItem.MEMORINA)
	assert_int(everyone.kind).is_equal(SaveFact.Kind.ALL_GUARDIANS_RESTORED)
	var root := load("res://resources/save_facts/knows_root.tres") as SaveFact
	assert_int(root.kind).is_equal(SaveFact.Kind.SONG)
	assert_int(root.index).is_equal(Enums.Song.ROOT)

## The village's 0.6 step is two guardians restored (RegionMemory.steps).
func test_guardians_restored_at_least_counts_them() -> void:
	var two := _fact(SaveFact.Kind.GUARDIANS_RESTORED_AT_LEAST, 2)
	var data := PlayerData.new()
	data.restored_guardians[Enums.Guardian.FROST] = true
	assert_bool(two.holds(data)).is_false()
	data.restored_guardians[Enums.Guardian.BLOOM] = true
	assert_bool(two.holds(data)).is_true()
	assert_bool(_fact(SaveFact.Kind.GUARDIANS_RESTORED_AT_LEAST, 0).holds(PlayerData.new())).is_true()

func test_dialogue_heard_reads_the_id() -> void:
	var heard := _fact(SaveFact.Kind.DIALOGUE_HEARD, 0, &"trial_first")
	var data := PlayerData.new()
	assert_bool(heard.holds(data)).is_false()
	data.dialogues_heard.append(&"trial_after")
	assert_bool(heard.holds(data)).is_false()
	data.dialogues_heard.append(&"trial_first")
	assert_bool(heard.holds(data)).is_true()

func test_response_chosen_follows_the_latest_answer() -> void:
	var hold := _fact(SaveFact.Kind.RESPONSE_CHOSEN, 0, &"trial_keep_hold")
	var data := PlayerData.new()
	assert_bool(hold.holds(data)).is_false()
	data.responses[&"trial_keep"] = &"trial_keep_hold"
	assert_bool(hold.holds(data)).is_true()
	data.responses[&"trial_keep"] = &"trial_keep_let_go"
	assert_bool(hold.holds(data)).is_false()

func test_the_check_without_an_id_is_unchanged() -> void:
	var data := PlayerData.new()
	data.owned_items[Enums.PlayerItem.SWORD] = true
	assert_bool(SaveFact.check(SaveFact.Kind.ITEM, Enums.PlayerItem.SWORD, data)).is_true()

func test_gates_pass_needs_every_when_and_no_unless() -> void:
	var data := PlayerData.new()
	var sword := _fact(SaveFact.Kind.ITEM, Enums.PlayerItem.SWORD)
	var memorina := _fact(SaveFact.Kind.ITEM, Enums.PlayerItem.MEMORINA)
	var none: Array[SaveFact] = []
	var both: Array[SaveFact] = [sword, memorina]
	var only_memorina: Array[SaveFact] = [memorina]
	assert_bool(SaveFact.gates_pass(none, none, data)).is_true()
	assert_bool(SaveFact.gates_pass(both, none, data)).is_false()
	data.owned_items[Enums.PlayerItem.SWORD] = true
	data.owned_items[Enums.PlayerItem.MEMORINA] = true
	assert_bool(SaveFact.gates_pass(both, none, data)).is_true()
	assert_bool(SaveFact.gates_pass(both, only_memorina, data)).is_false()
