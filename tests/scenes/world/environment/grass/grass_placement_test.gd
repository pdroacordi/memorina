class_name GrassPlacementTest extends GdUnitTestSuite

## Grass grows on every exposed top of a look that has it, never under water, a secret or another cell (architecture/generated-grass).

const EARTH := BiomeTileset.Look.EARTH


func _map(text: String) -> RoomMap:
	var result := RoomMapParser.parse("[room]\ntileset = legacy\n" + text, RoomLegend.load_default())
	assert(result.ok(), str(result.errors))
	return result.map

func _earth_only(look: int) -> bool:
	return look == EARTH

func test_an_exposed_top_makes_a_run_with_its_ends() -> void:
	var runs := GrassPlacement.runs(_map("[grid]\n......\n.####.\n######\n"), _earth_only)
	# The raised top, and the two bottom cells left open beside it.
	assert_int(runs.size()).is_equal(3)
	assert_int(runs[0].row).is_equal(1)
	assert_int(runs[0].first).is_equal(1)
	assert_int(runs[0].last).is_equal(4)
	assert_bool(runs[0].open_left and runs[0].open_right).is_true()

## A covered top, another look and the map's top row (its blades would stand above the room) grow none.
func test_a_covered_top_another_look_and_the_top_row_grow_none() -> void:
	var runs := GrassPlacement.runs(_map("[grid]\n####\n####\n....\nSSSS\n"), _earth_only)
	assert_int(runs.size()).is_equal(0)

func test_the_map_edge_closes_a_run() -> void:
	var runs := GrassPlacement.runs(_map("[grid]\n....\n####\n"), _earth_only)
	assert_bool(runs[0].open_left or runs[0].open_right).is_false()

func test_a_top_under_water_grows_none() -> void:
	var runs := GrassPlacement.runs(_map("[grid]\n#..#\n#..#\n####\n[water]\n....\n.~~.\n....\n"), _earth_only)
	assert_int(runs.size()).is_equal(0)

func test_a_top_under_a_secret_grows_none() -> void:
	var runs := GrassPlacement.runs(_map("[grid]\n....\n....\n####\n[secret]\n....\n.S..\n....\n"), _earth_only)
	assert_int(runs.size()).is_equal(2)
	assert_bool(runs[0].open_right).is_false()

## The shader's loop bound and GrassLook's are one constant written twice.
func test_the_blade_bound_is_the_same_in_the_shader() -> void:
	var source := FileAccess.get_file_as_string("res://scenes/world/environment/grass/grass_blades.gdshader")
	assert_bool(source.contains("const int MAX_BLADE_ART = %d;" % GrassLook.MAX_BLADE_ART)).is_true()
