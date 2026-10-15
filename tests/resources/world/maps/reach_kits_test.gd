class_name ReachKitsTest extends GdUnitTestSuite

## The kit check's stages (systems/rooms, "Kit check"): each kit adds one milestone to an earlier one, and each milestone
## holds the guardian's gifts (design 04 section 2).

const DESIGN_ORDER: Array[StringName] = [&"base", &"memorina", &"woods", &"lake", &"both", &"woods_orchards", &"woods_orchards_caldera", &"lake_caldera", &"both_caldera", &"orchards", &"caldera"]

var _kits: ReachKits

func before() -> void:
	_kits = ReachKits.load_default()

func _kit(id: StringName) -> ReachKit:
	for kit: ReachKit in _kits.kits:
		if kit.id == id:
			return kit
	return null

func test_the_kits_run_in_design_order() -> void:
	var ids: Array[StringName] = []
	for kit: ReachKit in _kits.kits:
		ids.append(kit.id)
	assert_array(ids).contains_exactly(DESIGN_ORDER)

func test_each_kit_after_the_base_adds_one_milestone_to_an_earlier_kit() -> void:
	for i: int in range(1, _kits.kits.size()):
		var kit := _kits.kits[i]
		var grown := false
		for j: int in i:
			for milestone: ReachMilestone in kit.milestones:
				if _kits.next(_kits.kits[j], milestone) == kit:
					grown = true
		assert_bool(grown).override_failure_message("%s grows from no earlier kit" % kit.id).is_true()

func test_the_base_kit_is_movement_and_the_sword() -> void:
	var data := _kit(&"base").player_data()
	assert_array(data.owned_items).contains_exactly([true, false])
	assert_bool(data.unlocked_player_skills.has(true)).is_false()
	assert_bool(data.learned_songs.has(true)).is_false()

## The opening's talks are part of the starting kit, so the east gate (heard_elder_story.tres) is open to every kit
## ("East gate shut until the elder points east (Recommended)", user, 2026-10-15).
func test_the_base_kit_has_heard_the_opening_and_passes_the_east_gate() -> void:
	var gate := ReachKit.of(load("res://resources/save_facts/heard_elder_story.tres") as SaveFact)
	for kit: ReachKit in _kits.kits:
		assert_bool(kit.holds(PackedInt32Array([gate]))).override_failure_message(String(kit.id)).is_true()
	var unheard := ReachKit.new()
	assert_bool(unheard.holds(PackedInt32Array([gate]))).is_false()

## A need on a talk packs its id, so two talks are two needs.
func test_a_dialogue_need_packs_its_id() -> void:
	var heard := SaveFact.new()
	heard.kind = SaveFact.Kind.DIALOGUE_HEARD
	heard.id = &"daughter_song"
	var other := SaveFact.new()
	other.kind = SaveFact.Kind.DIALOGUE_HEARD
	other.id = &"mentor_gift"
	assert_int(ReachKit.of(heard)).is_not_equal(ReachKit.of(other))
	assert_bool(_kit(&"base").holds(PackedInt32Array([ReachKit.of(heard)]))).is_true()
	assert_bool(_kit(&"base").holds(PackedInt32Array([ReachKit.of(other)]))).is_false()

func test_the_memorina_opens_the_village_fences() -> void:
	var fence := ReachKit.of(load("res://resources/save_facts/owns_memorina.tres") as SaveFact)
	assert_bool(_kit(&"base").holds(PackedInt32Array([fence]))).is_false()
	assert_bool(_kit(&"memorina").holds(PackedInt32Array([fence]))).is_true()

func test_each_guardian_gives_its_design_gifts() -> void:
	var woods := _kit(&"woods")
	assert_bool(woods.has_skill(Enums.PlayerSkill.DOUBLE_JUMP)).is_true()
	assert_bool(woods.holds(PackedInt32Array([ReachKit.song(Enums.Song.ROOT), ReachKit.song(Enums.Song.RAIN)]))).is_true()
	var lake := _kit(&"lake")
	assert_bool(lake.has_skill(Enums.PlayerSkill.ROLL)).is_true()
	assert_bool(lake.has_skill(Enums.PlayerSkill.DOUBLE_JUMP)).is_false()
	assert_bool(lake.holds(PackedInt32Array([ReachKit.song(Enums.Song.FREEZE), ReachKit.song(Enums.Song.BELL_JAR)]))).is_true()
	var orchards := _kit(&"orchards")
	assert_bool(orchards.has_skill(Enums.PlayerSkill.WALL_CLIMB)).is_true()
	assert_bool(orchards.holds(PackedInt32Array([ReachKit.song(Enums.Song.RELEASE), ReachKit.song(Enums.Song.GALE)]))).is_true()
	assert_bool(_kit(&"both").has_skill(Enums.PlayerSkill.WALL_CLIMB)).is_false()
	assert_bool(_kit(&"caldera").holds(PackedInt32Array([ReachKit.song(Enums.Song.SHADOW), ReachKit.song(Enums.Song.SOLSTICE)]))).is_true()
	assert_bool(_kit(&"orchards").holds(PackedInt32Array([ReachKit.song(Enums.Song.SHADOW)]))).is_false()

## The sword and the opening's talks are the starting kit; every other milestone is earned in a room.
func test_every_milestone_but_the_starting_ones_is_earned_in_a_room() -> void:
	for milestone: ReachMilestone in _kits.milestones():
		if milestone.id not in [&"sword", &"opening"]:
			assert_str(String(milestone.room)).override_failure_message("%s has no room" % milestone.id).is_not_empty()
