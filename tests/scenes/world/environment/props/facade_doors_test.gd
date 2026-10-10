class_name FacadeDoorsTest extends GdUnitTestSuite

## A facade stands on a door, and every door on a village street stands in a facade (systems/props, Facades).

const ROOMS_DIR := "res://scenes/world/rooms"
const STREET_BACKDROP := "res://resources/world/backdrops/village_valley.tres"


func _contents_scenes(dir: String) -> PackedStringArray:
	var found := PackedStringArray()
	for sub: String in DirAccess.get_directories_at(dir):
		found.append_array(_contents_scenes(dir.path_join(sub)))
	for file: String in DirAccess.get_files_at(dir):
		if file.ends_with("_contents.tscn"):
			found.append(dir.path_join(file))
	return found

# Door feet in the contents' space: the bottom centre of each `E` cell (a cell already counts the room's origin).
func _doors(contents: Node) -> Array[Vector2]:
	var doors: Array[Vector2] = []
	var map: RoomMap = contents.get_node("RoomMap").map
	for placed: Dictionary in map.entities:
		if placed.symbol == "E":
			var cell: Vector2i = placed.cell
			doors.append(Vector2((cell.x + 0.5) * RoomMap.CELL_PX, (cell.y + 1) * RoomMap.CELL_PX))
	return doors

func _facades(contents: Node) -> Array[Vector2]:
	var facades: Array[Vector2] = []
	var props := contents.get_node_or_null("Props")
	if props != null:
		for prop: Node in props.get_children():
			if prop.scene_file_path.ends_with("_facade.tscn"):
				facades.append((prop as Node2D).position)
	return facades

func test_every_facade_stands_on_a_door() -> void:
	var problems := PackedStringArray()
	for path: String in _contents_scenes(ROOMS_DIR):
		var contents := (load(path) as PackedScene).instantiate()
		var doors := _doors(contents)
		for facade: Vector2 in _facades(contents):
			if not facade in doors:
				problems.append("%s: a facade at %s has no door" % [path, facade])
		contents.free()
	assert_array(Array(problems)).is_empty()

## A street door never stands alone: its building's front surrounds it (systems/props, Facades).
func test_every_street_door_stands_in_a_facade() -> void:
	var problems := PackedStringArray()
	var streets := 0
	for path: String in _contents_scenes(ROOMS_DIR):
		var contents := (load(path) as PackedScene).instantiate()
		var backdrop := contents.get_node_or_null("Backdrop")
		if backdrop != null and backdrop.backdrop_set != null and backdrop.backdrop_set.resource_path == STREET_BACKDROP:
			streets += 1
			var facades := _facades(contents)
			for door: Vector2 in _doors(contents):
				if not door in facades:
					problems.append("%s: the door at %s stands in no facade" % [path, door])
		contents.free()
	assert_int(streets).is_greater(0)
	assert_array(Array(problems)).is_empty()
