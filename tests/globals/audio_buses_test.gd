class_name AudioBusesTest extends GdUnitTestSuite

## Every bus named in AudioBuses exists in the layout, and every audio player in a scene sends to one of them.

const SCENES := "res://scenes"
# Master only for the Settings screen's preview of its own volume.
const ALLOWED: Array[StringName] = [
	AudioBuses.MASTER, AudioBuses.MUSIC, AudioBuses.NOTES, AudioBuses.SFX, AudioBuses.SFX_WORLD,
]


func _scenes(dir: String) -> PackedStringArray:
	var found := PackedStringArray()
	for sub: String in DirAccess.get_directories_at(dir):
		found.append_array(_scenes(dir.path_join(sub)))
	for file: String in DirAccess.get_files_at(dir):
		if file.ends_with(".tscn"):
			found.append(dir.path_join(file))
	return found

func _players(node: Node) -> Array[Node]:
	var found: Array[Node] = []
	if node is AudioStreamPlayer or node is AudioStreamPlayer2D:
		found.append(node)
	for child: Node in node.get_children():
		found.append_array(_players(child))
	return found

func test_every_named_bus_is_in_the_layout() -> void:
	var layout := load("res://default_bus_layout.tres") as AudioBusLayout
	assert_object(layout).is_not_null()
	for bus: StringName in [AudioBuses.MUSIC, AudioBuses.NOTES, AudioBuses.SFX, AudioBuses.SFX_WORLD]:
		assert_int(AudioServer.get_bus_index(bus)).override_failure_message(String(bus)).is_greater(0)

func test_sfx_world_sends_to_sfx_at_0_db_with_its_muffle_off() -> void:
	var index := AudioServer.get_bus_index(AudioBuses.SFX_WORLD)
	assert_str(String(AudioServer.get_bus_send(index))).is_equal(String(AudioBuses.SFX))
	assert_float(AudioServer.get_bus_volume_db(index)).is_equal(0.0)
	assert_int(AudioServer.get_bus_effect_count(index)).is_equal(1)
	var muffle := AudioServer.get_bus_effect(index, 0) as AudioEffectLowPassFilter
	assert_object(muffle).is_not_null()
	assert_str(muffle.resource_name).is_equal("Muffle")
	assert_float(muffle.cutoff_hz).is_equal(20000.0)
	assert_bool(AudioServer.is_bus_effect_enabled(index, 0)).is_false()

func test_every_scene_player_sends_to_a_named_bus() -> void:
	var problems := PackedStringArray()
	var checked := 0
	for path: String in _scenes(SCENES):
		var text := FileAccess.get_file_as_string(path)
		if not text.contains("AudioStreamPlayer"):
			continue
		var root := (load(path) as PackedScene).instantiate()
		for player: Node in _players(root):
			checked += 1
			var bus: StringName = player.get("bus")
			if not ALLOWED.has(bus):
				problems.append("%s: %s on bus '%s'" % [path.get_file(), root.get_path_to(player), bus])
		root.free()
	assert_array(Array(problems)).is_empty()
	assert_int(checked).is_greater_equal(16)
