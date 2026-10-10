class_name BiomeTilesetTest extends GdUnitTestSuite

## Every biome resource is named by its file, sound, and builds a defined tile per slot of each present look.


func _biomes() -> Array[BiomeTileset]:
	var found: Array[BiomeTileset] = []
	for file: String in DirAccess.get_files_at(BiomeTileset.DIRECTORY):
		if file.ends_with(".tres"):
			found.append(load(BiomeTileset.DIRECTORY + file) as BiomeTileset)
	return found

func test_there_is_at_least_the_legacy_biome() -> void:
	assert_object(BiomeTileset.find("legacy")).is_not_null()

func test_an_unknown_id_is_null() -> void:
	assert_object(BiomeTileset.find("no_such_biome")).is_null()

func test_every_biome_is_sound_and_named_by_its_file() -> void:
	for biome: BiomeTileset in _biomes():
		assert_array(Array(biome.problems())).is_empty()
		assert_object(BiomeTileset.find(biome.id())).is_same(biome)

func test_the_tile_set_defines_every_slot_of_each_present_look() -> void:
	for biome: BiomeTileset in _biomes():
		var tile_set := biome.tile_set()
		for look: int in BiomeTileset.Look.values():
			if not biome.has_look(look):
				assert_bool(tile_set.has_source(look)).is_false()
				continue
			var source := tile_set.get_source(look) as TileSetAtlasSource
			assert_int(source.get_tiles_count()).is_equal(BiomeTileset.COLUMNS * BiomeTileset.ROWS)
