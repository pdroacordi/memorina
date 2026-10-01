class_name RoomFilesTest extends GdUnitTestSuite

## Every `.room` in the project parses and validates against the CURRENT
## legend, read fresh from disk - so a legend change that breaks a map fails
## here even though the editor has not reimported that map yet.

const ROOMS_DIR := "res://scenes/world/rooms"

func _room_files(dir: String) -> PackedStringArray:
	var found := PackedStringArray()
	for sub: String in DirAccess.get_directories_at(dir):
		found.append_array(_room_files(dir.path_join(sub)))
	for file: String in DirAccess.get_files_at(dir):
		if file.get_extension() == "room":
			found.append(dir.path_join(file))
	return found

func test_there_are_room_files_to_check() -> void:
	assert_int(_room_files(ROOMS_DIR).size()).is_greater(0)

func test_every_room_file_is_valid() -> void:
	var legend := RoomLegend.load_default()
	var problems := PackedStringArray()
	for path: String in _room_files(ROOMS_DIR):
		var result := RoomMapValidator.validate(FileAccess.get_file_as_string(path), legend, path)
		problems.append_array(result.errors)
	assert_array(Array(problems)).is_empty()

## The save remembers a bench and a defeated creature by an authored id, so
## an id two maps share is two places the save cannot tell apart.
func test_save_ids_and_bench_ids_are_unique_across_every_map() -> void:
	var legend := RoomLegend.load_default()
	var seen := {}
	var problems := PackedStringArray()
	for path: String in _room_files(ROOMS_DIR):
		var result := RoomMapParser.parse(FileAccess.get_file_as_string(path), legend, path)
		for placed: Dictionary in result.map.entities:
			for key: String in ["bench_id", "save_id"]:
				if not placed.params.has(key):
					continue
				var id := "%s=%s" % [key, placed.params[key]]
				if seen.has(id):
					problems.append("%s in %s and %s" % [id, seen[id], path])
				seen[id] = path
	assert_array(Array(problems)).is_empty()

func test_a_placement_missing_a_required_param_is_refused() -> void:
	var text := "[room]\norigin = 0, 0\n\n[grid]\n..R..\n#####\n"
	var result := RoomMapValidator.validate(text, RoomLegend.load_default(), "inline.room")
	assert_bool(result.ok()).is_false()
	assert_str("\n".join(result.errors)).contains("needs a 'bench_id' param")

func test_an_empty_required_param_is_refused() -> void:
	var text := "[room]\norigin = 0, 0\n\n[grid]\n..R..\n#####\n\n[entities]\n2,0 = {\"bench_id\": \"\"}\n"
	var result := RoomMapValidator.validate(text, RoomLegend.load_default(), "inline.room")
	assert_str("\n".join(result.errors)).contains("needs a 'bench_id' param")

func test_the_legend_is_sound() -> void:
	assert_array(Array(RoomLegend.load_default().problems())).is_empty()
