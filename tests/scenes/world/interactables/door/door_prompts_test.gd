class_name DoorPromptsTest extends GdUnitTestSuite

## Every door's prompt, placed the way `Door._dress` places it, lies inside its room in every map
## (bugs/the-lake-well-hatch-prompt-is-cut-by-the-top-of-the-frame).

const ROOMS_DIR := "res://scenes/world/rooms"
const DOOR := preload("res://scenes/world/interactables/door/door.tscn")
const ROOM_SCRIPT := preload("res://scenes/world/rooms/room.gd")


func _room_scenes(dir: String) -> PackedStringArray:
	var found := PackedStringArray()
	for sub: String in DirAccess.get_directories_at(dir):
		if sub != "contents":
			found.append_array(_room_scenes(dir.path_join(sub)))
	for file: String in DirAccess.get_files_at(dir):
		if file.ends_with(".tscn"):
			found.append(dir.path_join(file))
	return found

func test_every_door_prompt_lies_inside_its_room() -> void:
	var door := DOOR.instantiate() as Door
	var prompt_size := (door.get_node("Prompt") as Control).size
	door.free()
	var problems := PackedStringArray()
	var checked := 0
	for path: String in _room_scenes(ROOMS_DIR):
		var root := (load(path) as PackedScene).instantiate()
		if root.get_script() != ROOM_SCRIPT:
			root.free()
			continue
		var room := root as Room
		var shape_node := room.get_node("CollisionShape2D") as CollisionShape2D
		var size := (shape_node.shape as RectangleShape2D).size
		var bounds := Rect2(shape_node.position - size * 0.5, size)
		var contents := room.contents_scene.instantiate()
		var map_node := contents.get_node_or_null("RoomMap")
		if map_node != null:
			var map: RoomMap = map_node.map
			var at := (map_node as Node2D).position + (contents as Node2D).position
			for placed: Dictionary in map.entities:
				if placed.symbol != "E":
					continue
				var cell: Vector2i = placed.cell
				var feet := at + Vector2((cell.x + 0.5) * RoomMap.CELL_PX, (cell.y + 1) * RoomMap.CELL_PX)
				var look: String = (placed.params as Dictionary).get("look", "door")
				var rect := Rect2(feet + Door.prompt_position(look, prompt_size, feet, bounds), prompt_size)
				checked += 1
				if not bounds.encloses(rect):
					problems.append("%s: door at %s (%s) prompt %s leaves %s" % [room.id(), cell, look, rect, bounds])
		contents.free()
		room.free()
	assert_int(checked).is_greater(20)
	assert_array(problems).is_empty()
