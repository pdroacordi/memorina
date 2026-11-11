extends Node
## The player's preferences, applied and kept in user://; the only writer of bus volumes, the locale, the window and the
## rebindable InputMap events (systems/settings).

## A binding changed on either device; every prompt redraws.
signal bindings_changed

const PATH := "user://"
## Zoom actions and the action whose inputs they take; derived, never stored.
const FOLLOWERS: Dictionary[StringName, StringName] = {
	&"map_zoom_in": &"jump",
	&"map_zoom_out": &"attack",
}

var _defaults: GameSettings
var _settings: GameSettings
## What InputMap holds now, per device.
var _applied: Dictionary[KeyBindings.Device, KeyBindings] = {}
var _file: SettingsFile
## The file text last read or written; commit writes only when the settings encode to something else.
var _written: String = ""
## The scale the window has, which may be smaller than the saved one on a small screen.
var _window_scale: int = GameSettings.DEFAULT_SCALE


# First autoload: the locale is set before Boot swaps in the title. MEMORY sessions read, write and apply nothing.
func _ready() -> void:
	_defaults = GameSettings.new(
			KeyBindings.from_input_map(KeyBindings.Device.KEYBOARD), KeyBindings.from_input_map(KeyBindings.Device.PAD))
	_applied[KeyBindings.Device.KEYBOARD] = _defaults.keyboard.copy()
	_applied[KeyBindings.Device.PAD] = _defaults.pad.copy()
	var session := BootPolicy.decide(DisplayServer.get_name() == "headless", OS.is_debug_build(),
			OS.get_cmdline_args(), OS.get_cmdline_user_args())
	var memory_only := session == BootPolicy.Session.MEMORY
	_file = SettingsFile.new("" if memory_only else PATH, OS.is_debug_build())
	_settings = GameSettings.from_config(_file.read(), _defaults)
	_written = _encode()
	if memory_only:
		return
	for bus: StringName in GameSettings.VOLUME_BUSES:
		_apply_volume(bus)
	var picked := _settings.language
	TranslationServer.set_locale(picked if not picked.is_empty() else SettingsMath.locale_for(OS.get_locale()))
	for device: KeyBindings.Device in GameSettings.DEVICE_SECTIONS:
		_apply_bindings(device, _settings.bindings(device))
	_apply_window()

# A window close quits without closing the Settings screen, so what changed in it is written here.
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		commit()

## Nothing is read or written from now on. The playtest runner calls it.
func use_memory_only() -> void:
	_file = SettingsFile.new("", OS.is_debug_build())

func has_disk() -> bool:
	return _file.has_disk()

func volume(bus: StringName) -> int:
	return _settings.volumes.get(bus, SettingsMath.VOLUME_STEPS)

func set_volume(bus: StringName, step: int) -> void:
	_settings.volumes[bus] = clampi(step, 0, SettingsMath.VOLUME_STEPS)
	_apply_volume(bus)

func fullscreen() -> bool:
	return _settings.fullscreen

func set_fullscreen(on: bool) -> void:
	_settings.fullscreen = on
	_apply_window()

## The scale the window has now.
func window_scale() -> int:
	return _window_scale

func set_window_scale(scale: int) -> void:
	_settings.window_scale = clampi(scale, SettingsMath.MIN_SCALE, SettingsMath.MAX_SCALE)
	_apply_window()

## The usable size of the window's screen, px; the window scales that fit it.
func usable_screen() -> Vector2i:
	if DisplayServer.get_name() == "headless":
		return SettingsMath.window_size(SettingsMath.MAX_SCALE)
	return DisplayServer.screen_get_usable_rect(get_window().current_screen).size

## The picked language, else the shipped one the locale in use maps to (set from the OS at boot).
func current_language() -> String:
	if not _settings.language.is_empty():
		return _settings.language
	return SettingsMath.locale_for(TranslationServer.get_locale())

func set_language(locale: String) -> void:
	_settings.language = locale
	TranslationServer.set_locale(locale)

## Regional weather intensity in steps, 0..10.
func weather() -> int:
	return _settings.weather

func set_weather(step: int) -> void:
	_settings.weather = clampi(step, 0, GameSettings.WEATHER_STEPS)

## How much regional weather shows and pushes, 0..1; never a current, the gale or a guardian's gust.
func weather_intensity() -> float:
	return float(_settings.weather) / GameSettings.WEATHER_STEPS

## The table in use on `device`; a copy, so a caller cannot edit it.
func bindings(device: KeyBindings.Device) -> KeyBindings:
	return _settings.bindings(device).copy()

## Binds `action` to `code` on `device` by BindingRules.assign; an assignment or a swap reaches InputMap at once.
func bind(device: KeyBindings.Device, action: StringName, code: int) -> BindingRules.Assignment:
	var result := BindingRules.assign(_settings.bindings(device), action, code)
	if result.changed():
		_settings.set_bindings(device, result.bindings)
		_apply_bindings(device, result.bindings)
		bindings_changed.emit()
	return result

## Erases `device`'s overrides.
func reset_bindings(device: KeyBindings.Device) -> void:
	var table := _defaults.bindings(device).copy()
	_settings.set_bindings(device, table)
	_apply_bindings(device, table)
	bindings_changed.emit()

## Writes the file when something changed since the last read or write.
func commit() -> void:
	if not has_disk():
		return
	var text := _encode()
	if text == _written:
		return
	var cfg := ConfigFile.new()
	_settings.to_config(cfg, _defaults)
	if _file.write(cfg):
		_written = text

func _encode() -> String:
	var cfg := ConfigFile.new()
	_settings.to_config(cfg, _defaults)
	return cfg.encode_to_text()

func _apply_volume(bus: StringName) -> void:
	var index := AudioServer.get_bus_index(bus)
	if index < 0:
		return
	var step := volume(bus)
	AudioServer.set_bus_volume_db(index, SettingsMath.volume_db(step))
	AudioServer.set_bus_mute(index, step == 0)

## Moves InputMap from the applied table to `table`: each managed event changes code in place, and the zooms follow.
func _apply_bindings(device: KeyBindings.Device, table: KeyBindings) -> void:
	var from := _applied[device]
	for action: StringName in KeyBindings.REBINDABLE:
		_replace(action, device, from.code(action), table.code(action))
	for follower: StringName in FOLLOWERS:
		_replace(follower, device, from.code(FOLLOWERS[follower]), table.code(FOLLOWERS[follower]))
	_applied[device] = table.copy()

## Swaps `action`'s `device` event of `old` for one of `code`, keeping the order of its events.
static func _replace(action: StringName, device: KeyBindings.Device, old: int, code: int) -> void:
	if old == code or code == KeyBindings.NONE or not InputMap.has_action(action):
		return
	var events := InputMap.action_get_events(action)
	var replaced := false
	for i: int in events.size():
		var found := KeyBindings.code_of(events[i], device)
		if found == old and not (device == KeyBindings.Device.KEYBOARD and KeyBindings.ARROW_KEYS.has(found)):
			events[i] = KeyBindings.event_for(code, device)
			replaced = true
			break
	if not replaced:
		events.append(KeyBindings.event_for(code, device))
	InputMap.action_erase_events(action)
	for event: InputEvent in events:
		InputMap.action_add_event(action, event)

func _apply_window() -> void:
	if DisplayServer.get_name() == "headless":
		_window_scale = _settings.window_scale
		return
	var window := get_window()
	if _settings.fullscreen:
		window.mode = Window.MODE_FULLSCREEN
		return
	_window_scale = SettingsMath.largest_fitting(_settings.window_scale, usable_screen())
	window.mode = Window.MODE_WINDOWED
	window.size = SettingsMath.window_size(_window_scale)
	window.move_to_center()
