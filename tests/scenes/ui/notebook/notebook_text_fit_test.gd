class_name NotebookTextFitTest extends GdUnitTestSuite

## Every notebook text stays inside its page's text rect, in every shipped language: the user's hard rule
## after the v2 mockup ("the text is overflowing the page"). Measured with the page's own font.

const NOTEBOOK := preload("res://scenes/ui/notebook/notebook.tscn")
const LOCALES: Array[String] = ["en", "pt_BR"]

var _notebook: Notebook
var _locale: String


func before() -> void:
	_locale = TranslationServer.get_locale()

func after() -> void:
	TranslationServer.set_locale(_locale)

func before_test() -> void:
	SaveSystem.begin("", true)
	_notebook = auto_free(NOTEBOOK.instantiate()) as Notebook
	_notebook.frame_seconds = 0.0
	add_child(_notebook)

func after_test() -> void:
	SaveSystem.begin("", true)

## Every fact the notebook can show at once, so each page is at its longest.
func _everything() -> PlayerData:
	var data := PlayerData.new()
	for flags: Array[bool] in [data.unlocked_player_skills, data.learned_songs, data.owned_items,
			data.restored_guardians, data.met_guardians]:
		flags.fill(true)
	return data

func _settle() -> void:
	for i: int in 4:
		await await_idle_frame()

func _page(page_name: String) -> Control:
	return _notebook.find_child(page_name) as Control

## Each word fits the label's width (autowrap cannot break inside a word), measured with its font.
func _assert_words_fit(label: Label, what: String) -> void:
	var font := label.get_theme_font(&"font")
	var size := label.get_theme_font_size(&"font_size")
	for line: String in label.text.split("\n"):
		for word: String in line.split(" ", false):
			var width := font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
			assert_float(width).override_failure_message(
					"%s: '%s' is %.0f px in a %.0f px line" % [what, word, width, label.size.x]).is_less_equal(label.size.x)

func _assert_labels_fit(root: Node, what: String) -> void:
	for node: Node in root.find_children("*", "Label", true, false):
		var label := node as Label
		if label.is_visible_in_tree() and not label.text.is_empty():
			_assert_words_fit(label, "%s %s" % [what, label.name])
			var lines_height := label.get_line_count() * label.get_line_height() \
					+ maxi(label.get_line_count() - 1, 0) * label.get_theme_constant(&"line_spacing")
			assert_float(label.size.y).override_failure_message(
					"%s %s: %d lines need %d px, it has %.0f" % [what, label.name, label.get_line_count(), lines_height, label.size.y]
					).is_greater_equal(lines_height)

func test_every_entry_fits_the_right_page() -> void:
	SaveSystem.player_data.unlocked_player_skills.fill(true)
	_notebook.open()
	await _settle()
	var page := _page("RightPage")
	var detail := _page("Detail")
	for locale: String in LOCALES:
		TranslationServer.set_locale(locale)
		for entry: NotebookEntry in _notebook.catalog.entries:
			for data: PlayerData in [_everything(), PlayerData.new()]:
				_notebook.render_entry(entry, data)
				await _settle()
				var needed := detail.get_combined_minimum_size().y
				assert_float(needed).override_failure_message(
						"[%s] %s needs %.0f px, the page has %.0f" % [locale, entry.id, needed, page.size.y]).is_less_equal(page.size.y)
				_assert_labels_fit(detail, "[%s] %s" % [locale, entry.id])

## Section titles and list rows wrap inside the left page; the list scrolls, so only width can overflow.
## The guardians' page also holds the portrait, with both rows still in view.
func test_every_section_fits_the_left_page() -> void:
	var everything := _everything()
	SaveSystem.player_data.unlocked_player_skills = everything.unlocked_player_skills.duplicate()
	SaveSystem.player_data.learned_songs = everything.learned_songs.duplicate()
	SaveSystem.player_data.owned_items = everything.owned_items.duplicate()
	SaveSystem.player_data.restored_guardians = everything.restored_guardians.duplicate()
	for locale: String in LOCALES:
		TranslationServer.set_locale(locale)
		_notebook.close()
		_notebook.open()
		await _settle()
		_notebook.turn_to(NotebookEntry.Section.LORE)
		await _settle()
		for section: NotebookEntry.Section in Notebook.SECTION_KEYS:
			_notebook.turn_to(section)
			await _settle()
			var page := _page("LeftPage")
			var needed := page.get_combined_minimum_size().y
			assert_float(needed).override_failure_message(
					"[%s] section %d needs %.0f px, the page has %.0f" % [locale, section, needed, page.size.y]).is_less_equal(page.size.y)
			_assert_labels_fit(page, "[%s] section %d" % [locale, section])
			if section == NotebookEntry.Section.GUARDIANS:
				var list := _page("List")
				var rows := _page("Rows")
				assert_float(list.size.y).override_failure_message(
						"[%s] guardian rows need %.0f px beside the portrait, the list has %.0f" % [locale, rows.get_combined_minimum_size().y, list.size.y]
						).is_greater_equal(rows.get_combined_minimum_size().y)

## The notes' ink, in every glyph set, stays inside the right page; the glyphs' transparent margin may not.
func test_every_note_glyph_inks_inside_the_right_page() -> void:
	var was := InputDevice.glyph_set
	SaveSystem.player_data.learned_songs.fill(true)
	_notebook.open()
	await _settle()
	var page := _page("RightPage")
	var notes := _page("Notes")
	for glyph_set: int in Enums.GlyphSet.size():
		InputDevice.glyph_set = glyph_set as Enums.GlyphSet
		for entry: NotebookEntry in _notebook.catalog.in_section(NotebookEntry.Section.SONGS):
			_notebook.render_entry(entry, SaveSystem.player_data)
			await _settle()
			for slot: Node in notes.get_children():
				var glyph := slot as TextureRect
				var used := glyph.texture.get_image().get_used_rect()
				var ink := Rect2(notes.position + glyph.position + Vector2(used.position), Vector2(used.size))
				assert_bool(Rect2(Vector2.ZERO, page.size).encloses(ink)).override_failure_message(
						"set %d, %s: %s ink at %s leaves the %s page" % [glyph_set, entry.id, glyph.name, ink, page.size]).is_true()
				assert_vector(glyph.size).is_equal(Vector2(16, 16))
	InputDevice.glyph_set = was
