class_name RoomMapParserTest extends GdUnitTestSuite

## Checks room parsing, tile resolution and source-positioned errors.

var _legend: RoomLegend

func before_test() -> void:
	_legend = RoomLegend.new()
	_legend.entries = [
		_entry("#", RoomLegendEntry.Kind.GROUND, Enums.Ground.EARTH),
		_entry("S", RoomLegendEntry.Kind.GROUND, Enums.Ground.STONE),
		_entry("=", RoomLegendEntry.Kind.PLATFORM, Enums.Ground.EARTH),
		_water("~"),
		_water("f"),
		_lake("w"),
		_reach("r"),
		_thing("B"),
	]

func _entry(symbol: String, kind: RoomLegendEntry.Kind, ground: Enums.Ground) -> RoomLegendEntry:
	var entry := RoomLegendEntry.new()
	entry.symbol = symbol
	entry.kind = kind
	entry.ground = ground
	return entry

func _water(symbol: String) -> RoomLegendEntry:
	var entry := _entry(symbol, RoomLegendEntry.Kind.WATER, Enums.Ground.NONE)
	entry.water_layer = PackedScene.new()
	return entry

func _lake(symbol: String) -> RoomLegendEntry:
	var entry := _water(symbol)
	entry.takes_reach = false
	return entry

func _reach(symbol: String) -> RoomLegendEntry:
	var entry := _water(symbol)
	entry.reach = true
	return entry

func _thing(symbol: String) -> RoomLegendEntry:
	var entry := _entry(symbol, RoomLegendEntry.Kind.ENTITY, Enums.Ground.NONE)
	entry.scene = PackedScene.new()
	return entry

func _parse(text: String) -> RoomMapParser.Result:
	return RoomMapParser.parse(text, _legend, "test.room")

func test_the_grid_sets_size_and_origin() -> void:
	var result := _parse("[room]\norigin = -2, 3\n[grid]\n....\n####\n")
	assert_bool(result.ok()).is_true()
	assert_vector(result.map.origin).is_equal(Vector2i(-2, 3))
	assert_vector(result.map.size).is_equal(Vector2i(4, 2))

func test_ground_keeps_its_material() -> void:
	var map := _parse("[grid]\n#S\n").map
	assert_int(map.ground_at(Vector2i(0, 0))).is_equal(Enums.Ground.EARTH)
	assert_int(map.ground_at(Vector2i(1, 0))).is_equal(Enums.Ground.STONE)
	assert_int(map.ground_at(Vector2i(5, 5))).is_equal(Enums.Ground.NONE)

func test_a_floor_under_open_sky_draws_its_grassy_top() -> void:
	var map := _parse("[grid]\n....\n####\n").map
	# Out-of-bounds cells count as solid, making this bottom row autotile as ground.
	assert_vector(RoomMap.tile_coords(map.tile_at(Vector2i(1, 1)))).is_equal(Vector2i(1, 0))

func test_stone_draws_from_the_stone_block() -> void:
	var map := _parse("[grid]\n....\nSSSS\n").map
	assert_vector(RoomMap.tile_coords(map.tile_at(Vector2i(1, 1)))).is_equal(Vector2i(10, 0))

func test_a_platform_is_one_way_and_not_solid() -> void:
	var map := _parse("[grid]\n.===.\n.....\n").map
	var cell := Vector2i(2, 0)
	assert_bool(map.is_platform(cell)).is_true()
	assert_bool(map.is_solid(cell)).is_false()
	assert_int(RoomMap.tile_alternative(map.tile_at(cell))).is_equal(GroundAutotile.ONE_WAY_ALTERNATIVE)
	assert_vector(RoomMap.tile_coords(map.tile_at(cell))).is_equal(GroundAutotile.PLATFORM_MIDDLE)

func test_water_cells_are_grouped_by_kind() -> void:
	var map := _parse("[room]\norigin = 10, 0\n[grid]\n#..#\n####\n[water]\n.~~.\n....\n").map
	var cells: PackedVector2Array = map.water["~"]
	assert_array(Array(cells)).contains_exactly([Vector2(11, 0), Vector2(12, 0)])

func test_an_entity_takes_its_params_from_its_cell() -> void:
	var result := _parse("[grid]\n.B.\n###\n[entities]\n1,0 = {\"save_id\": \"brute\"}\n")
	assert_bool(result.ok()).is_true()
	assert_int(result.map.entities.size()).is_equal(1)
	var placed: Dictionary = result.map.entities[0]
	assert_vector(placed.cell).is_equal(Vector2i(1, 0))
	assert_str(placed.params.save_id).is_equal("brute")

func test_entity_rows_are_grid_coordinates_not_tile_coordinates() -> void:
	var result := _parse("[room]\norigin = -5, -5\n[grid]\n.B\n[entities]\n1,0 = {}\n")
	assert_bool(result.ok()).is_true()
	assert_vector(result.map.entities[0].cell).is_equal(Vector2i(-4, -5))

func test_comments_are_ignored_outside_the_grid() -> void:
	var result := _parse("; a room\n[room]\norigin = 0, 0 ; top-left\n[grid]\n##\n")
	assert_bool(result.ok()).is_true()

func test_an_unknown_character_is_an_error_at_its_line_and_column() -> void:
	var result := _parse("[grid]\n##\n#?\n")
	assert_bool(result.ok()).is_false()
	assert_str(result.errors[0]).is_equal("test.room:3:2: unknown character '?'")

func test_short_rows_are_padded_with_a_warning() -> void:
	var result := _parse("[grid]\n####\n##\n")
	assert_bool(result.ok()).is_true()
	assert_int(result.warnings.size()).is_equal(1)
	assert_int(result.map.ground_at(Vector2i(3, 1))).is_equal(Enums.Ground.NONE)

func test_params_for_an_empty_cell_are_an_error() -> void:
	var result := _parse("[grid]\n.B\n[entities]\n0,0 = {}\n")
	assert_bool(result.ok()).is_false()
	assert_str(result.errors[0]).contains("no entity at column 0, row 0")

func test_params_that_are_not_a_json_object_are_an_error() -> void:
	var result := _parse("[grid]\nB\n[entities]\n0,0 = [1, 2]\n")
	assert_bool(result.ok()).is_false()

func test_two_entities_may_not_share_an_id() -> void:
	var result := _parse("[grid]\nBB\n[entities]\n0,0 = {\"id\": \"gate\"}\n1,0 = {\"id\": \"gate\"}\n")
	assert_bool(result.ok()).is_false()
	assert_str(result.errors[0]).contains("id 'gate'")

func test_a_missing_grid_is_an_error() -> void:
	assert_bool(_parse("[room]\norigin = 0, 0\n").ok()).is_false()

func test_an_unknown_section_is_an_error() -> void:
	assert_bool(_parse("[rooms]\n[grid]\n#\n").ok()).is_false()

func test_a_broken_legend_is_reported() -> void:
	_legend.entries.append(_entry("#", RoomLegendEntry.Kind.GROUND, Enums.Ground.STONE))
	var result := _parse("[grid]\n#\n")
	assert_bool(result.ok()).is_false()
	assert_str(result.errors[0]).contains("defined twice")

func test_water_may_lie_over_ground() -> void:
	var result := _parse("[grid]\n....\n####\n[water]\n....\n~~~~\n")
	assert_bool(result.ok()).is_true()
	assert_int(result.map.water["~"].size()).is_equal(4)
	assert_int(result.map.ground_at(Vector2i(0, 1))).is_equal(Enums.Ground.EARTH)

func test_water_in_the_ground_grid_is_an_error() -> void:
	assert_bool(_parse("[grid]\n#~#\n").ok()).is_false()

func test_ground_in_the_water_grid_is_an_error() -> void:
	assert_bool(_parse("[grid]\n...\n[water]\n.#.\n").ok()).is_false()

func test_the_water_grid_must_match_the_ground_grid() -> void:
	assert_bool(_parse("[grid]\n...\n...\n[water]\n.~.\n").ok()).is_false()

func test_a_semicolon_inside_json_is_not_a_comment() -> void:
	var result := _parse("[grid]\nB\n[entities]\n0,0 = {\"id\": \"a;b\"} ; trailing note\n")
	assert_bool(result.ok()).is_true()
	assert_str(result.map.entities[0].params.id).is_equal("a;b")

func test_a_grid_row_may_not_start_with_whitespace() -> void:
	assert_bool(_parse("[grid]\n##\n ##\n").ok()).is_false()

# --- Reach -----------------------------------------------------------------------

func test_a_reach_over_water_joins_that_water() -> void:
	var map := _parse("[grid]
#..#
#..#
####
[water]
.rr.
.~~.
....
").map
	assert_int(map.reach["~"].size()).is_equal(2)
	assert_bool(map.water.has("r")).is_false()
	assert_int(map.water["~"].size()).is_equal(2)

func test_a_lone_reach_is_its_own_dry_basin() -> void:
	var map := _parse("[grid]
#..#
####
[water]
.rr.
....
").map
	assert_int(map.reach["r"].size()).is_equal(2)

func test_a_reach_over_a_lake_is_an_error() -> void:
	var result := _parse("[grid]
#..#
#..#
####
[water]
.rr.
.ww.
....
")
	assert_bool(result.ok()).is_false()
	assert_str(result.errors[0]).contains("a lake does not rise")

func test_a_reach_touching_two_waters_is_an_error() -> void:
	var result := _parse("[grid]
#...#
#.#.#
#####
[water]
.rrr.
.~.f.
.....
")
	assert_bool(result.ok()).is_false()
	assert_str(result.errors[0]).contains("touches two kinds of water")

func test_a_reach_under_water_is_an_error() -> void:
	var result := _parse("[grid]
#..#
#..#
####
[water]
.~~.
.rr.
....
")
	assert_bool(result.ok()).is_false()
	assert_str(result.errors[0]).contains("is under water")

func test_a_reach_beside_its_water_is_an_error() -> void:
	var result := _parse("[grid]\n#...#\n#...#\n#####\n[water]\n.rrr.\n.r~~.\n.....\n")
	assert_bool(result.ok()).is_false()
	assert_str(result.errors[0]).contains("beside or below its water's rest")
