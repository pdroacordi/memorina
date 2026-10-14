class_name SaveFactTest extends GdUnitTestSuite

## SaveFact reads one flag of the save, or all guardians at once.


func _fact(kind: SaveFact.Kind, index: int) -> SaveFact:
	var fact := SaveFact.new()
	fact.kind = kind
	fact.index = index
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
