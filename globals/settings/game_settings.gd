class_name GameSettings
extends RefCounted
## The player's preferences with their defaults and clamping, and their ConfigFile form (systems/settings).

const VERSION := 1
## The buses the Sound page sets, in row order.
const VOLUME_BUSES: Array[StringName] = [AudioBuses.MASTER, AudioBuses.MUSIC, AudioBuses.NOTES, AudioBuses.SFX]
## Each bus's key in the file's [audio] section.
const BUS_KEYS: Dictionary[StringName, String] = {
	AudioBuses.MASTER: "master",
	AudioBuses.MUSIC: "music",
	AudioBuses.NOTES: "notes",
	AudioBuses.SFX: "effects",
}
const DEFAULT_SCALE := 2
const DEVICE_SECTIONS: Dictionary[KeyBindings.Device, String] = {
	KeyBindings.Device.KEYBOARD: "keyboard",
	KeyBindings.Device.PAD: "pad",
}

## Bus -> step, 0..10.
var volumes: Dictionary[StringName, int] = {}
var fullscreen: bool = false
## Window size in multiples of 640x360, 1..3.
var window_scale: int = DEFAULT_SCALE
## A shipped locale once the player picked one; empty follows the OS at each boot.
var language: String = ""
var keyboard: KeyBindings
var pad: KeyBindings


func _init(keyboard_bindings: KeyBindings = null, pad_bindings: KeyBindings = null) -> void:
	for bus: StringName in VOLUME_BUSES:
		volumes[bus] = SettingsMath.VOLUME_STEPS
	keyboard = keyboard_bindings if keyboard_bindings != null else KeyBindings.new(KeyBindings.Device.KEYBOARD)
	pad = pad_bindings if pad_bindings != null else KeyBindings.new(KeyBindings.Device.PAD)

## `cfg` over `defaults`: values out of range clamp or fall back, and a binding table the rules refuse drops that
## device's overrides with a warning.
static func from_config(cfg: ConfigFile, defaults: GameSettings) -> GameSettings:
	var made := defaults.copy()
	if cfg == null:
		return made
	for bus: StringName in VOLUME_BUSES:
		var step: Variant = cfg.get_value("audio", BUS_KEYS[bus], SettingsMath.VOLUME_STEPS)
		if step is int or step is float:
			made.volumes[bus] = clampi(int(step), 0, SettingsMath.VOLUME_STEPS)
	var full: Variant = cfg.get_value("display", "fullscreen", false)
	made.fullscreen = full is bool and full
	var scale: Variant = cfg.get_value("display", "window_scale", DEFAULT_SCALE)
	if scale is int and scale >= SettingsMath.MIN_SCALE and scale <= SettingsMath.MAX_SCALE:
		made.window_scale = scale
	var locale: Variant = cfg.get_value("general", "language", "")
	if locale is String and SettingsMath.LANGUAGES.has(locale):
		made.language = locale
	for device: KeyBindings.Device in DEVICE_SECTIONS:
		made.set_bindings(device, _read_bindings(cfg, DEVICE_SECTIONS[device], defaults.bindings(device)))
	return made

static func _read_bindings(cfg: ConfigFile, section: String, defaults: KeyBindings) -> KeyBindings:
	var table := defaults.copy()
	if not cfg.has_section(section):
		return table
	for action: StringName in KeyBindings.REBINDABLE:
		var code: Variant = cfg.get_value(section, String(action), KeyBindings.NONE)
		if code is int and code != KeyBindings.NONE:
			table.codes[action] = code
	if not BindingRules.valid(table):
		push_warning("Settings: the [%s] bindings break the share rules; using the defaults." % section)
		return defaults.copy()
	return table

## Writes every value; a language only once picked, and only the bindings that differ from `defaults`.
func to_config(cfg: ConfigFile, defaults: GameSettings) -> void:
	cfg.set_value("meta", "version", VERSION)
	for bus: StringName in VOLUME_BUSES:
		cfg.set_value("audio", BUS_KEYS[bus], volumes[bus])
	cfg.set_value("display", "fullscreen", fullscreen)
	cfg.set_value("display", "window_scale", window_scale)
	if not language.is_empty():
		cfg.set_value("general", "language", language)
	for device: KeyBindings.Device in DEVICE_SECTIONS:
		var table := bindings(device)
		var base := defaults.bindings(device)
		for action: StringName in KeyBindings.REBINDABLE:
			if table.code(action) != base.code(action):
				cfg.set_value(DEVICE_SECTIONS[device], String(action), table.code(action))

func bindings(device: KeyBindings.Device) -> KeyBindings:
	return keyboard if device == KeyBindings.Device.KEYBOARD else pad

func set_bindings(device: KeyBindings.Device, table: KeyBindings) -> void:
	if device == KeyBindings.Device.KEYBOARD:
		keyboard = table
	else:
		pad = table

func copy() -> GameSettings:
	var made := GameSettings.new(keyboard.copy(), pad.copy())
	made.volumes = volumes.duplicate()
	made.fullscreen = fullscreen
	made.window_scale = window_scale
	made.language = language
	return made
