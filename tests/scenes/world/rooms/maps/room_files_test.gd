class_name RoomFilesTest extends GdUnitTestSuite

## Validates every `.room` file against the current legend read from disk.

const ROOMS_DIR := "res://scenes/world/rooms"
const TRANSLATIONS := "res://i18n/translations.csv"

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

## Save ids must be unique across maps so saved entities identify one location.
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

## The title names a slot's bench by `SaveSlots.bench_name_key`, so every bench needs that key in both languages.
func test_every_bench_has_a_name_in_the_translations() -> void:
	var legend := RoomLegend.load_default()
	var keys := _translation_keys()
	var problems := PackedStringArray()
	for path: String in _room_files(ROOMS_DIR):
		var result := RoomMapParser.parse(FileAccess.get_file_as_string(path), legend, path)
		for placed: Dictionary in result.map.entities:
			if not placed.params.has("bench_id"):
				continue
			var key := SaveSlots.bench_name_key(StringName(placed.params["bench_id"]))
			if not keys.has(key):
				problems.append("%s (%s) has no translated name" % [key, path])
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

## Keys whose every language column is filled, read from the source CSV.
func _translation_keys() -> Dictionary[String, bool]:
	var keys: Dictionary[String, bool] = {}
	var file := FileAccess.open(TRANSLATIONS, FileAccess.READ)
	var header := file.get_csv_line()
	while not file.eof_reached():
		var row := file.get_csv_line()
		if row.size() == header.size() and not row.has(""):
			keys[row[0]] = true
	return keys
