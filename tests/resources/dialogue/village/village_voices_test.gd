class_name VillageVoicesTest extends GdUnitTestSuite

## The village voices (STORY-09; design 05, "Village voices"): one optional line per villager by memory step, 0.8 at
## the start and 0.6 from the second guardian restored; the baker's cough is said once, after the errand.

const REGION := "res://scenes/world/rooms/home_village.tscn"
const CONTENTS := "res://scenes/world/rooms/home_village/contents/"
const AT_06 := "res://resources/save_facts/village_at_six_tenths.tres"
const VILLAGE := "res://resources/dialogue/village/"
const BAKER := "res://resources/dialogue/story/baker.tres"


## The 0.6 fact and every staging's GUARDIANS_RESTORED_AT_LEAST in the village read the step RegionMemory.steps gives
## 0.6 at, so a retuned step cannot leave the voices on the old one.
func test_the_six_tenths_fact_is_the_regions_memory_step() -> void:
	var steps := _region_memory()["steps"] as Dictionary
	var step := -1
	for key: int in steps:
		if is_equal_approx(float(steps[key]), 0.6):
			step = key
	assert_int(step).is_equal(2)
	# The voices know 0.8 and 0.6 only: a later step (STORY-07's Return at 1.0) needs an `unless` on every voice first.
	for key: int in steps:
		assert_int(key).override_failure_message("home_village step %d: give the village voices an unless for it" % key).is_less_equal(step)
	var fact := load(AT_06) as SaveFact
	assert_int(fact.kind).is_equal(SaveFact.Kind.GUARDIANS_RESTORED_AT_LEAST)
	assert_int(fact.index).is_equal(step)
	for file: String in DirAccess.get_files_at(CONTENTS):
		if not file.ends_with("_contents.tscn"):
			continue
		var text := FileAccess.get_file_as_string(CONTENTS + file)
		var at := text.find("kind = 6\n")
		while at >= 0:
			var line := text.substr(at + 9, text.find("\n", at + 9) - at - 9)
			assert_str(line).override_failure_message("%s: %s" % [file, line]).is_equal("index = %d" % step)
			at = text.find("kind = 6\n", at + 1)

func test_the_baker_greets_again_coughs_once_and_forgets_at_six_tenths() -> void:
	var baker := load(BAKER) as DialogueSet
	var data := PlayerData.new()
	assert_str(_id(baker, data)).is_equal("baker_errand")
	data.dialogues_heard.append(&"baker_errand")
	assert_str(_id(baker, data)).is_equal("baker_cough")
	var cough := baker.current(data)
	assert_bool(cough.once).is_true()
	assert_array(_keys(cough)).is_equal(["DLG_BAKER_ERRAND_01", "DLG_BAKER_COUGH"])
	data.dialogues_heard.append(&"baker_cough")
	assert_str(_id(baker, data)).is_equal("baker_again")
	assert_array(_keys(baker.current(data))).is_equal(["DLG_BAKER_ERRAND_01"])
	_restore_two(data)
	assert_str(_id(baker, data)).is_equal("baker_06")

## The errand still wins while it is due, at any step; the cough never comes before it or at 0.6.
func test_the_errand_wins_and_the_cough_needs_it_at_eight_tenths() -> void:
	var baker := load(BAKER) as DialogueSet
	var data := PlayerData.new()
	_restore_two(data)
	assert_str(_id(baker, data)).is_equal("baker_errand")
	data.dialogues_heard.append(&"baker_errand")
	assert_str(_id(baker, data)).is_equal("baker_06")

func test_each_villager_speaks_by_step() -> void:
	var early := PlayerData.new()
	var heard := PlayerData.new()
	heard.dialogues_heard.append(&"elder_story")
	var late := PlayerData.new()
	_restore_two(late)
	var expected := {
		"taverner": ["taverner_quiet", "taverner_quiet", ""],
		"water_carrier": ["water_carrier_water", "water_carrier_water", "water_carrier_06"],
		"seller": ["seller_apples", "seller_apples", ""],
		"boy": ["", "boy_statues", "boy_alone"],
	}
	for who: String in expected:
		var talk := load(VILLAGE + who + ".tres") as DialogueSet
		var ids: Array[String] = [_id(talk, early), _id(talk, heard), _id(talk, late)]
		assert_array(ids).override_failure_message(who).is_equal(expected[who])

func test_every_village_set_is_in_the_catalog_with_a_plate_and_no_portrait() -> void:
	var catalog := load("res://resources/dialogue/dialogue_catalog.tres") as DialogueCatalog
	for who: String in ["taverner", "water_carrier", "seller", "boy"]:
		var talk := load(VILLAGE + who + ".tres") as DialogueSet
		assert_bool(catalog.sets.has(talk)).override_failure_message(who).is_true()
		for dialogue: Dialogue in talk.dialogues:
			for line: DialogueLine in dialogue.lines:
				assert_str(line.speaker.name_key).is_equal("SPEAKER_" + who.to_upper())
				assert_object(line.speaker.portrait).is_null()

## A talk zone keeps more than Ivo's body width (22 px) from every door zone, so one Up prompt shows at a time
## (bugs/the-boys-talk-prompt-shows-over-the-bell-tower-door-and-up-enters-the-tower).
func test_no_village_voice_stands_within_a_body_of_a_door() -> void:
	for room: String in ["village_square", "village_lane_west", "village_tavern", "village_bakery"]:
		var path := CONTENTS + room + ".room"
		var map := RoomMapParser.parse(FileAccess.get_file_as_string(path), RoomLegend.load_default(), path).map
		var doors: Array[Vector2i] = []
		var talks: Array[Dictionary] = []
		for placed: Dictionary in map.entities:
			if placed.symbol == "E":
				doors.append(placed.cell)
			elif placed.symbol == "t":
				talks.append(placed)
		for talk: Dictionary in talks:
			var cell := talk.cell as Vector2i
			var half := int(talk.params.get("width_cells", 2)) * RoomMap.CELL_PX * 0.5
			var centre := (cell.x + 0.5) * RoomMap.CELL_PX
			for door: Vector2i in doors:
				if door.y != cell.y:
					continue
				var door_left := door.x * RoomMap.CELL_PX
				var gap := maxf(door_left - (centre + half), (centre - half) - (door_left + RoomMap.CELL_PX))
				assert_float(gap).override_failure_message("%s: talk at %s, door at %s" % [room, cell, door]).is_greater(22.0)

## The boy's talk points at the boy (square x 600), from west of him.
func test_the_boys_talk_faces_him() -> void:
	var path := CONTENTS + "village_square.room"
	var map := RoomMapParser.parse(FileAccess.get_file_as_string(path), RoomLegend.load_default(), path).map
	for placed: Dictionary in map.entities:
		if placed.symbol == "t" and str(placed.params.talk).ends_with("boy.tres"):
			var origin := ((placed.cell as Vector2i).x + 0.5) * RoomMap.CELL_PX
			assert_float(origin + float(placed.params.speaker_offset)).is_equal(600.0)
			return
	fail("no talk for the boy")

func _region_memory() -> Dictionary:
	var state := (load(REGION) as PackedScene).get_state()
	var found := {}
	for node: int in state.get_node_count():
		if state.get_node_name(node) != &"Memory":
			continue
		for i: int in state.get_node_property_count(node):
			found[String(state.get_node_property_name(node, i))] = state.get_node_property_value(node, i)
	return found

func _restore_two(data: PlayerData) -> void:
	data.restored_guardians[Enums.Guardian.FROST] = true
	data.restored_guardians[Enums.Guardian.BLOOM] = true

func _id(talk: DialogueSet, data: PlayerData) -> String:
	var dialogue := talk.current(data)
	return String(dialogue.id) if dialogue != null else ""

func _keys(dialogue: Dialogue) -> Array[String]:
	var keys: Array[String] = []
	for line: DialogueLine in dialogue.lines:
		keys.append(line.text_key)
	return keys

## At 0.6 the taverner sets two mugs and says nothing (design 05): the mugs are staged on the same 0.6 fact.
func test_the_taverners_two_mugs_show_only_at_six_tenths() -> void:
	var tavern := auto_free((load(CONTENTS + "village_tavern_contents.tscn") as PackedScene).instantiate()) as Node
	var mugs := tavern.get_node("Props/Mugs") as FactStaging
	assert_object(mugs.stages[0].when[0]).is_same(load(AT_06))
	assert_str(String(mugs.stages[0].show)).is_equal("AtSix")
	assert_int(mugs.get_node("AtSix").get_child_count()).is_equal(2)
	var data := PlayerData.new()
	assert_int(FactStaging.pick(mugs.stages, data)).is_equal(1)
	_restore_two(data)
	assert_int(FactStaging.pick(mugs.stages, data)).is_equal(0)
	assert_str(_id(load(VILLAGE + "taverner.tres") as DialogueSet, data)).is_equal("")
