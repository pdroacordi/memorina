class_name StepSurfacesTest extends GdUnitTestSuite

## A cell sounds as its biome's surface for its look; a look the biome leaves NONE, or no look, falls back to its
## ground; air is NONE.

const FROZEN_LAKE := preload("res://resources/world/tiles/biomes/frozen_lake.tres")
const VILLAGE := preload("res://resources/world/tiles/biomes/village.tres")


func test_frozen_lake_earth_is_snow() -> void:
	assert_int(StepSurfaces.of(BiomeTileset.Look.EARTH, Enums.Ground.EARTH, FROZEN_LAKE)).is_equal(Enums.Surface.SNOW)

func test_village_looks_sound_as_their_material() -> void:
	assert_int(StepSurfaces.of(BiomeTileset.Look.EARTH, Enums.Ground.EARTH, VILLAGE)).is_equal(Enums.Surface.EARTH)
	assert_int(StepSurfaces.of(BiomeTileset.Look.STONE, Enums.Ground.STONE, VILLAGE)).is_equal(Enums.Surface.STONE)
	assert_int(StepSurfaces.of(BiomeTileset.Look.WOOD, Enums.Ground.WOOD, VILLAGE)).is_equal(Enums.Surface.WOOD)

func test_a_lookless_cell_falls_back_to_its_ground() -> void:
	assert_int(StepSurfaces.of(RoomMap.NO_LOOK, Enums.Ground.WOOD, VILLAGE)).is_equal(Enums.Surface.WOOD)

func test_a_look_left_none_falls_back_to_its_ground() -> void:
	assert_int(StepSurfaces.of(BiomeTileset.Look.WALL, Enums.Ground.STONE, VILLAGE)).is_equal(Enums.Surface.STONE)

func test_no_biome_falls_back_to_the_ground() -> void:
	assert_int(StepSurfaces.of(BiomeTileset.Look.EARTH, Enums.Ground.EARTH, null)).is_equal(Enums.Surface.EARTH)

func test_air_is_none() -> void:
	assert_int(StepSurfaces.of(RoomMap.NO_LOOK, Enums.Ground.NONE, VILLAGE)).is_equal(Enums.Surface.NONE)
