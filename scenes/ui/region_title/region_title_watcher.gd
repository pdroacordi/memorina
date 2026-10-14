class_name RegionTitleWatcher
extends Node
## Announces a region's title on its first entry and records it in the save; draws nothing.

## A region entered for the first time; the keys are translation keys.
signal announced(name_key: String, epithet_key: String)

var _seeded: bool = false


## Connected to `Game.room_changed`.
func on_room_changed(room: Room) -> void:
	if not _seeded:
		_record_explored(get_tree().get_nodes_in_group(Room.GROUP))
	var region := room.get_region()
	var key := SceneKey.of(region)
	var action := RegionTitlePolicy.decide(region.shows_title, not _seeded, SaveSystem.is_region_announced(key))
	_seeded = true
	if action == RegionTitlePolicy.Action.NONE:
		return
	SaveSystem.announce_region(key)
	if action == RegionTitlePolicy.Action.ANNOUNCE:
		announced.emit(region.name_key, region.epithet_key)

# Marks every titled region with a room on the map as shown, so a save older than the title replays none it explored.
func _record_explored(rooms: Array[Node]) -> void:
	for node: Node in rooms:
		var room := node as Room
		var region := room.get_region()
		if region.shows_title and not SaveSystem.map_seen(SceneKey.of(room)).is_empty():
			SaveSystem.announce_region(SceneKey.of(region))
