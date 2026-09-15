class_name MemorinaHud extends Control

## The eight-slot grid of docs/design/02_mecanicas.md section 6.2: two songs
## per season, the ones not yet learned shown locked, visible only while the
## instrument is out.
##
## Purely an observer. It is told what happened by Ivo's signals and never
## polls, never reaches for the player, and never decides anything - so it
## cannot drift out of step with the component that actually holds the state.
##
## Placeholder visuals. Every string is a tr() key.

const LOCKED_KEY := "SONG_LOCKED"
const NOTE_KEYS: Dictionary = {
	Enums.Note.UP: "NOTE_UP",
	Enums.Note.DOWN: "NOTE_DOWN",
	Enums.Note.LEFT: "NOTE_LEFT",
	Enums.Note.RIGHT: "NOTE_RIGHT",
}

const SLOT_SIZE := Vector2(96.0, 18.0)
const LOCKED_COLOR := Color(0.18, 0.18, 0.2, 0.85)
const KNOWN_COLOR := Color(0.28, 0.3, 0.36, 0.9)
const FLASH_COLOR := Color(0.85, 0.4, 0.4, 0.95)

@export var catalog: SongCatalog

@onready var _grid: GridContainer = $Panel/Grid
@onready var _buffer_label: Label = $Panel/Buffer

## Song id -> the slot showing it, so an update is a lookup rather than a scan.
var _slots: Dictionary = {}
var _notes: Array[Enums.Note] = []
var _flash_tween: Tween
var _slot_tween: Tween

func _ready() -> void:
	hide()
	_build_slots()

## Ivo hands over exactly what he knows, so the HUD never consults the save.
func on_drawn(known_songs: Array[Song]) -> void:
	var known_ids: Dictionary = {}
	for song: Song in known_songs:
		known_ids[song.id] = true
	for id: int in _slots:
		var slot: Dictionary = _slots[id]
		var is_known: bool = known_ids.has(id)
		var label: Label = slot["label"]
		var panel: ColorRect = slot["panel"]
		label.text = tr(slot["name_key"] as String) if is_known else tr(LOCKED_KEY)
		panel.color = KNOWN_COLOR if is_known else LOCKED_COLOR
	_clear_notes()
	show()

func on_sheathed() -> void:
	_clear_notes()
	hide()

func on_note_played(note: Enums.Note) -> void:
	_notes.append(note)
	_refresh_buffer()

func on_sequence_failed() -> void:
	_flash()
	_clear_notes()

func on_song_played(song: Song, _position: Vector2) -> void:
	_clear_notes()
	if _slots.has(song.id):
		_pulse_slot(_slots[song.id]["panel"] as ColorRect)

func _build_slots() -> void:
	if catalog == null:
		return
	# Four columns, one per season, two rows - the shape of the instrument.
	_grid.columns = Enums.Season.size()
	var by_season: Array[Array] = []
	for season: int in Enums.Season.size():
		by_season.append(catalog.songs_for_season(season))
	# Derived, not hardcoded to 2: the design still has an unresolved third
	# Winter sequence (see enums.gd), and a hardcoded row count would make it
	# learnable, playable and invisible.
	var rows: int = 0
	for songs: Array in by_season:
		rows = maxi(rows, songs.size())
	for row: int in rows:
		for season: int in Enums.Season.size():
			var songs: Array = by_season[season]
			if row >= songs.size():
				_grid.add_child(Control.new())
				continue
			_grid.add_child(_make_slot(songs[row] as Song))

func _make_slot(song: Song) -> Control:
	var panel := ColorRect.new()
	panel.custom_minimum_size = SLOT_SIZE
	panel.color = LOCKED_COLOR
	var label := Label.new()
	label.text = tr(LOCKED_KEY)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_child(label)
	_slots[song.id] = {"panel": panel, "label": label, "name_key": song.name_key}
	return panel

func _clear_notes() -> void:
	_notes.clear()
	_refresh_buffer()

func _refresh_buffer() -> void:
	var parts: PackedStringArray = []
	for note: Enums.Note in _notes:
		parts.append(tr(NOTE_KEYS[note] as String))
	_buffer_label.text = " ".join(parts)

func _flash() -> void:
	# Tween the stored rest colour, never the CURRENT one: two failures inside
	# the fade would read a half-flashed value and tween back to that, leaving
	# the label permanently tinted.
	if _flash_tween and _flash_tween.is_valid():
		_flash_tween.kill()
	_buffer_label.modulate = FLASH_COLOR
	_flash_tween = create_tween()
	_flash_tween.tween_property(_buffer_label, "modulate", Color.WHITE, 0.25)

func _pulse_slot(panel: ColorRect) -> void:
	# Same reasoning as _flash(): lighten from the known rest colour so repeated
	# plays cannot compound toward white.
	if _slot_tween and _slot_tween.is_valid():
		_slot_tween.kill()
	panel.color = KNOWN_COLOR.lightened(0.5)
	_slot_tween = create_tween()
	_slot_tween.tween_property(panel, "color", KNOWN_COLOR, 0.35)
