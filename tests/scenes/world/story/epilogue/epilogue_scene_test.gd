class_name EpilogueSceneTest extends GdUnitTestSuite

## The epilogue (01 §9.4; architecture/story-07-epilogue): the stone plays it while due; its marks are the render's
## measured onsets; Ivo's lines lean with the quiet tally, Alba's never vary, and "Alba." is the only line of his that is
## her name, in every locale.

const GARDEN := preload("res://scenes/world/rooms/home_village/contents/village_garden_contents.tscn")
const EPILOGUE := preload("res://resources/cutscene/story/epilogue.tres")
const CATALOG := preload("res://resources/dialogue/dialogue_catalog.tres")
const DUET := preload("res://resources/music/wife_song_epilogue.tres")
const SETS: Array[String] = [
	"res://resources/dialogue/story/epilogue_talk.tres",
	"res://resources/dialogue/story/epilogue_answer.tres",
	"res://resources/dialogue/story/epilogue_name.tres",
]
const IVO_SPEAKER := "SPEAKER_IVO"
const ALBA_SPEAKER := "SPEAKER_ALBA"

var _locale: String


func before() -> void:
	_locale = TranslationServer.get_locale()

func after() -> void:
	TranslationServer.set_locale(_locale)

func before_test() -> void:
	SaveSystem.begin("", true)

func after_test() -> void:
	SaveSystem.begin("", true)

func _due() -> PlayerData:
	var data := PlayerData.new()
	data.world_restored = true
	for number: int in range(1, FlashbackSchedule.COUNT + 1):
		data.scenes_seen.append(FlashbackSchedule.id(number))
	data.dialogues_heard.append(EpilogueSchedule.REUNION_ID)
	return data

func _lines() -> Array[DialogueLine]:
	var found: Array[DialogueLine] = []
	for path: String in SETS:
		for dialogue: Dialogue in (load(path) as DialogueSet).dialogues:
			found.append_array(dialogue.lines)
	return found

func test_the_stone_plays_the_epilogue_while_it_is_due() -> void:
	var garden := auto_free(GARDEN.instantiate()) as Node
	var seat := garden.get_node("Seats/StoneSeat") as GroundSeat
	assert_object(seat.cutscene).is_same(EPILOGUE)
	assert_str(String(EPILOGUE.id)).is_equal(String(EpilogueSchedule.EPILOGUE_ID))
	assert_bool(EPILOGUE.skippable).is_true()
	var data := _due()
	assert_bool(seat.wants(data)).is_true()
	data.scenes_seen.append(EpilogueSchedule.EPILOGUE_ID)
	assert_bool(seat.wants(data)).is_false()
	data.scenes_seen.clear()
	assert_bool(seat.wants(data)).is_false()

func test_alba_waits_in_the_garden_cast_with_a_rest_that_shows_nothing() -> void:
	var garden := auto_free(GARDEN.instantiate()) as Node
	var alba := garden.get_node("Cast/Alba") as StoryActor
	assert_str(String(alba.actor_id)).is_equal("alba")
	var staging := alba.get_node(alba.stands_for) as FactStaging
	assert_array(staging.stages).is_empty()
	assert_int(staging.get_child_count()).is_equal(0)
	assert_bool(alba.find_children("*", "GreyhushShield").is_empty()).is_true()

## Her release and his last note are the render's (music_cue_test), and every mark fits the duet.
func test_the_marks_are_the_measured_onsets() -> void:
	var marks: Array[float] = []
	for leaf: CutsceneStep in CutsceneCatalog.leaves(EPILOGUE.steps):
		if leaf is CutsceneMusicMark:
			var mark := leaf as CutsceneMusicMark
			assert_bool(mark.fits(DUET)).is_true()
			marks.append(mark.seconds)
	assert_array(marks).is_equal([MusicCueTest.EPILOGUE_HER_RELEASE, 15.8])
	assert_float(marks[1]).is_greater(MusicCueTest.EPILOGUE_FLUTE_RELEASE)
	assert_float(marks[1]).is_less(MusicCueTest.EPILOGUE_END)

## The steps of 01 §9.4 in order: the attempt, the gap, her there, the talks, the duet, her leaving while the frame is up,
## the frame back on him for the flute's held C.
func test_the_scene_keeps_its_order() -> void:
	var kinds: Array[String] = []
	for leaf: CutsceneStep in CutsceneCatalog.leaves(EPILOGUE.steps):
		if leaf is CutsceneMelody:
			kinds.append("melody")
		elif leaf is CutscenePlace:
			kinds.append("place")
		elif leaf is CutsceneTalk:
			kinds.append("talk")
		elif leaf is CutsceneExit:
			kinds.append("exit")
		elif leaf is CutsceneMusic and (leaf as CutsceneMusic).cue == DUET:
			kinds.append("duet")
	assert_array(kinds).is_equal(["melody", "place", "talk", "talk", "talk", "duet", "exit"])
	var melody: CutsceneMelody = CutsceneCatalog.leaves(EPILOGUE.steps).filter(func(leaf: CutsceneStep) -> bool: return leaf is CutsceneMelody)[0]
	assert_int(melody.count).is_equal(4)

## Decision 7: the design's text is the base, said on a tie; only Ivo's lines vary, by the leaning tone.
func test_ivos_lines_lean_with_the_tally_and_alba_never_varies() -> void:
	var tie := _due()
	var hold_on := _due()
	hold_on.responses[&"guardian_frost_gift"] = &"guardian_frost_gift_close"
	var let_go := _due()
	let_go.responses[&"guardian_frost_gift"] = &"guardian_frost_gift_open"
	var varied := 0
	for line: DialogueLine in _lines():
		if line.speaker.name_key == ALBA_SPEAKER:
			assert_array(line.variants).override_failure_message(line.text_key).is_empty()
			continue
		assert_str(line.speaker.name_key).is_equal(IVO_SPEAKER)
		assert_str(line.text_for(tie)).is_equal(line.text_key)
		if line.variants.is_empty():
			assert_str(line.text_for(hold_on)).is_equal(line.text_key)
			continue
		varied += 1
		assert_str(line.text_for(hold_on)).is_equal(line.text_key + "_V%d" % DialogueChoice.Tone.HOLD_ON)
		assert_str(line.text_for(let_go)).is_equal(line.text_key + "_V%d" % DialogueChoice.Tone.LET_GO)
	assert_int(varied).is_equal(2)

## Draft §2: "Ivo só diz o nome dela uma vez, no epílogo".
func test_alba_is_ivos_only_line_that_is_her_name_in_every_locale() -> void:
	for locale: String in ["en", "pt_BR"]:
		TranslationServer.set_locale(locale)
		var name := TranslationServer.translate(ALBA_SPEAKER)
		var found: Array[String] = []
		for set: DialogueSet in CATALOG.sets:
			for dialogue: Dialogue in set.dialogues:
				for line: DialogueLine in dialogue.lines:
					if line.speaker == null or line.speaker.name_key != IVO_SPEAKER:
						continue
					var keys: Array[String] = [line.text_key]
					for variant: LineVariant in line.variants:
						keys.append(variant.text_key)
					for key: String in keys:
						if not key.is_empty() and TranslationServer.translate(key).rstrip(".!?…") == name:
							found.append(key)
		assert_array(found).override_failure_message(locale).is_equal(["DLG_EPILOGUE_08"])

## game.tscn's EpilogueDirector orders this scene (its credits come with step 11).
func test_the_game_orders_the_epilogue() -> void:
	var state := (load("res://scenes/world/game.tscn") as PackedScene).get_state()
	for node: int in state.get_node_count():
		if state.get_node_name(node) != &"EpilogueDirector":
			continue
		for i: int in state.get_node_property_count(node):
			if state.get_node_property_name(node, i) == &"epilogue":
				assert_object(state.get_node_property_value(node, i)).is_same(EPILOGUE)
				return
	fail("no EpilogueDirector with the epilogue in game.tscn")
