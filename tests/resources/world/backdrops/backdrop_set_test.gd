class_name BackdropSetTest extends GdUnitTestSuite

## Every backdrop set is sound, every EDGE fill continues one flat colour per band, and rooms draw their
## backgrounds only through a Backdrop (architecture/vertical-backdrops).

const SETS_DIR := "res://resources/world/backdrops"
const ROOMS_DIR := "res://scenes/world/rooms"
## The surface sets that share one sky and one horizon, so a seam between regions mixes sky with sky.
const SHARED_SKY_SETS: Array[String] = ["village_valley", "threshold", "frost_edge", "spring_woods", "frozen_lake", "wind_orchards", "summer_caldera"]
const SHARED_SKY := "res://assets/sprites/world/background/village_valley/sky.png"
## The GandalfHardcore pack's background folders (CREDITS.md); unused since WORLD-30.
const PACK_BACKGROUNDS: Array[String] = [
	"background/seasonal/", "background/spring/", "background/autumn/", "background/winter/", "backdrops/pine_woods.tres",
]
## Scripts that may still load the pack sheets: the local palette sampler (CREDITS.md).
const PACK_LOAD_EXEMPT: Array[String] = ["res://tools/art/extract_palette.gd"]
## Game px from a band's top within which a layer with nothing above may not run opaque, and the longest run allowed.
const FLAT_TOP_ROWS := 16
const FLAT_TOP_RUN := 32
## Layers that end in a straight top line, with the reason; the next layer of the set must cover that line
## (test_a_straight_topped_layer_is_covered_by_the_next).
const FLAT_TOP_ALLOWED := {
	"res://assets/sprites/world/background/basalt_caves/far.png": "caldera_crater: the basalt wall under the crater landscape, covered by the crater rim (WORLD-32)",
}


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

## "Our own per region (Recommended)" (user, 2026-10-13): one set per region on the shared sky and horizon.
func test_the_region_sets_share_the_sky_and_the_horizon() -> void:
	for id: String in SHARED_SKY_SETS:
		var backdrop := load(SETS_DIR.path_join(id + ".tres")) as BackdropSet
		assert_object(backdrop).override_failure_message("%s is missing" % id).is_not_null()
		assert_str(backdrop.layers[0].texture.resource_path).override_failure_message("%s: its sky" % id).is_equal(SHARED_SKY)
		assert_float(backdrop.horizon_screen_y).override_failure_message("%s: its eye level" % id).is_equal(191.0)
		# One sky scroll everywhere, 0 on y: the sky stands at eye level on any horizon (WORLD-33).
		assert_vector(backdrop.layers[0].scroll_scale).override_failure_message("%s: its sky scroll" % id).is_equal(Vector2(0.05, 0.0))
		for layer: BackdropLayer in backdrop.layers:
			assert_int(layer.horizon_row).override_failure_message("%s: a horizon row" % id).is_equal(229)

## A layer with nothing above it must close its shapes inside the strip: an opaque run along its top rows is drawn as
## a straight cut wherever the vertical parallax brings it on screen
## (bugs/the-spring-woods-near-trees-are-cut-flat-at-the-strip-top).
func test_no_layer_with_nothing_above_is_cut_flat_at_its_top() -> void:
	var problems := PackedStringArray()
	for backdrop: BackdropSet in _sets():
		for layer: BackdropLayer in backdrop.layers:
			var path := layer.texture.resource_path
			if layer.fill_above != BackdropLayer.Fill.NONE or FLAT_TOP_ALLOWED.has(path):
				continue
			var image := layer.texture.get_image()
			var strip := layer.strip_size()
			for band: int in layer.band_count:
				var run := _longest_opaque_run(image, band * strip.y, FLAT_TOP_ROWS)
				if run > FLAT_TOP_RUN:
					problems.append("%s band %d: %d opaque px in a row within the top %d rows" % [path, band, run, FLAT_TOP_ROWS])
	assert_array(Array(problems)).is_empty()

## The layer after a straight-topped one rides with it and continues it upward: same scroll and width, and from the
## row over the straight top down to its own bottom, which runs on over the wall, it is the wall's pixels, so neither
## the line nor a gap between the two quads shows (WORLD-32).
func test_a_straight_topped_layer_is_covered_by_the_next() -> void:
	var problems := PackedStringArray()
	for backdrop: BackdropSet in _sets():
		for i: int in backdrop.layers.size():
			var wall := backdrop.layers[i]
			if not FLAT_TOP_ALLOWED.has(wall.texture.resource_path) or wall.fill_above != BackdropLayer.Fill.NONE:
				continue
			var label := "%s layer %d" % [backdrop.resource_path, i]
			if i + 1 >= backdrop.layers.size():
				problems.append("%s: nothing covers its top" % label)
				continue
			var rim := backdrop.layers[i + 1]
			var rim_strip := rim.strip_size()
			var wall_strip := wall.strip_size()
			# Rim rows over the wall's top row.
			var above := rim.horizon_row - wall.horizon_row
			if rim.scroll_scale != wall.scroll_scale or rim.repeat_x != wall.repeat_x or rim_strip.x != wall_strip.x 					or rim.band_count != wall.band_count or rim.band_of_season != wall.band_of_season or rim.distance != wall.distance:
				problems.append("%s: the cover does not ride with it" % label)
			if above < 1 or rim_strip.y <= above or rim.fill_below != BackdropLayer.Fill.NONE:
				problems.append("%s: the cover does not run on over its top" % label)
				continue
			var rim_image := rim.texture.get_image()
			var wall_image := wall.texture.get_image()
			for row: int in range(above - 1, rim_strip.y):
				var wall_row := posmod(row - above, wall_strip.y)
				for x: int in rim_strip.x:
					if rim_image.get_pixel(x, row) != wall_image.get_pixel(x, wall_row):
						problems.append("%s: the cover breaks the wall's texture at x %d, row %d" % [label, x, row])
						break
	assert_array(Array(problems)).is_empty()

func test_no_room_places_its_own_parallax_layers() -> void:
	var offenders := PackedStringArray()
	for path: String in _contents_scenes(ROOMS_DIR):
		if FileAccess.get_file_as_string(path).contains("type=\"Parallax2D\""):
			offenders.append(path)
	assert_array(Array(offenders)).is_empty()

## The longest run of opaque pixels along any of `rows` rows from `top`, wrapping sideways.
func _longest_opaque_run(image: Image, top: int, rows: int) -> int:
	var width := image.get_width()
	var longest := 0
	for y: int in range(top, top + rows):
		var run := 0
		for i: int in width * 2:
			run = run + 1 if image.get_pixel(i % width, y).a > 0.0 else 0
			longest = maxi(longest, mini(run, width))
	return longest

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

## No scene draws the pack's backgrounds, the title included, and no set but the retired pine_woods holds them
## (WORLD-30: no pack art on screen; CREDITS.md).
func test_no_scene_or_other_set_draws_the_pack_backgrounds() -> void:
	var offenders := PackedStringArray()
	for path: String in _files_under("res://scenes", "tscn") + _files_under(SETS_DIR, "tres"):
		if path == SETS_DIR.path_join("pine_woods.tres"):
			continue
		var text := FileAccess.get_file_as_string(path)
		for folder: String in PACK_BACKGROUNDS:
			if text.contains(folder):
				offenders.append("%s: %s" % [path, folder])
	assert_array(Array(offenders)).is_empty()

## No script names a pack background sheet or the retired set; the palette sampler only reads them for colours.
func test_no_script_loads_the_pack_backgrounds() -> void:
	# Any string naming a pack sheet or the retired set, so a path held in a const and loaded later is caught too.
	var loads := RegEx.create_from_string("\"res://(assets/sprites/world/background/(seasonal|spring|autumn|winter)/[^\"]*|resources/world/backdrops/pine_woods\\.tres)\"")
	var offenders := PackedStringArray()
	for dir: String in ["res://scenes", "res://globals", "res://resources", "res://tools", "res://tests"]:
		for path: String in _files_under(dir, "gd"):
			if path in PACK_LOAD_EXEMPT:
				continue
			if loads.search(FileAccess.get_file_as_string(path)) != null:
				offenders.append(path)
	assert_array(Array(offenders)).is_empty()

func _files_under(dir: String, extension: String) -> PackedStringArray:
	var found := PackedStringArray()
	for sub: String in DirAccess.get_directories_at(dir):
		found.append_array(_files_under(dir.path_join(sub), extension))
	for file: String in DirAccess.get_files_at(dir):
		if file.get_extension() == extension:
			found.append(dir.path_join(file))
	return found

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
