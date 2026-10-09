class_name BackdropSetTest extends GdUnitTestSuite

## Every backdrop set is sound, every EDGE fill continues one flat colour per band, and rooms draw their
## backgrounds only through a Backdrop (architecture/vertical-backdrops).

const SETS_DIR := "res://resources/world/backdrops"
const ROOMS_DIR := "res://scenes/world/rooms"


func _sets() -> Array[BackdropSet]:
	var found: Array[BackdropSet] = []
	for file: String in DirAccess.get_files_at(SETS_DIR):
		if file.get_extension() == "tres":
			var resource := load(SETS_DIR.path_join(file)) as BackdropSet
			if resource != null:
				found.append(resource)
	return found

func test_there_are_sets_to_check() -> void:
	assert_int(_sets().size()).is_greater(0)

func test_every_set_has_no_problems() -> void:
	var problems := PackedStringArray()
	for backdrop: BackdropSet in _sets():
		for problem: String in backdrop.problems():
			problems.append("%s: %s" % [backdrop.resource_path, problem])
	assert_array(Array(problems)).is_empty()

## An EDGE side repeats its edge row forever: a row of two colours would draw vertical stripes.
func test_every_edge_row_is_one_colour_per_band() -> void:
	var problems := PackedStringArray()
	for backdrop: BackdropSet in _sets():
		for layer: BackdropLayer in backdrop.layers:
			var image := layer.texture.get_image()
			var strip := layer.strip_size()
			for band: int in layer.band_count:
				if layer.fill_above == BackdropLayer.Fill.EDGE and not _flat(image, band * strip.y):
					problems.append("%s band %d: top row is not one colour" % [layer.texture.resource_path, band])
				if layer.fill_below == BackdropLayer.Fill.EDGE and not _flat(image, band * strip.y + strip.y - 1):
					problems.append("%s band %d: bottom row is not one colour" % [layer.texture.resource_path, band])
	assert_array(Array(problems)).is_empty()

func test_no_room_places_its_own_parallax_layers() -> void:
	var offenders := PackedStringArray()
	for path: String in _contents_scenes(ROOMS_DIR):
		if FileAccess.get_file_as_string(path).contains("type=\"Parallax2D\""):
			offenders.append(path)
	assert_array(Array(offenders)).is_empty()

func _flat(image: Image, row: int) -> bool:
	var first := image.get_pixel(0, row)
	for x: int in image.get_width():
		if image.get_pixel(x, row) != first:
			return false
	return true

func _contents_scenes(dir: String) -> PackedStringArray:
	var found := PackedStringArray()
	for sub: String in DirAccess.get_directories_at(dir):
		found.append_array(_contents_scenes(dir.path_join(sub)))
	for file: String in DirAccess.get_files_at(dir):
		if file.ends_with("_contents.tscn"):
			found.append(dir.path_join(file))
	return found
