class_name FlashbackCatalogTest extends GdUnitTestSuite

## FlashbackCatalog.validate names a number outside 1..5 or listed twice, a missing scene or one not in the cutscene
## catalog, a leaving id that is not flashback_<n>, a returning scene naming more than Ivo, and music marks outside the
## visit's music. The shipped catalog is sound.

const F := preload("res://tests/resources/story/flashbacks/flashback_fixture.gd")
const C := preload("res://tests/resources/cutscene/cutscene_fixture.gd")


func _problems(flashbacks: Array[Flashback]) -> PackedStringArray:
	return F.catalog(flashbacks).validate(F.cutscenes(flashbacks))

func test_the_fixture_is_sound() -> void:
	assert_array(Array(_problems([F.flashback(1), F.flashback(2)]))).is_empty()

func test_numbers_lie_in_one_to_five_once() -> void:
	assert_array(Array(_problems([F.flashback(0)]))).is_not_empty()
	assert_array(Array(_problems([F.flashback(6)]))).is_not_empty()
	var twin := F.flashback(1)
	twin.crossing = C.scene(&"other_crossing", [])
	assert_array(Array(_problems([F.flashback(1), twin]))).is_not_empty()

func test_every_scene_is_set_and_in_the_cutscene_catalog() -> void:
	var made := F.flashback(1)
	assert_array(Array(F.catalog([made]).validate(CutsceneCatalog.new()))).is_not_empty()
	made.opening = null
	assert_array(Array(_problems([made]))).is_not_empty()

func test_the_leaving_scene_is_the_flashbacks_seen_id() -> void:
	var made := F.flashback(2)
	made.leaving = C.scene(&"flashback_3", [])
	assert_array(Array(_problems([made]))).is_not_empty()

func test_the_returning_scene_names_only_ivo() -> void:
	var made := F.flashback(1)
	made.returning = C.scene(&"fixture_returning_1", [C.walk(&"alba", 10.0)])
	assert_array(Array(_problems([made]))).is_not_empty()
	made.returning = C.scene(&"fixture_returning_1", [C.walk(CutsceneStep.IVO, 10.0)])
	assert_array(Array(_problems([made]))).is_empty()

## The fixture's music is 2 s long.
func test_music_marks_lie_inside_the_visits_music() -> void:
	var made := F.flashback(1)
	made.entry_mark = 2.5
	assert_array(Array(_problems([made]))).is_not_empty()
	made.entry_mark = 1.5
	var mark := CutsceneMusicMark.new()
	mark.seconds = 3.0
	made.leaving = C.scene(&"flashback_1", [mark])
	assert_array(Array(_problems([made]))).is_not_empty()
	mark.seconds = 1.0
	assert_array(Array(_problems([made]))).is_empty()
	made.music = null
	assert_array(Array(_problems([made]))).is_not_empty()

func test_the_crossing_finds_its_flashback() -> void:
	var one := F.flashback(1)
	var two := F.flashback(2)
	var catalog := F.catalog([one, two])
	assert_object(catalog.by_crossing(two.crossing)).is_same(two)
	assert_object(catalog.by_crossing(one.opening)).is_null()
	assert_object(catalog.by_crossing(null)).is_null()

func test_the_shipped_catalog_is_sound() -> void:
	var catalog := load("res://resources/story/flashbacks/flashback_catalog.tres") as FlashbackCatalog
	var cutscenes := load("res://resources/cutscene/cutscene_catalog.tres") as CutsceneCatalog
	assert_array(Array(catalog.validate(cutscenes))).is_empty()
