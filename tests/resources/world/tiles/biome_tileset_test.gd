class_name BiomeTilesetTest extends GdUnitTestSuite

## Every biome resource is named by its file, sound, and builds a defined tile per slot of each present look.

## Art px every fill variant must differ from the plain fill and from each other by (the village soil's pebble is 3).
const MIN_DISTINCT_ART_PX := 3


func _biomes() -> Array[BiomeTileset]:
	var found: Array[BiomeTileset] = []
	for file: String in DirAccess.get_files_at(BiomeTileset.DIRECTORY):
		if file.ends_with(".tres"):
			found.append(load(BiomeTileset.DIRECTORY + file) as BiomeTileset)
	return found

func test_there_is_at_least_the_legacy_biome() -> void:
	assert_object(BiomeTileset.find("legacy")).is_not_null()

## "No earth there" (user, 2026-10-08): roots must find nothing to join in these biomes; the ash scree is stone.
func test_the_biomes_without_earth_draw_none() -> void:
	for id: String in ["frost_edge", "lighthouse", "summer_caldera", "summer_caldera_ash"]:
		var biome := BiomeTileset.find(id)
		assert_object(biome).override_failure_message("%s is missing" % id).is_not_null()
		assert_bool(biome.has_look(BiomeTileset.Look.EARTH)).override_failure_message("%s draws earth" % id).is_false()

func test_an_unknown_id_is_null() -> void:
	assert_object(BiomeTileset.find("no_such_biome")).is_null()

func test_every_biome_is_sound_and_named_by_its_file() -> void:
	for biome: BiomeTileset in _biomes():
		assert_array(Array(biome.problems())).is_empty()
		assert_object(BiomeTileset.find(biome.id())).is_same(biome)

## A declared variant missing from a sheet would draw a hole in the street's top 4 cells in 5.
func test_every_declared_variant_is_drawn_in_every_band() -> void:
	for biome: BiomeTileset in _biomes():
		for look: int in BiomeTileset.Look.values():
			if not biome.has_look(look) or biome.variants(look) == 0:
				continue
			var image := biome.sheet(look).get_image()
			var tile := image.get_width() / BiomeTileset.COLUMNS
			for band: int in 3:
				for variant: int in range(1, biome.variants(look) + 1):
					for mask: int in [GroundAutotile.FULL] + GroundAutotile.EDGE_MASKS:
						var at := GroundAutotile.varied_coords(mask, variant) + Vector2i(0, band * GroundAutotile.BAND_ROWS)
						var empty := image.get_region(Rect2i(at * tile, Vector2i(tile, tile))).is_invisible()
						assert_bool(empty).override_failure_message("%s %d: variant %d of mask %d is empty in band %d" % [biome.id(), look, variant, mask, band]).is_false()

## A fill variant that is almost the plain fill or another variant draws the same cell twice
## (bugs/painted-tile-variants-repeat-because-fixed-position-details-ignore-their-seed).
func test_every_fill_variant_is_distinct() -> void:
	var problems := PackedStringArray()
	for biome: BiomeTileset in _biomes():
		for look: int in BiomeTileset.Look.values():
			if not biome.has_look(look) or biome.variants(look) == 0:
				continue
			var image := biome.sheet(look).get_image()
			var tile := image.get_width() / BiomeTileset.COLUMNS
			var fills: Array[Vector2i] = [GroundAutotile.wang_coords(GroundAutotile.FULL)]
			for variant: int in range(1, biome.variants(look) + 1):
				fills.append(GroundAutotile.varied_coords(GroundAutotile.FULL, variant))
			for i: int in fills.size():
				for j: int in range(i + 1, fills.size()):
					var differ := _differing_art_px(image, fills[i] * tile, fills[j] * tile, tile)
					if differ < MIN_DISTINCT_ART_PX:
						problems.append("%s %s: fills %d and %d differ by %d art px" % [biome.id(), BiomeTileset.Look.keys()[look], i, j, differ])
	assert_array(Array(problems)).is_empty()

## Art px (2x2 game px, sampled at even coordinates) that differ between two tiles of `size` game px.
func _differing_art_px(image: Image, a: Vector2i, b: Vector2i, size: int) -> int:
	var count := 0
	for y: int in range(0, size, 2):
		for x: int in range(0, size, 2):
			if image.get_pixel(a.x + x, a.y + y) != image.get_pixel(b.x + x, b.y + y):
				count += 1
	return count

func test_the_tile_set_defines_every_slot_of_each_present_look() -> void:
	for biome: BiomeTileset in _biomes():
		var tile_set := biome.tile_set()
		for look: int in BiomeTileset.Look.values():
			if not biome.has_look(look):
				assert_bool(tile_set.has_source(look)).is_false()
				continue
			var source := tile_set.get_source(look) as TileSetAtlasSource
			assert_int(source.get_tiles_count()).is_equal(BiomeTileset.COLUMNS * BiomeTileset.ROWS)

func test_a_crack_sheet_defines_every_variant_of_every_band() -> void:
	for biome: BiomeTileset in _biomes():
		if biome.crack == null:
			continue
		var source := biome.tile_set().get_source(BiomeTileset.CRACK_SOURCE) as TileSetAtlasSource
		assert_int(source.get_tiles_count()).is_equal(BiomeTileset.CRACK_VARIANTS * 3)
