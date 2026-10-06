class_name Notebook
extends MenuScreen
## The field notebook (design 02, UI): a section's list on the left page, the focused entry on the right. It holds the world while open.
## Plan: docs/knowledge/architecture/notebook-entries-are-derived-from-the-save.md.

## The closing animation finished; Screens closes the screen.
signal close_requested

enum Phase { SHUT, OPENING, OPEN, TURNING, CLOSING }

## Top-left of the open book in pack px, inside the 320x180 Art root.
const BOOK_ORIGIN := Vector2(24, 10)
## The strips are bottom-aligned on the open book, which is this tall.
const BOOK_HEIGHT := 160
const STRIP_FRAMES := 8
const SECTION_KEYS: Dictionary[NotebookEntry.Section, String] = {
	NotebookEntry.Section.LORE: "NOTEBOOK_SECTION_LORE",
	NotebookEntry.Section.SONGS: "NOTEBOOK_SECTION_SONGS",
	NotebookEntry.Section.ITEMS: "NOTEBOOK_SECTION_ITEMS",
	NotebookEntry.Section.GUARDIANS: "NOTEBOOK_SECTION_GUARDIANS",
}
const UNKNOWN_KEY := "NOTEBOOK_UNKNOWN"
const ROW := preload("res://scenes/ui/notebook/notebook_row.tscn")

@export var catalog: NotebookCatalog
@export var songs: SongCatalog
## Every guardian's stats: a guardian page reads the song and the recalled skills it taught.
@export var guardians: Array[GuardianStats] = []
## Indexed by Enums.GlyphSet.
@export var glyph_sets: Array[NoteGlyphSet] = []
@export var opening_strip: Texture2D
@export var next_page_strip: Texture2D
@export var previous_page_strip: Texture2D
## Indexed by NotebookEntry.Section.
@export var tab_normal: Array[Texture2D] = []
@export var tab_selected: Array[Texture2D] = []
## Real seconds each strip frame is shown.
@export var frame_seconds: float = 0.05
## The grey of a corrupted guardian's portrait.
@export var forgotten_material: Material

## Set through Screens; the notebook opens on the newest unread entry it announced.
var watcher: NotebookWatcher

var _phase: Phase = Phase.SHUT
var _section: NotebookEntry.Section = NotebookEntry.Section.LORE
## The entry last focused in each section, so a section reopens where it was left.
var _focus_by_section: Dictionary[NotebookEntry.Section, StringName] = {}
## The entry on the right page; it counts as read once it leaves.
var _showing: NotebookEntry
var _tween: Tween
## The open-strip frame on screen, so a close during the opening runs back from it.
var _strip_frame: int = 0
## The row the list is framed around; null frames from the top.
var _framed: NotebookRow
## Index of the first row the frame starts from: 0 for a new section, else the first shown when focus last moved.
## Settling layout passes all reframe from it, so a stale pass cannot carry the window down.
var _base_first: int = 0
## Index of the first row shown now.
var _shown_first: int = 0

@onready var _book: TextureRect = %Book
@onready var _flip: Sprite2D = %Flip
@onready var _pages: Control = %Pages
@onready var _section_title: Label = %SectionTitle
@onready var _list: ScrollContainer = %List
@onready var _rows: VBoxContainer = %Rows
@onready var _more_above: Control = %MoreAbove
@onready var _more_below: Control = %MoreBelow
@onready var _portrait: TextureRect = %Portrait
@onready var _detail: VBoxContainer = %Detail
@onready var _entry_title: Label = %EntryTitle
@onready var _notes: Control = %Notes
@onready var _line: Label = %Line
@onready var _taught: Label = %Taught
@onready var _body: Label = %Body
@onready var _tabs: Control = %Tabs


## The skills `stats`' moves make Ivo recall, in move order.
static func recalled_skills(stats: GuardianStats) -> Array[Enums.PlayerSkill]:
	var skills: Array[Enums.PlayerSkill] = []
	for attack: GuardianAttack in stats.attacks:
		if attack.recall != null and not skills.has(attack.recall.skill):
			skills.append(attack.recall.skill)
	return skills

static func skill_key(skill: Enums.PlayerSkill) -> String:
	return "SKILL_" + Enums.PlayerSkill.keys()[skill]

func _ready() -> void:
	var problems := catalog.validate()
	assert(problems.is_empty(), "NotebookCatalog: %s" % ", ".join(problems))
	assert(glyph_sets.size() == Enums.GlyphSet.size(),
		"Notebook has %d glyph sets for %d members of Enums.GlyphSet." % [glyph_sets.size(), Enums.GlyphSet.size()])
	for section: NotebookEntry.Section in SECTION_KEYS:
		_tab(section).pressed.connect(turn_to.bind(section))
	InputDevice.device_changed.connect(_on_device_changed)
	# Autowrapped rows settle over several sorts; the window is kept on the final layout.
	_rows.sort_children.connect(func() -> void: _reframe.call_deferred())
	_shut()

## Opens on the section of the newest unread entry with that entry focused, else on the section last viewed.
func open() -> void:
	show()
	var data := SaveSystem.player_data
	var newest := NotebookIndex.newest_unread(catalog, data, watcher.recent if watcher != null else ([] as Array[StringName]))
	if newest != &"":
		_section = catalog.get_entry(newest).section
		_focus_by_section[_section] = newest
	_build_section(data)
	_set_open_parts(false)
	_phase = Phase.OPENING
	_play(opening_strip, 0, STRIP_FRAMES - 1, _on_opened)

func close() -> void:
	_leave_entry()
	_shut()

## Plays the book shut; Screens closes the screen on `close_requested`.
func step_back() -> bool:
	match _phase:
		Phase.SHUT:
			return false
		Phase.CLOSING:
			return true
	var from := _strip_frame if _phase == Phase.OPENING else STRIP_FRAMES - 1
	_leave_entry()
	_set_open_parts(false)
	_phase = Phase.CLOSING
	_play(opening_strip, from, 0, close_requested.emit)
	return true

func phase() -> Phase:
	return _phase

func section() -> NotebookEntry.Section:
	return _section

## +1 turns to the next section, -1 to the previous; ignored while the book moves or at either end.
func turn(direction: int) -> void:
	turn_to(clampi(_section + direction, 0, SECTION_KEYS.size() - 1) as NotebookEntry.Section)

func turn_to(target: NotebookEntry.Section) -> void:
	if _phase != Phase.OPEN or target == _section:
		return
	var strip := next_page_strip if target > _section else previous_page_strip
	_leave_entry()
	_section = target
	_refresh_tabs(SaveSystem.player_data)
	_pages.hide()
	_book.hide()
	_phase = Phase.TURNING
	_play(strip, 0, STRIP_FRAMES - 1, _on_turned)

## Fills the right page with `entry` as `data` knows it; null clears it.
func render_entry(entry: NotebookEntry, data: PlayerData) -> void:
	_detail.visible = entry != null
	_portrait.visible = entry != null and entry.art != null
	if entry == null:
		return
	_entry_title.text = tr(entry.title_key)
	_notes.visible = entry.section == NotebookEntry.Section.SONGS
	if _notes.visible:
		_show_notes(songs.get_song(entry.index as Enums.Song).notes)
	_line.visible = true
	_taught.visible = false
	match entry.section:
		NotebookEntry.Section.GUARDIANS:
			var restored := data.restored_guardians[entry.index]
			_line.text = tr("NOTEBOOK_GUARDIAN_RESTORED" if restored else "NOTEBOOK_GUARDIAN_CORRUPTED")
			var taught := _taught_names(entry.index as Enums.Guardian, data)
			_taught.visible = not taught.is_empty()
			_taught.text = "%s %s" % [tr("NOTEBOOK_GUARDIAN_TAUGHT"), ", ".join(taught)]
			_portrait.texture = entry.art
			_portrait.material = null if restored else forgotten_material
		_:
			_line.visible = not entry.detail_key.is_empty()
			_line.text = tr(entry.detail_key) if _line.visible else ""
	_body.text = tr(entry.body_key)

func rows() -> Array[NotebookRow]:
	var found: Array[NotebookRow] = []
	for child: Node in _rows.get_children():
		if child is NotebookRow and not child.is_queued_for_deletion():
			found.append(child)
	return found

## Translated names of what `guardian` taught that `data` holds: its song once restored, then each recalled skill learned.
func _taught_names(guardian: Enums.Guardian, data: PlayerData) -> PackedStringArray:
	var names := PackedStringArray()
	var stats := _stats_for(guardian)
	if stats == null:
		return names
	if data.restored_guardians[guardian]:
		names.append(tr(stats.song.title_key))
	for skill: Enums.PlayerSkill in recalled_skills(stats):
		if data.unlocked_player_skills[skill]:
			names.append(tr(skill_key(skill)))
	return names

func _stats_for(guardian: Enums.Guardian) -> GuardianStats:
	for stats: GuardianStats in guardians:
		if stats.id == guardian:
			return stats
	return null

## The scene sets the 16 px glyphs 14 px apart from x -3, as in the approved mockup: the glyphs' 3 px transparent margin
## falls outside the page and the ink stays inside it (notebook_text_fit_test).
func _show_notes(notes: Array[Enums.Note]) -> void:
	var glyphs := glyph_sets[InputDevice.glyph_set]
	for i: int in _notes.get_child_count():
		var slot := _notes.get_child(i) as TextureRect
		slot.visible = i < notes.size()
		if slot.visible:
			slot.texture = glyphs.texture(notes[i], false)

func _on_device_changed(_glyph_set: Enums.GlyphSet) -> void:
	if _showing != null and _showing.section == NotebookEntry.Section.SONGS:
		_show_notes(songs.get_song(_showing.index as Enums.Song).notes)

func _build_section(data: PlayerData) -> void:
	_section_title.text = tr(SECTION_KEYS[_section])
	for row: Node in _rows.get_children():
		_rows.remove_child(row)
		row.queue_free()
	var waiting := NotebookIndex.unread(catalog, data)
	for entry: NotebookEntry in catalog.in_section(_section):
		var known := entry.is_present(data)
		var row := ROW.instantiate() as NotebookRow
		_rows.add_child(row)
		row.setup(entry if known else null, tr(entry.title_key if known else UNKNOWN_KEY), waiting.has(entry.id))
		if known:
			row.focus_entered.connect(_on_row_focused.bind(row))
	_link_known_rows()
	_list.scroll_vertical = 0
	_base_first = 0
	_shown_first = 0
	_frame_list(null)
	render_entry(null, data)
	_refresh_tabs(data)

## Up and down step between known rows, skipping "? ? ?", by explicit neighbours: the engine's own search never
## reaches a row wholly clipped by the list (gotchas/gui-focus-skips-a-neighbour-wholly-clipped-by-a-scroll-container).
func _link_known_rows() -> void:
	var known: Array[NotebookRow] = []
	for row: NotebookRow in rows():
		if row.entry != null:
			known.append(row)
	for i: int in known.size():
		var row := known[i]
		var above := known[maxi(i - 1, 0)]
		var below := known[mini(i + 1, known.size() - 1)]
		row.focus_neighbor_top = row.get_path_to(above)
		row.focus_previous = row.focus_neighbor_top
		row.focus_neighbor_bottom = row.get_path_to(below)
		row.focus_next = row.focus_neighbor_bottom
		row.focus_neighbor_left = NodePath(".")
		row.focus_neighbor_right = NodePath(".")

## Focuses the row last focused in this section, else its first known entry.
func _focus_section() -> void:
	var wanted: StringName = _focus_by_section.get(_section, &"")
	var target: NotebookRow = null
	for row: NotebookRow in rows():
		if row.entry == null:
			continue
		if target == null or row.entry.id == wanted:
			target = row
		if row.entry.id == wanted:
			break
	if target != null:
		target.grab_focus()
	else:
		_frame_list(null)

func _on_row_focused(row: NotebookRow) -> void:
	if _showing != row.entry:
		_leave_entry()
	_showing = row.entry
	_focus_by_section[_section] = row.entry.id
	render_entry(row.entry, SaveSystem.player_data)
	_frame_list(row)

## Frames the list around `focused` once the layout has settled; null frames it from the top.
func _frame_list(focused: NotebookRow) -> void:
	if focused != _framed:
		_base_first = _shown_first
	_framed = focused
	_reframe.call_deferred()

## Scrolls by whole rows only as far as the framed row needs, refills the rows above that fit, and hides any row not
## wholly shown; `Tail` lets any row reach the top (systems/notebook, "A list longer than the page").
func _reframe() -> void:
	var focused: NotebookRow = _framed if is_instance_valid(_framed) and not _framed.is_queued_for_deletion() else null
	var all := rows()
	if all.is_empty():
		_more_above.hide()
		_more_below.hide()
		return
	var height := _list.size.y
	var top := func(i: int) -> float: return all[i].position.y
	var bottom := func(i: int) -> float: return all[i].position.y + all[i].size.y
	var first := clampi(_base_first, 0, all.size() - 1)
	var at := all.find(focused)
	if at != -1:
		var known := all.filter(func(row: NotebookRow) -> bool: return row.entry != null)
		var lowest := all.size() - 1 if known.back() == focused else at
		first = mini(first, at)
		while first < at and bottom.call(lowest) - top.call(first) > height:
			first += 1
	var last := first
	while last + 1 < all.size() and bottom.call(last + 1) - top.call(first) <= height:
		last += 1
	while first > 0 and bottom.call(last) - top.call(first - 1) <= height:
		first -= 1
	_list.scroll_vertical = int(top.call(first))
	_shown_first = first
	for i: int in all.size():
		all[i].modulate.a = 1.0 if i >= first and i <= last else 0.0
	_more_above.visible = first > 0
	_more_below.visible = last < all.size() - 1

## The entry leaving the right page has been read.
func _leave_entry() -> void:
	if _showing == null:
		return
	SaveSystem.mark_notebook_read(_showing.id)
	_showing = null
	var data := SaveSystem.player_data
	var waiting := NotebookIndex.unread(catalog, data)
	for row: NotebookRow in rows():
		row.set_unread(row.entry != null and waiting.has(row.entry.id))
	_refresh_tabs(data)

func _refresh_tabs(data: PlayerData) -> void:
	for section: NotebookEntry.Section in SECTION_KEYS:
		var tab := _tab(section)
		var selected := section == _section
		tab.texture_normal = tab_selected[section] if selected else tab_normal[section]
		tab.position.x = 1.0 if selected else 0.0
		(tab.get_node("Mark") as CanvasItem).visible = NotebookIndex.section_unread(catalog, data, section)

func _tab(section: NotebookEntry.Section) -> TextureButton:
	return _tabs.get_child(section) as TextureButton

## Shows `strip` from frame `from` to `to`, one frame per `frame_seconds` of real time, then calls `done`.
func _play(strip: Texture2D, from: int, to: int, done: Callable) -> void:
	if _tween != null:
		_tween.kill()
	_flip.texture = strip
	_flip.hframes = STRIP_FRAMES
	_flip.position = BOOK_ORIGIN - Vector2(0, strip.get_height() - BOOK_HEIGHT)
	_set_frame(from)
	_flip.show()
	# Real time: the world this book holds runs at time scale 0.
	_tween = create_tween().set_ignore_time_scale(true)
	var step := 1 if to >= from else -1
	for frame: int in range(from + step, to + step, step):
		_tween.tween_interval(frame_seconds)
		_tween.tween_callback(_set_frame.bind(frame))
	_tween.tween_interval(frame_seconds)
	_tween.tween_callback(done)

func _set_frame(frame: int) -> void:
	_flip.frame = frame
	if _flip.texture == opening_strip:
		_strip_frame = frame

func _on_opened() -> void:
	_phase = Phase.OPEN
	_set_open_parts(true)
	_focus_section()

func _on_turned() -> void:
	_phase = Phase.OPEN
	_build_section(SaveSystem.player_data)
	_flip.hide()
	_book.show()
	_pages.show()
	_focus_section()

func _set_open_parts(shown: bool) -> void:
	_book.visible = shown
	_pages.visible = shown
	_tabs.visible = shown
	_flip.visible = not shown

func _shut() -> void:
	if _tween != null:
		_tween.kill()
	_phase = Phase.SHUT
	_set_open_parts(false)
	_flip.hide()
	hide()
