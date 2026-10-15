class_name PropScenesTest extends GdUnitTestSuite

## Every prop and inhabitant scene is a plain sprite: never collides, never joins a pass, and plays only its own
## frames (systems/props).

const DIRS: Array[String] = ["res://scenes/world/environment/props", "res://scenes/world/environment/inhabitants"]


func _scenes(dir: String) -> PackedStringArray:
	var found := PackedStringArray()
	for sub: String in DirAccess.get_directories_at(dir):
		found.append_array(_scenes(dir.path_join(sub)))
	for file: String in DirAccess.get_files_at(dir):
		if file.get_extension() == "tscn":
			found.append(dir.path_join(file))
	return found

func _all(node: Node) -> Array[Node]:
	var nodes: Array[Node] = [node]
	for child: Node in node.get_children():
		nodes.append_array(_all(child))
	return nodes

func test_there_are_prop_scenes() -> void:
	var count := 0
	for dir: String in DIRS:
		count += _scenes(dir).size()
	assert_int(count).is_greater(0)

func test_every_prop_is_a_still_sprite_that_never_collides() -> void:
	var problems := PackedStringArray()
	for dir: String in DIRS:
		for path: String in _scenes(dir):
			var root := (load(path) as PackedScene).instantiate()
			var sprite := root as Sprite2D
			if sprite == null:
				problems.append("%s: the root is not a Sprite2D" % path)
			elif sprite.visibility_layer != 1:
				problems.append("%s: visibility_layer is %d, not the root canvas" % [path, sprite.visibility_layer])
			for node: Node in _all(root):
				if node is CollisionObject2D:
					problems.append("%s: %s collides" % [path, node.name])
				var motion := node as AmbientMotion
				# A motion drives its own parent: a front's composed lights and smoke have frames of their own.
				var driven: Sprite2D = node.get_parent() as Sprite2D if motion != null else null
				if driven != null:
					for frame: int in motion.sequence:
						if frame < 0 or frame >= driven.hframes:
							problems.append("%s: sequence frame %d is outside the %d frames" % [path, frame, driven.hframes])
			root.free()
	assert_array(Array(problems)).is_empty()

## Every room contents' `Props` node draws at z -10, behind the ground and the entities (systems/props, Placement;
## bugs/the-farmhouse-props-node-has-no-z-index). Read from the scene file: a missing z_index line is 0.
func test_every_rooms_props_node_draws_at_minus_ten() -> void:
	var checked := 0
	var problems := PackedStringArray()
	for path: String in _scenes("res://scenes/world/rooms"):
		if not path.ends_with("_contents.tscn"):
			continue
		var state := (load(path) as PackedScene).get_state()
		for node: int in state.get_node_count():
			if state.get_node_name(node) != &"Props":
				continue
			checked += 1
			var z := 0
			for i: int in state.get_node_property_count(node):
				if state.get_node_property_name(node, i) == &"z_index":
					z = int(state.get_node_property_value(node, i))
			if z != -10:
				problems.append("%s: Props is at z %d" % [path, z])
	assert_int(checked).is_greater(0)
	assert_array(Array(problems)).is_empty()
