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
				if motion != null and sprite != null:
					for frame: int in motion.sequence:
						if frame < 0 or frame >= sprite.hframes:
							problems.append("%s: sequence frame %d is outside the %d frames" % [path, frame, sprite.hframes])
			root.free()
	assert_array(Array(problems)).is_empty()
