class_name SettingsScreen
extends Control
## The Settings panel the pause menu and the title open: four pages of rows, the capture of a new binding and the
## reset confirmations. Values reach Settings live; closing commits them (systems/settings).

enum Page { SOUND, GENERAL, KEYBOARD, PAD }

const TAB_KEYS: Dictionary[Page, String] = {
	Page.SOUND: "SETTINGS_TAB_SOUND",
	Page.GENERAL: "SETTINGS_TAB_GENERAL",
	Page.KEYBOARD: "SETTINGS_TAB_KEYBOARD",
	Page.PAD: "SETTINGS_TAB_PAD",
}
const VOLUME_KEYS: Dictionary[StringName, String] = {
	AudioBuses.MASTER: "SETTINGS_VOLUME_MASTER",
	AudioBuses.MUSIC: "SETTINGS_VOLUME_MUSIC",
	AudioBuses.NOTES: "SETTINGS_VOLUME_NOTES",
	AudioBuses.SFX: "SETTINGS_VOLUME_EFFECTS",
}
const LANGUAGE_KEYS: Dictionary[String, String] = {"en": "LANGUAGE_EN", "pt_BR": "LANGUAGE_PT_BR"}
const RESET_KEY := "SETTINGS_RESET_BINDINGS"
## Real seconds the Music preview plays, and its fade out.
const MUSIC_PREVIEW := 1.5
const MUSIC_PREVIEW_FADE := 0.3

## Whether a Music step plays its sample. Off at the title, whose theme already plays on that bus.
@export var music_preview: bool = true

## The owner's menu reader; capture mode runs through it. Set by PauseMenu and Title.
var menu_input: MenuInput:
	set(value):
		menu_input = value
		menu_input.bind_pressed.connect(_on_bind_pressed)
		menu_input.capture_cancelled.connect(_on_capture_cancelled)

var _page: Page = Page.SOUND
var _tabs: Dictionary[Page, Button] = {}
var _pages: Dictionary[Page, Control] = {}
var _volume_rows: Array[SettingRow] = []
var _language_row: SettingRow
var _fullscreen_row: SettingRow
var _window_row: SettingRow
var _binding_rows: Array[BindingRow] = []
var _reset_rows: Dictionary[KeyBindings.Device, Button] = {}
## The row waiting for a press; null when not capturing.
var _capturing: BindingRow
var _previews: Dictionary[StringName, AudioStreamPlayer] = {}
var _music_tween: Tween

@onready var _sheet: Control = %Sheet
@onready var _status: Label = %Status
@onready var _shield: Control = %CaptureShield
@onready var _confirms: Dictionary[KeyBindings.Device, ConfirmPanel] = {
	KeyBindings.Device.KEYBOARD: %ConfirmResetKeyboard,
	KeyBindings.Device.PAD: %ConfirmResetPad,
}


func _ready() -> void:
	_tabs = {Page.SOUND: %SoundTab, Page.GENERAL: %GeneralTab, Page.KEYBOARD: %KeyboardTab, Page.PAD: %PadTab}
	_pages = {Page.SOUND: %SoundPage, Page.GENERAL: %GeneralPage, Page.KEYBOARD: %KeyboardPage, Page.PAD: %PadPage}
	_previews = {
		AudioBuses.MASTER: %MasterPreview, AudioBuses.MUSIC: %MusicPreview,
		AudioBuses.NOTES: %NotesPreview, AudioBuses.SFX: %SfxPreview,
	}
	for page: Page in _tabs:
		_tabs[page].focus_entered.connect(_show_page.bind(page))
		# After MenuEntry's own handler, which drops the Selected look.
		_tabs[page].focus_exited.connect(_mark_tab)
		_tabs[page].pressed.connect(_focus_first_row)
	_build_rows()
	for device: KeyBindings.Device in _confirms:
		_confirms[device].confirmed.connect(_on_reset_confirmed.bind(device))
		_confirms[device].cancelled.connect(step_back)
		_confirms[device].close()
	Settings.bindings_changed.connect(_refresh_bindings)
	InputDevice.device_changed.connect(_refresh_bindings.unbind(1))
	_shield.hide()
	_retranslate()
	hide()

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_retranslate()

## Shows the Sound page with its tab focused.
func open() -> void:
	show()
	_sheet.show()
	_status.text = ""
	_refresh_values()
	_refresh_bindings()
	_show_page(Page.SOUND)
	_tabs[Page.SOUND].grab_focus()

## Ends any capture or question and writes what changed.
func close() -> void:
	_end_capture()
	for confirm: ConfirmPanel in _confirms.values():
		confirm.close()
	_sheet.show()
	hide()
	Settings.commit()

## Closes a reset question onto its row; true when it did.
func step_back() -> bool:
	for device: KeyBindings.Device in _confirms:
		if _confirms[device].visible:
			_confirms[device].close()
			_sheet.show()
			_reset_rows[device].grab_focus()
			return true
	return false

## Left or right on the focused value row; true when a value row took it, so the owner consumes the press.
func step(direction: int) -> bool:
	if not visible or not _sheet.visible or _capturing != null:
		return false
	var row := get_viewport().gui_get_focus_owner() as SettingRow
	if row == null or not _pages[_page].is_ancestor_of(row):
		return false
	_step_row(row, direction, false)
	return true

func page() -> Page:
	return _page

func is_capturing() -> bool:
	return _capturing != null

## The status line as shown.
func status() -> String:
	return _status.text

func _build_rows() -> void:
	for bus: StringName in GameSettings.VOLUME_BUSES:
		var row := SettingRow.make(SettingRow.Kind.VOLUME, VOLUME_KEYS[bus], bus)
		_add_row(Page.SOUND, row)
		_volume_rows.append(row)
	_language_row = SettingRow.make(SettingRow.Kind.LANGUAGE, "SETTINGS_LANGUAGE")
	_fullscreen_row = SettingRow.make(SettingRow.Kind.FULLSCREEN, "SETTINGS_FULLSCREEN")
	_window_row = SettingRow.make(SettingRow.Kind.WINDOW, "SETTINGS_WINDOW_SIZE")
	for row: SettingRow in [_language_row, _fullscreen_row, _window_row]:
		_add_row(Page.GENERAL, row)
	for device: KeyBindings.Device in [KeyBindings.Device.KEYBOARD, KeyBindings.Device.PAD]:
		var page := Page.KEYBOARD if device == KeyBindings.Device.KEYBOARD else Page.PAD
		for action: StringName in KeyBindings.REBINDABLE:
			var binding := BindingRow.make(device, action)
			binding.pressed.connect(_begin_capture.bind(binding))
			binding.focus_exited.connect(_clear_status)
			_pages[page].add_child(binding)
			_binding_rows.append(binding)
		var reset := Button.new()
		reset.name = "Reset"
		SettingRow.compact(reset)
		reset.pressed.connect(_ask_reset.bind(device))
		reset.focus_exited.connect(_clear_status)
		_pages[page].add_child(reset)
		_reset_rows[device] = reset

func _add_row(page: Page, row: SettingRow) -> void:
	row.pressed.connect(_step_row.bind(row, 1, true))
	_pages[page].add_child(row)
	row.focus_exited.connect(_clear_status)

func _retranslate() -> void:
	for page: Page in _tabs:
		_tabs[page].text = tr(TAB_KEYS[page])
	for reset: Button in _reset_rows.values():
		reset.text = tr(RESET_KEY)
	if visible:
		_refresh_values()
		_refresh_bindings()

func _show_page(page: Page) -> void:
	_page = page
	for each: Page in _pages:
		_pages[each].visible = each == page
	_mark_tab()
	_link_focus()

## The shown page's tab keeps the Selected look while a row has the focus.
func _mark_tab() -> void:
	for page: Page in _tabs:
		var tab := _tabs[page]
		tab.theme_type_variation = MenuEntry.FOCUSED_VARIATION if page == _page or tab.has_focus() else &""

func _clear_status() -> void:
	if _capturing == null:
		_status.text = ""

func _focus_first_row() -> void:
	var rows := _focusable_rows()
	if not rows.is_empty():
		rows[0].grab_focus()

func _focusable_rows() -> Array[Control]:
	var rows: Array[Control] = []
	for child: Node in _pages[_page].get_children():
		var row := child as Control
		if row != null and row.focus_mode != Control.FOCUS_NONE:
			rows.append(row)
	return rows

## Tabs go left and right; down from a tab is the page's first row, up from it is the tab; rows never move sideways.
func _link_focus() -> void:
	var order: Array[Page] = [Page.SOUND, Page.GENERAL, Page.KEYBOARD, Page.PAD]
	var rows := _focusable_rows()
	for i: int in order.size():
		var tab := _tabs[order[i]]
		tab.focus_neighbor_left = tab.get_path_to(_tabs[order[maxi(i - 1, 0)]])
		tab.focus_neighbor_right = tab.get_path_to(_tabs[order[mini(i + 1, order.size() - 1)]])
		tab.focus_neighbor_top = tab.get_path_to(tab)
		tab.focus_neighbor_bottom = tab.get_path_to(rows[0] if not rows.is_empty() else tab)
	for i: int in rows.size():
		var row := rows[i]
		row.focus_neighbor_top = row.get_path_to(rows[i - 1] if i > 0 else _tabs[_page])
		row.focus_neighbor_bottom = row.get_path_to(rows[mini(i + 1, rows.size() - 1)])
		row.focus_neighbor_left = row.get_path_to(row)
		row.focus_neighbor_right = row.get_path_to(row)

## Accept advances a list row and wraps; left and right step it and clamp. A volume only steps.
func _step_row(row: SettingRow, direction: int, wrap: bool) -> void:
	match row.kind:
		SettingRow.Kind.VOLUME:
			if wrap:
				return
			var was := Settings.volume(row.bus)
			Settings.set_volume(row.bus, was + direction)
			if Settings.volume(row.bus) != was:
				_preview(row.bus)
		SettingRow.Kind.LANGUAGE:
			var languages := SettingsMath.LANGUAGES
			var index := languages.find(Settings.current_language()) + direction
			index = posmod(index, languages.size()) if wrap else clampi(index, 0, languages.size() - 1)
			if languages[index] != Settings.current_language() or wrap:
				Settings.set_language(languages[index])
		SettingRow.Kind.FULLSCREEN:
			var on := not Settings.fullscreen() if wrap else direction > 0
			if on != Settings.fullscreen():
				Settings.set_fullscreen(on)
		SettingRow.Kind.WINDOW:
			var usable := Settings.usable_screen()
			var next := SettingsMath.step_scale(Settings.window_scale(), direction, usable)
			if wrap and next == Settings.window_scale():
				next = SettingsMath.MIN_SCALE
			if next != Settings.window_scale():
				Settings.set_window_scale(next)
	_refresh_values()

func _refresh_values() -> void:
	for row: SettingRow in _volume_rows:
		var step := Settings.volume(row.bus)
		row.show_value(str(step), step)
	_language_row.show_value(tr(LANGUAGE_KEYS.get(Settings.current_language(), "LANGUAGE_EN")))
	_fullscreen_row.show_value(tr("SETTINGS_ON" if Settings.fullscreen() else "SETTINGS_OFF"))
	var scale := Settings.window_scale()
	var size_px := SettingsMath.window_size(scale)
	_window_row.show_value(tr("SETTINGS_WINDOW_SCALE") % [scale, size_px.x, size_px.y])
	var windowed := not Settings.fullscreen()
	if _window_row.disabled == windowed:
		_window_row.disabled = not windowed
		_window_row.focus_mode = Control.FOCUS_ALL if windowed else Control.FOCUS_NONE
		_window_row.show_value(_window_row.value_text())
		if _page == Page.GENERAL:
			_link_focus()

func _refresh_bindings() -> void:
	var family := Enums.GlyphSet.PLAYSTATION if InputDevice.glyph_set == Enums.GlyphSet.PLAYSTATION else Enums.GlyphSet.XBOX
	var tables: Dictionary[KeyBindings.Device, KeyBindings] = {
		KeyBindings.Device.KEYBOARD: Settings.bindings(KeyBindings.Device.KEYBOARD),
		KeyBindings.Device.PAD: Settings.bindings(KeyBindings.Device.PAD),
	}
	for row: BindingRow in _binding_rows:
		if row == _capturing:
			continue
		row.show_binding(BindingNames.code_text(tables[row.device].code(row.action), row.device, family))

func _begin_capture(row: BindingRow) -> void:
	if menu_input == null or _capturing != null:
		return
	_capturing = row
	menu_input.capturing = true
	_shield.show()
	_status.text = ""
	row.show_binding(tr("SETTINGS_PRESS_KEY" if row.device == KeyBindings.Device.KEYBOARD else "SETTINGS_PRESS_BUTTON"))

func _on_bind_pressed(device: KeyBindings.Device, code: int) -> void:
	if _capturing == null or device != _capturing.device:
		return
	var result := Settings.bind(device, _capturing.action, code)
	match result.outcome:
		BindingRules.Outcome.REFUSED_RESERVED:
			_status.text = tr("SETTINGS_BIND_RESERVED")
			return
		BindingRules.Outcome.REFUSED_TAKEN:
			_status.text = tr("SETTINGS_BIND_TAKEN") % tr(BindingRow.action_key(result.other))
			return
		BindingRules.Outcome.SWAPPED:
			_status.text = tr("SETTINGS_BIND_SWAPPED") % tr(BindingRow.action_key(result.other))
		_:
			_status.text = ""
	_end_capture()

func _on_capture_cancelled() -> void:
	_status.text = ""
	_end_capture()

func _end_capture() -> void:
	if _capturing == null:
		return
	_capturing = null
	if menu_input != null:
		menu_input.capturing = false
	_shield.hide()
	_refresh_bindings()

func _ask_reset(device: KeyBindings.Device) -> void:
	_sheet.hide()
	_status.text = ""
	_confirms[device].open()

func _on_reset_confirmed(device: KeyBindings.Device) -> void:
	Settings.reset_bindings(device)
	step_back()

## The bus's sample, heard under the hold: the players are ALWAYS. The world's music itself stays paused.
func _preview(bus: StringName) -> void:
	var player := _previews[bus]
	if bus == AudioBuses.MUSIC:
		if not music_preview:
			return
		if _music_tween != null:
			_music_tween.kill()
		player.volume_db = 0.0
		player.play()
		_music_tween = create_tween().set_ignore_time_scale(true)
		_music_tween.tween_interval(MUSIC_PREVIEW - MUSIC_PREVIEW_FADE)
		_music_tween.tween_property(player, "volume_db", -40.0, MUSIC_PREVIEW_FADE)
		_music_tween.tween_callback(player.stop)
		return
	player.play()
