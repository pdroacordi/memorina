class_name RoomTileResolverTest extends GdUnitTestSuite

## Dual-grid display masks around cells, past the map's edges, under ledges and for back walls.


func _map(text: String) -> RoomMap:
	var result := RoomMapParser.parse("[room]\ntileset = legacy\n" + text, RoomLegend.load_default())
	assert(result.ok(), str(result.errors))
	return result.map

func _mask(map: RoomMap, layers: Dictionary, look: int, i: int, j: int) -> int:
	var layer: PackedByteArray = layers[look]
	return layer[j * map.display_size().x + i] & 0xf

func test_the_display_grid_is_one_larger_each_way() -> void:
	var map := _map("[grid]\n...\n...\n")
	assert_vector(map.display_size()).is_equal(Vector2i(4, 3))

## A lone earth cell in the air is four quarter tiles: a rounded boulder.
func test_a_lone_cell_makes_the_four_corner_masks() -> void:
	var map := _map("[grid]\n...\n.#.\n...\n")
	var earth := BiomeTileset.Look.EARTH
	assert_int(_mask(map, map.ground_layers, earth, 1, 1)).is_equal(GroundAutotile.SE)
	assert_int(_mask(map, map.ground_layers, earth, 2, 1)).is_equal(GroundAutotile.SW)
	assert_int(_mask(map, map.ground_layers, earth, 1, 2)).is_equal(GroundAutotile.NE)
	assert_int(_mask(map, map.ground_layers, earth, 2, 2)).is_equal(GroundAutotile.NW)

func test_the_floor_continues_past_the_sides_and_bottom_but_not_the_top() -> void:
	var map := _map("[grid]\n...\n###\n")
	var earth := BiomeTileset.Look.EARTH
	# Left of the map the edge cell continues: the top there is still an exposed top, not a corner.
	assert_int(_mask(map, map.ground_layers, earth, 0, 1)).is_equal(GroundAutotile.SW | GroundAutotile.SE)
	assert_int(_mask(map, map.ground_layers, earth, 1, 2)).is_equal(GroundAutotile.FULL)
	assert_int(_mask(map, map.ground_layers, earth, 1, 0)).is_equal(0)

func test_a_stone_row_on_earth_fills_the_earth_under_it() -> void:
	var map := _map("[grid]\nSSS\n###\n")
	var earth := BiomeTileset.Look.EARTH
	var stone := BiomeTileset.Look.STONE
	assert_int(_mask(map, map.ground_layers, earth, 1, 1)).is_equal(GroundAutotile.FULL)
	assert_int(_mask(map, map.ground_layers, stone, 1, 1)).is_equal(GroundAutotile.NW | GroundAutotile.NE)

func test_a_ledge_is_air_to_the_ground_and_draws_its_pieces() -> void:
	var map := _map("[grid]\n===\n...\n")
	assert_bool(map.ground_layers.is_empty()).is_true()
	var ledges: PackedByteArray = map.ledge_layers[BiomeTileset.Look.EARTH]
	assert_int(ledges[0]).is_equal(GroundAutotile.LEDGE_LEFT + 1)
	assert_int(ledges[1]).is_equal(GroundAutotile.LEDGE_MIDDLE + 1)
	assert_int(ledges[2]).is_equal(GroundAutotile.LEDGE_RIGHT + 1)

func test_back_walls_fill_only_the_back_layers() -> void:
	var map := _map("[grid]\n...\n###\n[back]\nhhh\n...\n")
	assert_bool(map.back_layers.has(BiomeTileset.Look.WALL)).is_true()
	assert_bool(map.ground_layers.has(BiomeTileset.Look.WALL)).is_false()
	assert_int(_mask(map, map.back_layers, BiomeTileset.Look.WALL, 1, 1)).is_equal(GroundAutotile.NW | GroundAutotile.NE)

func test_a_full_tile_may_carry_a_fill_variant_and_others_never_do() -> void:
	var map := _map("[grid]\n" + "########\n".repeat(8))
	var layer: PackedByteArray = map.ground_layers[BiomeTileset.Look.EARTH]
	var varied := false
	for packed: int in layer:
		if packed & 0xf != GroundAutotile.FULL:
			assert_int(packed >> 4).is_equal(0)
		elif packed >> 4 > 0:
			varied = true
	assert_bool(varied).is_true()
