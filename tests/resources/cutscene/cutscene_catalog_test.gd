class_name CutsceneCatalogTest extends GdUnitTestSuite

## The catalog names unique ids, talks only outside a together and waiting unless last, one step per subject in a
## together, SCENE_SEEN facts that name its scenes and music marks inside their cues; the game's catalog is sound.

const C := preload("res://tests/resources/cutscene/cutscene_fixture.gd")
const D := preload("res://tests/resources/dialogue/dialogue_fixture.gd")
const CATALOG := preload("res://resources/cutscene/cutscene_catalog.tres")


func _catalog(scenes: Array[Cutscene]) -> CutsceneCatalog:
	var made := CutsceneCatalog.new()
	made.scenes = scenes
	return made

func test_the_games_catalog_is_sound() -> void:
	assert_array(Array(CATALOG.validate())).is_empty()
	assert_object(CATALOG.find(&"daughter_to_bed")).is_not_null()

func test_ids_are_unique_and_present() -> void:
	var problems := _catalog([C.scene(&"a", []), C.scene(&"a", []), C.scene(&"", [])]).validate()
	assert_int(problems.size()).is_equal(2)

func test_a_talk_inside_a_together_is_refused() -> void:
	var problems := _catalog([C.scene(&"a", [C.together([C.talk()])])]).validate()
	assert_str(" ".join(problems)).contains("together")

func test_a_talk_that_does_not_wait_must_be_last() -> void:
	assert_array(Array(_catalog([C.scene(&"a", [C.wait(1.0), C.talk(false)])]).validate())).is_empty()
	var problems := _catalog([C.scene(&"a", [C.talk(false), C.wait(1.0)])]).validate()
	assert_str(" ".join(problems)).contains("last")

func test_one_step_per_subject_inside_a_together() -> void:
	var problems := _catalog([C.scene(&"a", [C.together([C.walk(&"girl", 10.0), C.gesture(&"girl", &"sit")])])]).validate()
	assert_str(" ".join(problems)).contains("girl")
	assert_array(Array(_catalog([C.scene(&"a", [C.together([C.walk(&"girl", 10.0), C.walk(&"ivo", 5.0)])])]).validate())).is_empty()

## A sequence inside a together runs its steps in order, so they may share a subject; the together's other steps may not.
func test_a_sequence_inside_a_together_may_move_one_subject_twice() -> void:
	var walks := C.sequence([C.walk(&"girl", 10.0), C.wait(0.5), C.walk(&"girl", 20.0)])
	assert_array(Array(_catalog([C.scene(&"a", [C.together([walks, C.walk(&"ivo", 5.0)])])]).validate())).is_empty()
	var problems := _catalog([C.scene(&"a", [C.together([walks, C.gesture(&"girl", &"sit")])])]).validate()
	assert_str(" ".join(problems)).contains("girl")

func test_a_scene_seen_fact_names_a_catalog_scene() -> void:
	var cases: Array[CutsceneCase] = [C.case_of([D.fact(SaveFact.Kind.SCENE_SEEN, &"nowhere")], [])]
	var problems := _catalog([C.scene(&"a", [C.branch(cases)])]).validate()
	assert_str(" ".join(problems)).contains("nowhere")

## A music mark must come before the end of a cue its scene asks for: a looping cue's position wraps there.
func test_a_music_mark_past_its_cue_is_refused() -> void:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = 8000
	var data := PackedByteArray()
	data.resize(16000)
	wav.data = data
	var music := CutsceneMusic.new()
	music.cue = MusicCue.new()
	music.cue.id = &"hum"
	music.cue.stream = wav
	var mark := CutsceneMusicMark.new()
	mark.seconds = 1.5
	assert_array(Array(_catalog([C.scene(&"a", [music, mark])]).validate())).is_empty()
	mark.seconds = 2.5
	assert_str(" ".join(_catalog([C.scene(&"a", [music, mark])]).validate())).contains("past the end of 'hum'")
