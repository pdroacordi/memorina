@tool
extends EditorImportPlugin

## `.room` text -> RoomMap, once, at import. Parsing (and resolving every
## ground cell's tile) happens here so a room's load does neither.
##
## A map with any error is not imported: the errors go to the Output panel
## with their file, line and column, and the last good import stays in use.
## Entity params are checked against the placed scene here too, so a typo in
## a param name fails the import instead of silently doing nothing in game.
##
## A legend change does not reimport maps by itself; reimport them (or run
## `--import`). tests/scenes/world/rooms/maps/room_files_test.gd parses every
## map against the current legend, so a map the legend broke fails the suite.

func _get_importer_name() -> String:
	return "memorina.room_map"

func _get_visible_name() -> String:
	return "Room Map"

func _get_recognized_extensions() -> PackedStringArray:
	return PackedStringArray(["room"])

func _get_save_extension() -> String:
	return "res"

func _get_resource_type() -> String:
	return "Resource"

func _get_priority() -> float:
	return 1.0

func _get_import_order() -> int:
	return 0

func _get_preset_count() -> int:
	return 1

func _get_preset_name(_preset_index: int) -> String:
	return "Default"

func _get_import_options(_path: String, _preset_index: int) -> Array[Dictionary]:
	return []

func _get_option_visibility(_path: String, _option_name: StringName, _options: Dictionary) -> bool:
	return true

func _import(source_file: String, save_path: String, _options: Dictionary,
		_platform_variants: Array[String], _gen_files: Array[String]) -> Error:
	var text := FileAccess.get_file_as_string(source_file)
	if text.is_empty() and FileAccess.get_open_error() != OK:
		push_error("%s: could not be read" % source_file)
		return FileAccess.get_open_error()
	var result := RoomMapValidator.validate(text, RoomLegend.load_default(), source_file)
	for warning: String in result.warnings:
		push_warning(warning)
	if not result.ok():
		for error: String in result.errors:
			push_error(error)
		return ERR_PARSE_ERROR
	return ResourceSaver.save(result.map, "%s.%s" % [save_path, _get_save_extension()])
