class_name NotebookCatalogTest extends GdUnitTestSuite

## The shipped notebook catalog is sound, and every key it or the notebook names has a row in translations.csv.

const CATALOG_PATH := "res://resources/ui/notebook/notebook_catalog.tres"
const CSV_PATH := "res://i18n/translations.csv"
const GUARDIAN_STATS: Array[String] = [
	"res://resources/characters/guardians/frost_guardian/frost_guardian_stats.tres",
	"res://resources/characters/guardians/bloom_guardian/bloom_guardian_stats.tres",
]


func _catalog() -> NotebookCatalog:
	return load(CATALOG_PATH) as NotebookCatalog

func _entry(id: StringName, section: NotebookEntry.Section, requirement: NotebookEntry.Requirement, index: int) -> NotebookEntry:
	var entry := NotebookEntry.new()
	entry.id = id
	entry.section = section
	entry.requirement = requirement
	entry.index = index
	entry.title_key = "T"
	entry.body_key = "B"
	return entry

## Rows keyed by their first column; the importer reads the same file.
func _csv_keys() -> Dictionary[String, PackedStringArray]:
	var rows: Dictionary[String, PackedStringArray] = {}
	var file := FileAccess.open(CSV_PATH, FileAccess.READ)
	var header := file.get_csv_line()
	assert_array(Array(header)).contains_exactly(["keys", "en", "pt_BR"])
	while not file.eof_reached():
		var row := file.get_csv_line()
		if row.size() >= 3:
			rows[row[0]] = row
	return rows

func test_the_shipped_catalog_is_valid() -> void:
	assert_array(Array(_catalog().validate())).is_empty()

func test_a_duplicate_id_is_reported() -> void:
	var catalog := NotebookCatalog.new()
	catalog.entries = _catalog().entries.duplicate()
	catalog.entries.append(_entry(catalog.entries[0].id, NotebookEntry.Section.LORE, NotebookEntry.Requirement.SKILL, 0))
	assert_array(Array(catalog.validate())).is_not_empty()

func test_a_section_with_the_wrong_requirement_is_reported() -> void:
	var catalog := NotebookCatalog.new()
	catalog.entries = _catalog().entries.duplicate()
	var wrong := _entry(&"song_wrong", NotebookEntry.Section.SONGS, NotebookEntry.Requirement.ITEM, 0)
	catalog.entries.append(wrong)
	assert_str(", ".join(catalog.validate())).contains("song_wrong")

func test_a_missing_song_is_reported() -> void:
	var catalog := NotebookCatalog.new()
	for entry: NotebookEntry in _catalog().entries:
		if entry.id != &"song_rain":
			catalog.entries.append(entry)
	assert_array(Array(catalog.validate())).is_not_empty()

func test_there_is_one_entry_per_song_item_and_guardian() -> void:
	var catalog := _catalog()
	assert_array(catalog.in_section(NotebookEntry.Section.SONGS)).has_size(Enums.Song.size())
	assert_array(catalog.in_section(NotebookEntry.Section.ITEMS)).has_size(Enums.PlayerItem.size())
	assert_array(catalog.in_section(NotebookEntry.Section.GUARDIANS)).has_size(Enums.Guardian.size())

## The user's "Story order": the approved drafts' order.
func test_entries_keep_story_order() -> void:
	var ids: Array[StringName] = []
	for entry: NotebookEntry in _catalog().in_section(NotebookEntry.Section.SONGS):
		ids.append(entry.id)
	assert_array(ids).contains_exactly([&"song_freeze", &"song_bell_jar", &"song_release", &"song_gale",
			&"song_root", &"song_rain", &"song_shadow", &"song_solstice"])

func test_every_guardian_has_a_portrait() -> void:
	for entry: NotebookEntry in _catalog().in_section(NotebookEntry.Section.GUARDIANS):
		assert_object(entry.art).is_not_null()

func test_every_catalog_key_has_both_languages() -> void:
	var rows := _csv_keys()
	for entry: NotebookEntry in _catalog().entries:
		for key: String in entry.keys():
			assert_bool(rows.has(key)).override_failure_message("%s names %s, which is not in the CSV" % [entry.id, key]).is_true()
			assert_str(rows[key][1]).is_not_empty()
			assert_str(rows[key][2]).is_not_empty()

## The labels the screen sets itself, and the name of every skill a guardian makes Ivo recall.
func test_every_screen_key_has_both_languages() -> void:
	var rows := _csv_keys()
	var keys: Array[String] = [Notebook.UNKNOWN_KEY, "NOTEBOOK_GUARDIAN_CORRUPTED", "NOTEBOOK_GUARDIAN_RESTORED", "NOTEBOOK_GUARDIAN_TAUGHT"]
	keys.append_array(Notebook.SECTION_KEYS.values())
	for path: String in GUARDIAN_STATS:
		var stats := load(path) as GuardianStats
		assert_bool(rows.has(stats.song.title_key)).is_true()
		for skill: Enums.PlayerSkill in Notebook.recalled_skills(stats):
			keys.append(Notebook.skill_key(skill))
	for key: String in keys:
		assert_bool(rows.has(key)).override_failure_message("%s is not in the CSV" % key).is_true()

func test_presence_follows_the_save() -> void:
	var data := PlayerData.new()
	var song := _entry(&"s", NotebookEntry.Section.SONGS, NotebookEntry.Requirement.SONG, Enums.Song.RAIN)
	assert_bool(song.is_present(data)).is_false()
	data.learned_songs[Enums.Song.RAIN] = true
	assert_bool(song.is_present(data)).is_true()

## A restored guardian was met, so a save from before met_guardians shows it.
func test_a_guardian_is_met_once_fought_or_restored() -> void:
	var met := _entry(&"g", NotebookEntry.Section.GUARDIANS, NotebookEntry.Requirement.GUARDIAN_MET, Enums.Guardian.BLOOM)
	var data := PlayerData.new()
	assert_bool(met.is_present(data)).is_false()
	data.restored_guardians[Enums.Guardian.BLOOM] = true
	assert_bool(met.is_present(data)).is_true()
	data = PlayerData.new()
	data.met_guardians[Enums.Guardian.BLOOM] = true
	assert_bool(met.is_present(data)).is_true()
