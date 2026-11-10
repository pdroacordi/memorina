class_name SettingsFile
extends RefCounted
## The settings ConfigFile in one directory. An empty directory means no disk: reads answer null and writes do nothing.

var dir: String = ""
## Debug builds use their own file, as the save slots do.
var debug: bool = false


func _init(settings_dir: String, debug_build: bool) -> void:
	dir = settings_dir
	debug = debug_build

static func file_name(debug_build: bool) -> String:
	return "settings_debug.cfg" if debug_build else "settings.cfg"

func has_disk() -> bool:
	return not dir.is_empty()

## Empty when there is no disk.
func path() -> String:
	return dir.path_join(file_name(debug)) if has_disk() else ""

## The file, or null with no disk, no file or a file that does not parse.
func read() -> ConfigFile:
	var file_path := path()
	if file_path.is_empty() or not FileAccess.file_exists(file_path):
		return null
	var cfg := ConfigFile.new()
	var err := cfg.load(file_path)
	if err != OK:
		push_warning("Settings: could not read %s (%s); using the defaults." % [file_path, error_string(err)])
		return null
	return cfg

## False with no disk or when the write failed.
func write(cfg: ConfigFile) -> bool:
	var file_path := path()
	if file_path.is_empty():
		return false
	var err := cfg.save(file_path)
	if err != OK:
		push_error("Settings: could not write %s (%s)." % [file_path, error_string(err)])
	return err == OK
