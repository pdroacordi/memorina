class_name RoomVoidTest extends GdUnitTestSuite

## Void outside a room's shell (architecture/room-void-outside-the-shell): the placement rule, solid stone with no look,
## the section cut in the tiles, the black mask over exactly the void cells, and the audit blocking on it.

const SHELL := "....\n.SS.\n.SS."


func _parse(grid: String, extra: String = "") -> RoomMapParser.Result:
	return RoomMapParser.parse("[room]\norigin = 0, 0\ntileset = legacy\n\n[grid]\n%s\n%s" % [grid, extra], RoomLegend.load_default(), "void.room")

func _ok(grid: String) -> RoomMap:
	var result := _parse(grid)
	assert_array(Array(result.errors)).is_empty()
	return result.map

func test_a_void_cell_is_solid_stone_with_no_look() -> void:
	var map := _ok("SSSS\nS__S\nSSSS")
	assert_bool(map.is_void(Vector2i(1, 1))).is_true()
	assert_int(map.ground_at(Vector2i(1, 1))).is_equal(Enums.Ground.STONE)
	assert_bool(map.is_solid(Vector2i(1, 1))).is_true()
	assert_int(map.looks[1 * 4 + 1]).is_equal(RoomMap.NO_LOOK)

func test_void_beside_air_is_refused_on_any_of_its_eight_sides() -> void:
	assert_str("\n".join(_parse("S_S\nS.S\nSSS").errors)).contains("touches air")
	assert_str("\n".join(_parse("_SS\nS.S\nSSS").errors)).contains("touches air")

func test_void_beside_a_ledge_is_refused() -> void:
	assert_str("\n".join(_parse("SSSS\n_=SS\nSSSS").errors)).contains("touches a ledge")

func test_void_under_water_is_refused() -> void:
	var result := _parse("SSS\nS_S\nSSS", "\n[water]\n...\n.~.\n...\n")
	assert_str("\n".join(result.errors)).contains("under water")

func test_void_off_the_map_edge_is_fine() -> void:
	assert_array(Array(_parse("__\n__").errors)).is_empty()

func test_a_void_cell_takes_its_walls_look_and_a_tile_of_four_void_corners_is_cleared() -> void:
	var map := _ok("SSSS\nS..S\nSSSS\n____\n____")
	var looks := RoomTileResolver.void_filled(map)
	assert_int(looks[3 * 4 + 1]).is_equal(BiomeTileset.Look.STONE)
	var layer: PackedByteArray = map.ground_layers[BiomeTileset.Look.STONE]
	var display := map.display_size()
	# Display (2, 4) sits on four void corners: empty. Display (2, 3) has two wall corners and two void corners: full.
	assert_int(layer[4 * display.x + 2] & 0xf).is_equal(0)
	assert_int(layer[3 * display.x + 2] & 0xf).is_equal(GroundAutotile.FULL)

func test_the_mask_covers_exactly_the_void_cells_in_merged_runs() -> void:
	var map := _ok("SSSS\nS..S\nSSSS\n____\n____")
	var runs := RoomVoid.runs(map)
	assert_int(runs.size()).is_equal(1)
	assert_that(runs[0]).is_equal(Rect2i(0, 3, 4, 2))
	var room := RoomMapNode.new()
	room.map = map
	add_child(room)
	auto_free(room)
	var mask := room.get_node("Void") as RoomVoid
	assert_int(mask.z_index).is_equal(RoomVoid.Z)
	assert_that(mask.rects).is_equal([Rect2(0, 96, 128, 64)] as Array[Rect2])

func test_a_room_without_void_has_no_mask() -> void:
	var room := RoomMapNode.new()
	room.map = _ok("....\nSSSS")
	add_child(room)
	auto_free(room)
	assert_object(room.get_node_or_null("Void")).is_null()

func test_the_reach_grid_blocks_on_void() -> void:
	var grid := ReachGrid.new()
	grid.add_room(&"void", _ok("SSSS\nS..S\nSSSS\n____"), Vector2i.ZERO)
	assert_int(grid.flags(Vector2i(1, 3)) & ReachGrid.SOLID).is_equal(ReachGrid.SOLID)
