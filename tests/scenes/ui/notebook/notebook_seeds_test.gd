class_name NotebookSeedsTest extends GdUnitTestSuite

## The seeds entry is present from the first cache and its detail line shows the seeds held, derived from the save
## ("Shop + notebook entry somewhere and load save screen", user, 2026-10-28; systems/seeds-and-the-seller).

const NOTEBOOK := preload("res://scenes/ui/notebook/notebook.tscn")

var _notebook: Notebook
var _locale: String


func before() -> void:
	_locale = TranslationServer.get_locale()
	TranslationServer.set_locale("en")

func after() -> void:
	TranslationServer.set_locale(_locale)

func before_test() -> void:
	SaveSystem.begin("", true)
	_notebook = auto_free(NOTEBOOK.instantiate()) as Notebook
	_notebook.frame_seconds = 0.0
	add_child(_notebook)

func after_test() -> void:
	SaveSystem.begin("", true)

func _entry() -> NotebookEntry:
	for entry: NotebookEntry in _notebook.catalog.entries:
		if entry.id == &"lore_seeds":
			return entry
	return null

func test_the_entry_is_present_from_the_first_cache() -> void:
	var entry := _entry()
	assert_int(entry.section).is_equal(NotebookEntry.Section.LORE)
	var data := PlayerData.new()
	assert_bool(entry.is_present(data)).is_false()
	data.caches_taken.append(&"threshold_ravine_cache")
	assert_bool(entry.is_present(data)).is_true()

func test_the_detail_line_shows_the_seeds_held() -> void:
	var data := PlayerData.new()
	data.caches_taken.append_array([&"threshold_ravine_cache", &"woods_crown_cache", &"orchard_crag_cache"])
	data.offers_bought.append(&"map_threshold")
	_notebook.render_entry(_entry(), data)
	var line := _notebook.find_child("Line", true, false) as Label
	assert_str(line.text).is_equal(tr("NOTEBOOK_LORE_SEEDS_HELD") % 2)
	assert_bool(line.visible).is_true()
