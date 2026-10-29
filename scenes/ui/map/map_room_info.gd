class_name MapRoomInfo
extends RefCounted
## What the map knows of one room without loading its contents (systems/seeds-and-the-seller).

## The room's id, its scene file name (`Room.id`).
var room_id: StringName
## The room's `SceneKey`, which keys `map_seen` and the map's cache.
var key: String
## The `name_key` of its region; empty for a room outside a region.
var region_key: String
## World px.
var bounds: Rect2
var interior: bool


func _init(id: StringName, scene_key: String, region: String, room_bounds: Rect2, is_interior: bool) -> void:
	room_id = id
	key = scene_key
	region_key = region
	bounds = room_bounds
	interior = is_interior
