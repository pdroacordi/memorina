class_name BearerFragmentCatalogTest extends GdUnitTestSuite

## The catalog names every rule its data can break, against the shipped guardians' songs
## (architecture/story-04-bearer-fragments, "Data").

const B := preload("res://tests/resources/story/bearers/bearer_fixture.gd")
const SOUND_FRAME_SECONDS := 7.0

var _stats: Dictionary[Enums.Guardian, GuardianStats]


func before() -> void:
	_stats = BearerFragmentCatalog.shipped_stats()

func _problems(fragment: BearerFragment) -> PackedStringArray:
	var catalog := B.catalog([fragment])
	return catalog.validate(B.cutscenes([fragment]), _stats, B.PAPER)

func _sound() -> BearerFragment:
	return B.fragment(SOUND_FRAME_SECONDS)

func _assert_names(fragment: BearerFragment, part: String) -> void:
	var problems := _problems(fragment)
	assert_int(problems.size()).override_failure_message("expected one problem with '%s': %s" % [part, problems]) \
			.is_equal(1)
	assert_str(problems[0] if not problems.is_empty() else "").contains(part)

func test_a_sound_fragment_has_no_problems() -> void:
	assert_array(Array(_problems(_sound()))).is_empty()

func test_the_shipped_stats_name_each_guardians_song() -> void:
	var songs := {Enums.Guardian.FROST: Enums.Song.FREEZE, Enums.Guardian.BLOOM: Enums.Song.ROOT,
			Enums.Guardian.AUTUMN: Enums.Song.RELEASE, Enums.Guardian.SUMMER: Enums.Song.SHADOW}
	for guardian: int in songs:
		assert_int((_stats[guardian] as GuardianStats).song.id).is_equal(songs[guardian])

func test_the_shipped_catalog_is_sound() -> void:
	var catalog := load("res://resources/story/bearers/bearer_catalog.tres") as BearerFragmentCatalog
	var cutscenes := load("res://resources/cutscene/cutscene_catalog.tres") as CutsceneCatalog
	assert_array(Array(catalog.validate(cutscenes, _stats, B.PAPER))).is_empty()
	assert_array(catalog.missing()).is_empty()

func test_a_guardian_listed_twice() -> void:
	var catalog := B.catalog([_sound(), _sound()])
	var problems := catalog.validate(B.cutscenes([_sound()]), _stats, B.PAPER)
	assert_str(" ".join(problems)).contains("listed twice")

func test_missing_names_the_guardians_with_no_fragment() -> void:
	assert_array(B.catalog([_sound()]).missing()).is_equal(
			[Enums.Guardian.BLOOM, Enums.Guardian.AUTUMN, Enums.Guardian.SUMMER])

func test_a_song_that_is_not_the_guardians() -> void:
	var fragment := _sound()
	fragment.song = preload("res://resources/songs/root.tres")
	var problems := _problems(fragment)
	assert_str(" ".join(problems)).contains("not its guardian's")

func test_an_engraving_id_not_bearer_guardian() -> void:
	var fragment := _sound()
	fragment.engraving.id = &"bearer_wrong"
	_assert_names(fragment, "not 'bearer_frost'")

func test_a_scene_missing_from_the_cutscene_catalog() -> void:
	var fragment := _sound()
	var catalog := B.catalog([fragment])
	var cutscenes := B.cutscenes([fragment])
	cutscenes.scenes.erase(fragment.returning)
	var problems := catalog.validate(cutscenes, _stats, B.PAPER)
	assert_str(" ".join(problems)).contains("not in the cutscene catalog")

func test_a_skippable_call_or_returning() -> void:
	var fragment := _sound()
	fragment.call.skippable = true
	_assert_names(fragment, "call is skippable")
	fragment = _sound()
	fragment.returning.skippable = true
	_assert_names(fragment, "returning is skippable")

func test_an_engraving_that_cannot_be_skipped() -> void:
	var fragment := _sound()
	fragment.engraving.skippable = false
	_assert_names(fragment, "engraving is not skippable")

func test_an_engraving_not_ending_in_black() -> void:
	var fragment := _sound()
	fragment.engraving.steps.pop_back()
	_assert_names(fragment, "does not end covered in black")
	fragment = _sound()
	(fragment.engraving.steps.back() as CutsceneFade).colour = B.PAPER
	_assert_names(fragment, "does not end covered in black")

func test_music_that_is_not_its_songs_track() -> void:
	var fragment := _sound()
	fragment.music = null
	_assert_names(fragment, "music is not its song's track")
	fragment = _sound()
	fragment.music.stream = (load("res://resources/songs/root.tres") as Song).track
	_assert_names(fragment, "music is not its song's track")

func test_a_returning_scene_naming_more_than_ivo() -> void:
	var fragment := _sound()
	fragment.returning.steps = [B.C.walk(&"alba", 10.0)]
	_assert_names(fragment, "returning scene names 'alba'")

func test_a_call_not_ending_in_the_paper() -> void:
	var fragment := B.fragment(SOUND_FRAME_SECONDS, Color.WHITE)
	_assert_names(fragment, "paper")

func test_too_few_or_too_many_frames() -> void:
	var fragment := _sound()
	fragment.engraving.steps.remove_at(0)
	(fragment.engraving.steps[0] as CutsceneEngraving).dissolve = false
	var problems := _problems(fragment)
	assert_str(" ".join(problems)).contains("3 frames")
	fragment = B.fragment(5.0)
	for i: int in 2:
		fragment.engraving.steps.insert(4, B.engraving_step(5.0, true))
	assert_str(" ".join(_problems(fragment))).contains("6 frames")

func test_a_frame_with_no_caption_or_three() -> void:
	var fragment := _sound()
	(fragment.engraving.steps[1] as CutsceneEngraving).frame.captions = []
	_assert_names(fragment, "frame 2 has 0 captions")
	fragment = _sound()
	(fragment.engraving.steps[2] as CutsceneEngraving).frame.captions = [&"A", &"B", &"C"]
	_assert_names(fragment, "frame 3 has 3 captions")

func test_a_frame_that_pans_out_of_its_canvas() -> void:
	var fragment := _sound()
	(fragment.engraving.steps[0] as CutsceneEngraving).frame.pan_to = Vector2(80.0, 0.0)
	_assert_names(fragment, "frame 1 pans outside")

func test_the_first_frame_reveals_and_the_rest_dissolve() -> void:
	var fragment := _sound()
	(fragment.engraving.steps[0] as CutsceneEngraving).dissolve = true
	_assert_names(fragment, "frame 1")
	fragment = _sound()
	(fragment.engraving.steps[3] as CutsceneEngraving).dissolve = false
	_assert_names(fragment, "frame 4 does not dissolve")

func test_a_frame_inked_in_another_season() -> void:
	var fragment := _sound()
	(fragment.engraving.steps[2] as CutsceneEngraving).ink = preload("res://resources/songs/palettes/summer_palette.tres")
	_assert_names(fragment, "frame 3 is not inked")

func test_an_engraving_too_short_or_too_long() -> void:
	_assert_names(B.fragment(5.0), "runs 20.2 s")
	_assert_names(B.fragment(9.0), "runs 36.2 s")

func test_seconds_count_together_as_its_longest() -> void:
	var bars := CutsceneBars.new()
	bars.seconds = 0.8
	var steps: Array[CutsceneStep] = [B.C.together([bars, B.C.wait(1.6)]), B.C.wait(0.6)]
	assert_float(BearerFragmentCatalog.seconds_of(steps)).is_equal_approx(2.2, 0.001)

func test_by_song_finds_the_fragment() -> void:
	var fragment := _sound()
	var catalog := B.catalog([fragment])
	assert_object(catalog.by_song(preload("res://resources/songs/freeze.tres"))).is_same(fragment)
	assert_object(catalog.by_song(preload("res://resources/songs/root.tres"))).is_null()
	assert_object(catalog.by_song(null)).is_null()
