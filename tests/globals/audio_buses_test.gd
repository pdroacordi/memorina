class_name AudioBusesTest extends GdUnitTestSuite

## Every bus named in AudioBuses exists in the layout, and every AudioStreamPlayer in a scene sends to one of them.

const SCENES := "res://scenes"


func _scenes(dir: String) -> PackedStringArray:
	var found := PackedStringArray()
	for sub: String in DirAccess.get_directories_at(dir):
		found.append_array(_scenes(dir.path_join(sub)))
	for file: String in DirAccess.get_files_at(dir):
		if file.ends_with(".tscn"):
			found.append(dir.path_join(file))
	return found

func _players(node: Node) -> Array[AudioStreamPlayer]:
	var found: Array[AudioStreamPlayer] = []
	if node is AudioStreamPlayer:
		found.append(node as AudioStreamPlayer)
	for child: Node in node.get_children():
		found.append_array(_players(child))
	return found

func test_every_named_bus_is_in_the_layout() -> void:
	var layout := load("res://default_bus_layout.tres") as AudioBusLayout
	assert_object(layout).is_not_null()
	for bus: StringName in [AudioBuses.MUSIC, AudioBuses.NOTES, AudioBuses.SFX]:
		assert_int(AudioServer.get_bus_index(bus)).override_failure_message(String(bus)).is_greater(0)

func test_every_scene_player_sends_to_a_named_bus() -> void:
	var problems := PackedStringArray()
	var checked := 0
	for path: String in _scenes(SCENES):
		var text := FileAccess.get_file_as_string(path)
		if not text.contains("AudioStreamPlayer"):
			continue
		var root := (load(path) as PackedScene).instantiate()
		for player: AudioStreamPlayer in _players(root):
			checked += 1
			# Master only for the Settings screen's preview of its own volume.
			if not [AudioBuses.MASTER, AudioBuses.MUSIC, AudioBuses.NOTES, AudioBuses.SFX].has(player.bus):
				problems.append("%s: %s on bus '%s'" % [path.get_file(), root.get_path_to(player), player.bus])
		root.free()
	assert_array(Array(problems)).is_empty()
	assert_int(checked).is_greater_equal(16)
