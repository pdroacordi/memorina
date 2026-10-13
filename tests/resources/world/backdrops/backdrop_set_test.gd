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

## A repeating layer's wrap differs from its neighbour no more than the art's own column steps do: a straight cut
## at the wrap shows every repeat (bugs/the-village-valley-hills-show-a-vertical-cut-where-they-wrap).
func test_every_repeating_layer_wraps_without_a_cut() -> void:
	var problems := PackedStringArray()
	for backdrop: BackdropSet in _sets():
		for layer: BackdropLayer in backdrop.layers:
			if not layer.repeat_x:
				continue
			var image := layer.texture.get_image()
			var strip := layer.strip_size()
			for band: int in layer.band_count:
				var top := band * strip.y
				var steepest := 0
				# Every art-pixel boundary (odd to even columns, so a 2x sheet compares across art pixels).
				for x: int in range(1, strip.x - 2, 2):
					steepest = maxi(steepest, _differing_rows(image, x, x + 1, top, strip.y))
				var wrap := _differing_rows(image, strip.x - 1, 0, top, strip.y)
				if wrap > steepest:
					problems.append("%s band %d: %d rows change at the wrap, at most %d inside" % [layer.texture.resource_path, band, wrap, steepest])
	assert_array(Array(problems)).is_empty()

func test_no_room_places_its_own_parallax_layers() -> void:
	var offenders := PackedStringArray()
	for path: String in _contents_scenes(ROOMS_DIR):
		if FileAccess.get_file_as_string(path).contains("type=\"Parallax2D\""):
			offenders.append(path)
	assert_array(Array(offenders)).is_empty()

func _differing_rows(image: Image, a: int, b: int, top: int, rows: int) -> int:
	var count := 0
	for y: int in range(top, top + rows):
		if image.get_pixel(a, y) != image.get_pixel(b, y):
			count += 1
	return count

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

## A band pixel handed to a room must hit art: every set's first layer is opaque wherever it can draw
## (architecture/backdrop-seams).
func test_every_sets_first_layer_is_opaque_everywhere() -> void:
	for backdrop: BackdropSet in _sets():
		var layer := backdrop.layers[0]
		assert_bool(layer.repeat_x).override_failure_message("%s: layer 0 must repeat across" % backdrop.resource_path).is_true()
		assert_bool(layer.fill_above != BackdropLayer.Fill.NONE and layer.fill_below != BackdropLayer.Fill.NONE) \
			.override_failure_message("%s: layer 0 must fill above and below" % backdrop.resource_path).is_true()
		var image := layer.texture.get_image()
		for y: int in image.get_height():
			for x: int in image.get_width():
				if image.get_pixel(x, y).a < 1.0:
					assert_bool(false).override_failure_message("%s: layer 0 has alpha at %d,%d" % [backdrop.resource_path, x, y]).is_true()
					return

## Every room has a backdrop: its own set, or its region's, so no seam hands the void to the clear colour.
func test_every_contents_scene_has_one_backdrop_with_a_set() -> void:
	var region_sets := _region_sets()
	var problems := PackedStringArray()
	for path: String in _contents(ROOMS_DIR):
		var root := (load(path) as PackedScene).instantiate()
		var count := 0
		for child: Node in root.get_children():
			if child is Backdrop:
				count += 1
				if (child as Backdrop).backdrop_set == null and region_sets.get(path) == null:
					problems.append("%s: its Backdrop has no set and its region none" % path)
		if count != 1:
			problems.append("%s: %d Backdrops" % [path, count])
		root.free()
	assert_array(Array(problems)).is_empty()

## A region's set repeats across on every layer, so its rooms draw the same pixels wherever they stand; a set with an
## edge on y stands on the region's horizon, which must be set.
func test_every_region_has_a_set_that_repeats_across() -> void:
	var problems := PackedStringArray()
	for path: String in _region_scenes():
		var region := (load(path) as PackedScene).instantiate() as Region
		var shown := region.backdrop_set
		if shown == null:
			problems.append("%s: no backdrop set" % path)
		else:
			var edge_y := false
			for layer: BackdropLayer in shown.layers:
				if not layer.repeat_x:
					problems.append("%s: %s has a layer that does not repeat across" % [path, shown.resource_path])
				edge_y = edge_y or not layer.repeats_y()
			if edge_y and region.horizon_y == 0.0:
				problems.append("%s: its set has a horizon and the region none" % path)
		region.free()
	assert_array(Array(problems)).is_empty()

## The pack forest is no room's backdrop ("the pack forest leaves everywhere", user, 2026-10-13).
func test_no_room_or_region_shows_the_pack_forest() -> void:
	var offenders := PackedStringArray()
	for path: String in _contents(ROOMS_DIR) + _region_scenes():
		if FileAccess.get_file_as_string(path).contains("backdrops/pine_woods.tres"):
			offenders.append(path)
	assert_array(Array(offenders)).is_empty()

# Contents scene path -> its region's set, for every room a region scene places.
func _region_sets() -> Dictionary:
	var sets := {}
	for path: String in _region_scenes():
		var region := (load(path) as PackedScene).instantiate() as Region
		for child: Node in region.get_children():
			if child is Room and (child as Room).contents_scene != null:
				sets[(child as Room).contents_scene.resource_path] = region.backdrop_set
		region.free()
	return sets

func _region_scenes() -> PackedStringArray:
	var found := PackedStringArray()
	for file: String in DirAccess.get_files_at(ROOMS_DIR):
		if file.get_extension() == "tscn" and FileAccess.get_file_as_string(ROOMS_DIR.path_join(file)).contains("rooms/region.gd"):
			found.append(ROOMS_DIR.path_join(file))
	return found

func _contents(dir: String) -> PackedStringArray:
	var found := PackedStringArray()
	for sub: String in DirAccess.get_directories_at(dir):
		found.append_array(_contents(dir.path_join(sub)))
	for file: String in DirAccess.get_files_at(dir):
		if file.ends_with("_contents.tscn"):
			found.append(dir.path_join(file))
	return found
