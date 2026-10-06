class_name NotebookTest extends GdUnitTestSuite

## The notebook opens on the newest unread entry, lists unknown entries as unfocusable placeholders,
## turns pages between sections, marks an entry read once it leaves the page, and plays itself shut.

const NOTEBOOK := preload("res://scenes/ui/notebook/notebook.tscn")

var _notebook: Notebook
var _closed: int = 0


func before_test() -> void:
	SaveSystem.begin("", true)
	# A debug save starts owning the sword and the Memorina; read, they leave the opening to the test.
	for id: StringName in NotebookIndex.present(load("res://resources/ui/notebook/notebook_catalog.tres"), SaveSystem.player_data):
		SaveSystem.mark_notebook_read(id)
	_closed = 0
	_notebook = auto_free(NOTEBOOK.instantiate()) as Notebook
	_notebook.frame_seconds = 0.0
	add_child(_notebook)
	_notebook.close_requested.connect(func() -> void: _closed += 1)

func after_test() -> void:
	SaveSystem.begin("", true)

func _settle() -> void:
	for i: int in 4:
		await await_idle_frame()

func _open() -> void:
	_notebook.open()
	await _settle()

func _focused() -> NotebookRow:
	return get_viewport().gui_get_focus_owner() as NotebookRow

func test_it_opens_through_the_opening_strip() -> void:
	_notebook.open()
	assert_int(_notebook.phase()).is_equal(Notebook.Phase.OPENING)
	assert_bool((_notebook.find_child("Pages") as CanvasItem).visible).is_false()
	await _settle()
	assert_int(_notebook.phase()).is_equal(Notebook.Phase.OPEN)
	assert_bool((_notebook.find_child("Pages") as CanvasItem).visible).is_true()
	assert_bool((_notebook.find_child("Flip") as CanvasItem).visible).is_false()

## "Newest unread, else last": the debug save's items are unread too, but the song arrived last.
func test_it_opens_on_the_newest_unread_entry() -> void:
	var watcher := auto_free(NotebookWatcher.new()) as NotebookWatcher
	watcher.catalog = _notebook.catalog
	add_child(watcher)
	_notebook.watcher = watcher
	SaveSystem.learn_song(Enums.Song.GALE)
	await _open()
	assert_int(_notebook.section()).is_equal(NotebookEntry.Section.SONGS)
	assert_str(String(_focused().entry.id)).is_equal("song_gale")

func test_with_nothing_unread_it_opens_where_it_was_left() -> void:
	SaveSystem.learn_song(Enums.Song.FREEZE)
	SaveSystem.learn_song(Enums.Song.ROOT)
	for id: StringName in NotebookIndex.unread(_notebook.catalog, SaveSystem.player_data):
		SaveSystem.mark_notebook_read(id)
	await _open()
	_notebook.turn(1)
	await _settle()
	assert_int(_notebook.section()).is_equal(NotebookEntry.Section.SONGS)
	_notebook.close()
	await _open()
	assert_int(_notebook.section()).is_equal(NotebookEntry.Section.SONGS)

func test_unknown_entries_are_unfocusable_placeholders() -> void:
	SaveSystem.learn_song(Enums.Song.FREEZE)
	await _open()
	var rows := _notebook.rows()
	assert_array(rows).has_size(Enums.Song.size())
	assert_object(rows[0].entry).is_not_null()
	for row: NotebookRow in rows.slice(1):
		assert_object(row.entry).is_null()
		assert_int(row.focus_mode).is_equal(Control.FOCUS_NONE)
		assert_str(row.label().text).is_equal(tr(Notebook.UNKNOWN_KEY))

func test_an_entry_is_read_once_it_leaves_the_page() -> void:
	SaveSystem.learn_song(Enums.Song.FREEZE)
	SaveSystem.learn_song(Enums.Song.BELL_JAR)
	await _open()
	var freeze := _notebook.rows()[0]
	freeze.grab_focus()
	await _settle()
	assert_bool(freeze.is_unread()).is_true()
	_notebook.rows()[1].grab_focus()
	await _settle()
	assert_bool(SaveSystem.is_notebook_read(&"song_freeze")).is_true()
	assert_bool(freeze.is_unread()).is_false()

func test_the_tab_of_a_section_with_something_unread_is_marked() -> void:
	SaveSystem.unlock_skill(Enums.PlayerSkill.ROLL)
	await _open()
	var lore_mark := _notebook.find_child("Tabs").get_child(NotebookEntry.Section.LORE).get_node("Mark") as CanvasItem
	var songs_mark := _notebook.find_child("Tabs").get_child(NotebookEntry.Section.SONGS).get_node("Mark") as CanvasItem
	assert_bool(lore_mark.visible).is_true()
	assert_bool(songs_mark.visible).is_false()
	_notebook.turn(1)
	await _settle()
	assert_bool(lore_mark.visible).is_false()

func test_a_page_turn_plays_the_strip_then_shows_the_next_section() -> void:
	await _open()
	var from := _notebook.section()
	_notebook.turn(1)
	assert_int(_notebook.phase()).is_equal(Notebook.Phase.TURNING)
	assert_bool((_notebook.find_child("Pages") as CanvasItem).visible).is_false()
	await _settle()
	assert_int(_notebook.section()).is_equal(from + 1)
	assert_int(_notebook.phase()).is_equal(Notebook.Phase.OPEN)

func test_turning_stops_at_either_end() -> void:
	await _open()
	_notebook.turn_to(NotebookEntry.Section.LORE)
	await _settle()
	_notebook.turn(-1)
	assert_int(_notebook.phase()).is_equal(Notebook.Phase.OPEN)

func test_back_plays_the_book_shut_then_asks_to_close() -> void:
	await _open()
	assert_bool(_notebook.step_back()).is_true()
	assert_int(_notebook.phase()).is_equal(Notebook.Phase.CLOSING)
	assert_bool(_notebook.step_back()).is_true()
	await _settle()
	assert_int(_closed).is_equal(1)

func test_back_during_the_opening_closes_from_where_it_was() -> void:
	_notebook.open()
	assert_bool(_notebook.step_back()).is_true()
	await _settle()
	assert_int(_closed).is_equal(1)

func test_a_shut_book_has_nothing_to_step_back_from() -> void:
	assert_bool(_notebook.step_back()).is_false()

## The page reads the notes in the player's own glyphs and follows a device change.
func test_a_song_shows_its_notes_in_the_current_device_glyphs() -> void:
	var was := InputDevice.glyph_set
	SaveSystem.learn_song(Enums.Song.FREEZE)
	await _open()
	var song := _notebook.songs.get_song(Enums.Song.FREEZE)
	var first := _notebook.find_child("Notes").get_child(0) as TextureRect
	assert_object(first.texture).is_equal(_notebook.glyph_sets[InputDevice.glyph_set].texture(song.notes[0], false))
	InputDevice.glyph_set = Enums.GlyphSet.XBOX
	InputDevice.device_changed.emit(Enums.GlyphSet.XBOX)
	assert_object(first.texture).is_equal(_notebook.glyph_sets[Enums.GlyphSet.XBOX].texture(song.notes[0], false))
	InputDevice.glyph_set = was

## Grey while corrupted, colour once restored; what it taught shows only once held.
func test_a_guardian_page_follows_its_restoration() -> void:
	var entry := _notebook.catalog.get_entry(&"guardian_frost")
	var data := PlayerData.new()
	data.met_guardians[Enums.Guardian.FROST] = true
	await _open()
	_notebook.render_entry(entry, data)
	var portrait := _notebook.find_child("Portrait") as TextureRect
	assert_object(portrait.material).is_same(_notebook.forgotten_material)
	assert_str((_notebook.find_child("Line") as Label).text).is_equal(tr("NOTEBOOK_GUARDIAN_CORRUPTED"))
	assert_bool((_notebook.find_child("Taught") as CanvasItem).visible).is_false()
	data.restored_guardians[Enums.Guardian.FROST] = true
	data.unlocked_player_skills[Enums.PlayerSkill.ROLL] = true
	_notebook.render_entry(entry, data)
	assert_object(portrait.material).is_null()
	assert_str((_notebook.find_child("Line") as Label).text).is_equal(tr("NOTEBOOK_GUARDIAN_RESTORED"))
	assert_str((_notebook.find_child("Taught") as Label).text).contains(tr("SONG_TITLE_FREEZE")).contains(tr("SKILL_ROLL"))

## A list longer than the page scrolls by whole rows: a shown row is never cut, and the margin cues tell what is hidden.
func test_a_long_list_never_shows_a_cut_row() -> void:
	for song: int in Enums.Song.size():
		SaveSystem.learn_song(song as Enums.Song)
	await _open()
	_notebook.turn_to(NotebookEntry.Section.SONGS)
	await _settle()
	var list := _notebook.find_child("List") as ScrollContainer
	for at: int in [Enums.Song.size() - 1, 0, 4]:
		_notebook.rows()[at].grab_focus()
		await _settle()
		var shown := 0
		var hidden_below := false
		for row: NotebookRow in _notebook.rows():
			var top := row.position.y - list.scroll_vertical
			var inside := top >= 0.0 and top + row.size.y <= list.size.y
			if row.modulate.a > 0.0:
				shown += 1
				assert_bool(inside).override_failure_message("row %s is shown but cut" % row.label().text).is_true()
			elif top >= 0.0:
				hidden_below = true
		assert_float(_notebook.rows()[at].modulate.a).is_equal(1.0)
		assert_int(shown).is_less(Enums.Song.size())
		assert_bool((_notebook.find_child("MoreBelow") as CanvasItem).visible).is_equal(hidden_below)

func _press(action: StringName) -> void:
	for pressed: bool in [true, false]:
		var event := InputEventAction.new()
		event.action = action
		event.pressed = pressed
		Input.parse_input_event(event)
		await _settle()

func _shown_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for row: NotebookRow in _notebook.rows():
		if row.modulate.a > 0.0:
			ids.append(row.entry.id if row.entry != null else &"?")
	return ids

## Real ui_down / ui_up through the engine's focus handling: the list scrolls down to the last song and all the
## way back up to the first (bugs/the-notebook-list-cannot-scroll-back-up-past-a-hidden-row).
func test_up_and_down_reach_every_known_row_of_a_scrolled_list() -> void:
	for song: int in Enums.Song.size():
		SaveSystem.learn_song(song as Enums.Song)
	for id: StringName in NotebookIndex.unread(_notebook.catalog, SaveSystem.player_data):
		SaveSystem.mark_notebook_read(id)
	await _open()
	_notebook.turn_to(NotebookEntry.Section.SONGS)
	await _settle()
	assert_str(String(_focused().entry.id)).is_equal("song_freeze")
	for i: int in Enums.Song.size() - 1:
		await _press(&"ui_down")
	assert_str(String(_focused().entry.id)).is_equal("song_solstice")
	assert_bool((_notebook.find_child("MoreAbove") as CanvasItem).visible).is_true()
	for i: int in Enums.Song.size() - 1:
		await _press(&"ui_up")
		assert_float(_focused().modulate.a).is_equal(1.0)
	assert_str(String(_focused().entry.id)).is_equal("song_freeze")
	assert_bool((_notebook.find_child("MoreAbove") as CanvasItem).visible).is_false()
	assert_array(_shown_ids().slice(0, 2)).is_equal([&"song_freeze", &"song_bell_jar"])

## Up and down skip the unknown rows.
func test_up_and_down_skip_the_placeholders() -> void:
	SaveSystem.learn_song(Enums.Song.FREEZE)
	SaveSystem.learn_song(Enums.Song.ROOT)
	for id: StringName in NotebookIndex.unread(_notebook.catalog, SaveSystem.player_data):
		SaveSystem.mark_notebook_read(id)
	await _open()
	_notebook.turn_to(NotebookEntry.Section.SONGS)
	await _settle()
	await _press(&"ui_down")
	assert_str(String(_focused().entry.id)).is_equal("song_root")
	await _press(&"ui_down")
	assert_str(String(_focused().entry.id)).is_equal("song_root")
	await _press(&"ui_up")
	assert_str(String(_focused().entry.id)).is_equal("song_freeze")

## A section reopened on its remembered row shows the rows above it that fit, and the top line is never empty.
func test_returning_to_a_section_keeps_the_rows_above_that_fit() -> void:
	for song: int in Enums.Song.size():
		SaveSystem.learn_song(song as Enums.Song)
	for id: StringName in NotebookIndex.unread(_notebook.catalog, SaveSystem.player_data):
		SaveSystem.mark_notebook_read(id)
	await _open()
	_notebook.turn_to(NotebookEntry.Section.SONGS)
	await _settle()
	_notebook.rows()[3].grab_focus()
	await _settle()
	var first_visit := _shown_ids()
	_notebook.turn_to(NotebookEntry.Section.ITEMS)
	await _settle()
	_notebook.turn_to(NotebookEntry.Section.SONGS)
	await _settle()
	assert_str(String(_focused().entry.id)).is_equal(String(_notebook.rows()[3].entry.id))
	assert_array(_shown_ids()).is_equal(first_visit)
	for at: int in [Enums.Song.size() - 1, 5]:
		_notebook.rows()[at].grab_focus()
		await _settle()
		var list := _notebook.find_child("List") as ScrollContainer
		var first_shown := _notebook.rows().filter(func(row: NotebookRow) -> bool: return row.modulate.a > 0.0)[0] as NotebookRow
		assert_float(first_shown.position.y).is_equal(float(list.scroll_vertical))

