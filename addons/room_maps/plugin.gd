@tool
extends EditorPlugin

## Registers the `.room` importer. Rooms are authored as text
## (docs/maps/README.md); this is what turns the text into the RoomMap a
## RoomMapLayer builds from.

var _importer: EditorImportPlugin

func _enter_tree() -> void:
	_importer = preload("res://addons/room_maps/room_map_importer.gd").new()
	add_import_plugin(_importer)

func _exit_tree() -> void:
	remove_import_plugin(_importer)
	_importer = null
