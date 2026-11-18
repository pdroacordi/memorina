class_name FinalFragmentTest extends GdUnitTestSuite

## STORY-42's scene as data: seven engraved panels in order with his two inks, the crack alone trembling, the captions in
## their turns, his phrase and the broken one as note steps over a stream-less SCENE request, and an end under black
## that clears itself only when the restoration was seen (architecture/story42-the-final-fragment, "The scene").

const SCENE := preload("res://resources/cutscene/story/final_fragment.tres")
const CATALOG := preload("res://resources/cutscene/cutscene_catalog.tres")
const WINTER := preload("res://resources/songs/palettes/winter_palette.tres")
const FLOWER := preload("res://resources/story/engraving/flower_ink.tres")
const FINAL_A := preload("res://resources/songs/final_phrase_a.tres")
const ROOT := preload("res://resources/songs/root.tres")
const SEEN_RESTORATION := preload("res://resources/save_facts/seen_world_restoration.tres")
const TURNS: Array[int] = [2, 2, 2, 1, 2, 1, 3]
const INKLESS := 6
const TREMBLING := 4


func _engravings() -> Array[CutsceneEngraving]:
	var found: Array[CutsceneEngraving] = []
	for leaf: CutsceneStep in CutsceneCatalog.leaves(SCENE.steps):
		if leaf is CutsceneEngraving:
			found.append(leaf as CutsceneEngraving)
	return found

func _of_type(kind: Variant) -> Array[CutsceneStep]:
	var found: Array[CutsceneStep] = []
	for leaf: CutsceneStep in CutsceneCatalog.leaves(SCENE.steps):
		if is_instance_of(leaf, kind):
			found.append(leaf)
	return found

## Scaled seconds the steps take when played through; a branch's cases are not counted.
func _seconds(steps: Array[CutsceneStep]) -> float:
	var total := 0.0
	for step: CutsceneStep in steps:
		total += _step_seconds(step)
	return total

func _step_seconds(step: CutsceneStep) -> float:
	if step is CutsceneTogether:
		var longest := 0.0
		for inner: CutsceneStep in (step as CutsceneTogether).steps:
			longest = maxf(longest, _step_seconds(inner))
		return longest
	if step is CutsceneSequence:
		return _seconds((step as CutsceneSequence).steps)
	if step is CutsceneEngraving:
		return (step as CutsceneEngraving).frame.seconds
	if step is CutsceneEngravingClear:
		return 0.0 if (step as CutsceneEngravingClear).hide else (step as CutsceneEngravingClear).seconds
	if step is CutsceneMelody:
		var melody := step as CutsceneMelody
		return melody.melody.duration(melody.count) if melody.wait else 0.0
	return float(step.get(&"seconds")) if &"seconds" in step else 0.0

func test_it_is_a_skippable_catalog_scene_with_no_talk_that_hides_the_life_notes() -> void:
	assert_str(String(SCENE.id)).is_equal("final_fragment")
	assert_bool(SCENE.skippable).is_true()
	assert_bool(SCENE.hud_hidden).is_true()
	assert_object(CATALOG.find(&"final_fragment")).is_same(SCENE)
	assert_array(_of_type(CutsceneTalk)).is_empty()

func test_seven_panels_in_order_the_first_revealed_and_the_rest_dissolving() -> void:
	var panels := _engravings()
	assert_int(panels.size()).is_equal(TURNS.size())
	for i: int in panels.size():
		assert_bool(panels[i].dissolve).override_failure_message("panel %d" % (i + 1)).is_equal(i > 0)
		var base := panels[i].frame.layers[0].texture.resource_path
		assert_str(base).is_equal("res://assets/sprites/story/final_fragment/panel_%d_base.png" % (i + 1))

func test_his_two_inks_on_every_inked_panel_and_none_on_the_grey_one() -> void:
	var panels := _engravings()
	for i: int in panels.size():
		var panel := panels[i]
		var what := "panel %d" % (i + 1)
		if i + 1 == INKLESS:
			assert_object(panel.ink).override_failure_message(what).is_null()
			assert_object(panel.second_ink).override_failure_message(what).is_null()
		else:
			assert_object(panel.ink).override_failure_message(what).is_same(WINTER)
			assert_object(panel.second_ink).override_failure_message(what).is_same(FLOWER)

func test_only_the_crack_trembles_and_only_ink_moves() -> void:
	var panels := _engravings()
	for i: int in panels.size():
		var frame := panels[i].frame
		var what := "panel %d" % (i + 1)
		assert_float(frame.tremble).override_failure_message(what).is_equal(1.0 if i + 1 == TREMBLING else 0.0)
		assert_bool(frame.layers[0].ink_only).override_failure_message(what).is_false()
		var moving := 0
		for layer: EngravingLayer in frame.layers.slice(1):
			assert_bool(layer.ink_only).override_failure_message(what).is_true()
			moving += 1
		assert_int(moving).override_failure_message(what).is_less_equal(2)

func test_every_caption_is_its_panels_turn_in_order_and_every_frame_fits() -> void:
	var panels := _engravings()
	for i: int in panels.size():
		var frame := panels[i].frame
		var keys: Array[StringName] = []
		for turn: int in range(1, TURNS[i] + 1):
			keys.append(StringName("FINAL_FRAGMENT_%d_%d" % [i + 1, turn]))
		assert_array(frame.captions).is_equal(keys)
		assert_bool(frame.caption_turns).is_equal(TURNS[i] > 1)
		assert_bool(EngravingMath.fits(frame)).override_failure_message("panel %d" % (i + 1)).is_true()

func test_his_phrase_and_the_broken_phrase_are_the_fights_notes() -> void:
	var melodies := _of_type(CutsceneMelody)
	assert_int(melodies.size()).is_equal(3)
	var phrase := (melodies[0] as CutsceneMelody).melody
	var spring := (melodies[2] as CutsceneMelody).melody
	assert_array(phrase.notes).is_equal(FINAL_A.notes)
	assert_array(spring.notes).is_equal(ROOT.notes)
	assert_object((melodies[1] as CutsceneMelody).melody).is_same(phrase)
	assert_int((melodies[0] as CutsceneMelody).count).is_equal(-1)
	assert_int((melodies[1] as CutsceneMelody).count).is_equal(4)
	assert_int((melodies[2] as CutsceneMelody).count).is_equal(4)
	for step: CutsceneStep in melodies:
		var melody := step as CutsceneMelody
		assert_array(melody.melody.validate()).is_empty()
		assert_int(melody.voices.size()).is_equal(4)

## The data slot for the underscore: a stream-less SCENE request held through the scene until the AIVA piece is approved.
func test_the_music_is_one_stream_less_request() -> void:
	var music := _of_type(CutsceneMusic)
	assert_int(music.size()).is_equal(1)
	var cue := (music[0] as CutsceneMusic).cue
	assert_object(cue).is_not_null()
	assert_str(String(cue.id)).is_equal("final_fragment_silence")
	assert_object(cue.stream).is_null()

func test_it_ends_under_black_and_clears_only_when_the_restoration_was_seen() -> void:
	var last := SCENE.steps[SCENE.steps.size() - 1] as CutsceneBranch
	assert_object(last).is_not_null()
	var black := SCENE.steps[SCENE.steps.size() - 2] as CutsceneFade
	assert_bool(black.to_black).is_true()
	assert_object(black.colour).is_equal(Color.BLACK)
	assert_int(last.cases.size()).is_equal(1)
	assert_array(last.cases[0].when).is_equal([SEEN_RESTORATION])
	var steps := last.cases[0].steps
	assert_bool((steps[0] as CutsceneEngravingClear).hide).is_true()
	assert_bool((steps[1] as CutsceneFade).to_black).is_false()
	var data := PlayerData.new()
	assert_array(last.pick(data)).is_empty()
	data.scenes_seen.append(&"world_restoration")
	assert_array(last.pick(data)).is_equal(steps)

func test_it_lasts_about_a_minute() -> void:
	var seconds := _seconds(SCENE.steps)
	assert_float(seconds).is_between(55.0, 75.0)

## Placeholders and the approved art share the bearer canvas: the view plus the widest pan, per loop cell.
func test_every_panel_canvas_holds_the_widest_pan() -> void:
	var widest := EngravingMath.VIEW + Vector2(64.0, 32.0)
	for panel: CutsceneEngraving in _engravings():
		for layer: EngravingLayer in panel.frame.layers:
			assert_vector(EngravingMath.cell_size(layer)).override_failure_message(layer.texture.resource_path) \
					.is_equal(widest)
