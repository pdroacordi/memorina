class_name RoomMapParserTest extends GdUnitTestSuite

## Checks room parsing, dual-grid tile resolution and source-positioned errors.

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
		_shell_reach("u"),
		_thing("B"),
		_entry("%", RoomLegendEntry.Kind.GROUND, Enums.Ground.WOOD),
		_back("h"),
	]

func _entry(symbol: String, kind: RoomLegendEntry.Kind, ground: Enums.Ground) -> RoomLegendEntry:
	var entry := RoomLegendEntry.new()
	entry.symbol = symbol
	entry.kind = kind
	entry.ground = ground
	match ground:
		Enums.Ground.STONE:
			entry.look = BiomeTileset.Look.STONE
		Enums.Ground.WOOD:
			entry.look = BiomeTileset.Look.WOOD
	return entry

func _back(symbol: String) -> RoomLegendEntry:
	var entry := _entry(symbol, RoomLegendEntry.Kind.BACK, Enums.Ground.NONE)
	entry.look = BiomeTileset.Look.WALL
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

func _shell_reach(symbol: String) -> RoomLegendEntry:
	var entry := _reach(symbol)
	entry.rains = false
	return entry

func _thing(symbol: String) -> RoomLegendEntry:
	var entry := _entry(symbol, RoomLegendEntry.Kind.ENTITY, Enums.Ground.NONE)
	entry.scene = PackedScene.new()
	return entry

func _parse(text: String) -> RoomMapParser.Result:
	# Appended, so line numbers in the asserted messages stay where the text puts them.
	return RoomMapParser.parse(text + "\n[room]\ntileset = legacy\n", _legend, "test.room")

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

## The display cell on the corner between two air cells and two earth cells is an exposed top.
func test_a_floor_under_open_sky_draws_its_exposed_top() -> void:
	var map := _parse("[grid]\n....\n####\n").map
	var layer: PackedByteArray = map.ground_layers[BiomeTileset.Look.EARTH]
	var width := map.display_size().x
	assert_int(layer[1 * width + 1] & 0xf).is_equal(GroundAutotile.SW | GroundAutotile.SE)
	# Below the map the bottom row repeats, so the floor continues past the map's bottom edge.
	assert_int(layer[2 * width + 1] & 0xf).is_equal(GroundAutotile.FULL)

func test_stone_draws_on_its_own_layer() -> void:
	var map := _parse("[grid]\n....\nSSSS\n").map
	assert_array(map.ground_layers.keys()).contains_exactly([BiomeTileset.Look.STONE])

func test_a_platform_is_one_way_and_drawn_as_a_ledge() -> void:
	var map := _parse("[grid]\n.===.\n.....\n").map
	var cell := Vector2i(2, 0)
	assert_bool(map.is_platform(cell)).is_true()
	assert_bool(map.is_solid(cell)).is_false()
	assert_bool(map.ground_layers.has(BiomeTileset.Look.EARTH)).is_false()
	var ledges: PackedByteArray = map.ledge_layers[BiomeTileset.Look.EARTH]
	assert_int(ledges[2]).is_equal(GroundAutotile.LEDGE_MIDDLE + 1)
	assert_int(ledges[1]).is_equal(GroundAutotile.LEDGE_LEFT + 1)

func test_wood_is_solid_wood() -> void:
	var map := _parse("[grid]\n%%\n").map
	assert_int(map.ground_at(Vector2i(0, 0))).is_equal(Enums.Ground.WOOD)
	assert_bool(map.is_solid(Vector2i(1, 0))).is_true()

func test_a_room_without_a_tileset_is_an_error() -> void:
	var result := RoomMapParser.parse("[grid]\n##\n", _legend, "test.room")
	assert_str(" ".join(result.errors)).contains("no 'tileset' in [room]")

func test_an_unknown_tileset_is_an_error() -> void:
	var result := RoomMapParser.parse("[room]\ntileset = nowhere\n[grid]\n##\n", _legend, "test.room")
	assert_str(" ".join(result.errors)).contains("unknown tileset 'nowhere'")

func test_a_malformed_tileset_is_an_error() -> void:
	var result := RoomMapParser.parse("[room]\ntileset = Village-1\n[grid]\n##\n", _legend, "test.room")
	assert_str(" ".join(result.errors)).contains("tileset must be a biome file name")

func test_back_walls_never_change_the_ground() -> void:
	var result := _parse("[grid]\n....\n####\n[back]\nhh..\n....\n")
	assert_bool(result.ok()).is_true()
	assert_int(result.map.ground_at(Vector2i(0, 0))).is_equal(Enums.Ground.NONE)
	assert_bool(result.map.back_layers.has(BiomeTileset.Look.WALL)).is_true()

func test_back_needs_the_grid_rows() -> void:
	var result := _parse("[grid]\n....\n####\n[back]\nhh..\n")
	assert_str(" ".join(result.errors)).contains("[back] has 1 rows, [grid] has 2")

func test_a_ledge_cannot_be_a_back_wall() -> void:
	var result := _parse("[grid]\n....\n####\n[back]\n.==.\n....\n")
	assert_str(" ".join(result.errors)).contains("'=' cannot be a back wall")

func test_a_back_wall_belongs_in_back() -> void:
	var result := _parse("[grid]\n.h..\n####\n")
	assert_str(" ".join(result.errors)).contains("'h' belongs in [back], not [grid]")

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

## Water beside an open passage mouth stands in the air (bugs/well-water-stands-in-the-air-at-a-passage-mouth).
func test_pool_water_beside_open_air_is_an_error() -> void:
	var result := _parse("[grid]\n#....#\n##..##\n#...##\n######\n[water]\n......\n..~~..\n..~~..\n......\n")
	assert_bool(result.ok()).is_false()
	assert_str(str(result.errors)).contains("stands against open air")

## A flooded passage up into a sealed chamber: the chamber's trapped air holds the water at its floor.
func test_water_under_a_sealed_pocket_is_held() -> void:
	var result := _parse("[grid]\n####...#\n#..#...#\n##.#...#\n##.....#\n########\n[water]\n........\n....~~~.\n..~.~~~.\n..~~~~~.\n........\n")
	assert_bool(result.ok()).is_true()

func test_water_under_air_open_to_the_sky_is_an_error() -> void:
	var result := _parse("[grid]\n#.##...#\n#..#...#\n##.#...#\n##.....#\n########\n[water]\n........\n....~~~.\n..~.~~~.\n..~~~~~.\n........\n")
	assert_bool(result.ok()).is_false()

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

func test_a_lake_over_air_running_off_both_sides_parses() -> void:
	var result := _parse("[grid]
====
....
[water]
....
wwww
")
	assert_bool(result.ok()).is_true()
	assert_int(result.map.water["w"].size()).is_equal(4)

func test_a_lake_ending_against_ground_on_every_row_parses() -> void:
	var result := _parse("[grid]
S..#
S..#
[water]
.ww.
.ww.
")
	assert_bool(result.ok()).is_true()

func test_a_lake_over_ground_is_an_error() -> void:
	var result := _parse("[grid]
....
SSSS
[water]
....
wwww
")
	assert_bool(result.ok()).is_false()
	assert_str(result.errors[0]).contains("'w' at 0,1 lies over ground (and 3 more cells)")

func test_a_lake_over_a_ledge_is_an_error() -> void:
	var result := _parse("[grid]
..=.
....
[water]
..w.
wwww
")
	assert_bool(result.ok()).is_false()
	assert_str(result.errors[0]).contains("'w' at 2,0 lies over a ledge")

func test_a_lake_ending_in_the_air_is_an_error() -> void:
	var result := _parse("[grid]
S...
S...
[water]
.ww.
.www
")
	assert_bool(result.ok()).is_false()
	assert_int(result.errors.size()).is_equal(1)
	assert_str(result.errors[0]).contains("'w' at 2,0 ends in the air: run each row")

func test_a_lake_ending_beside_a_ledge_is_an_error() -> void:
	var result := _parse("[grid]
#..=
[water]
.ww.
")
	assert_bool(result.ok()).is_false()
	assert_str(result.errors[0]).contains("'w' at 2,0 ends in the air")

func test_a_lake_column_stopping_in_the_air_is_an_error() -> void:
	var result := _parse("[grid]
....
....
####
[water]
wwww
....
....
")
	assert_bool(result.ok()).is_false()
	assert_int(result.errors.size()).is_equal(1)
	assert_str(result.errors[0]).contains("'w' at 0,0 stops in the air (and 3 more cells): run each column")

func test_a_lake_column_on_solid_ground_parses() -> void:
	var result := _parse("[grid]
....
####
[water]
wwww
....
")
	assert_bool(result.ok()).is_true()

func test_a_lake_row_meeting_a_pool_is_its_own_error() -> void:
	var result := _parse("[grid]
#....#
######
[water]
.ww~~.
......
")
	assert_bool(result.ok()).is_false()
	assert_int(result.errors.size()).is_equal(1)
	assert_str(result.errors[0]).contains("'w' at 2,0 meets '~' water: a lake and another kind of water need solid ground")

func test_a_lake_over_a_pool_is_its_own_error() -> void:
	var result := _parse("[grid]
#..#
#..#
####
[water]
.ww.
.~~.
....
")
	assert_bool(result.ok()).is_false()
	assert_str(result.errors[0]).contains("'w' at 1,0 meets '~' water (and 1 more cells)")

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

func test_a_shell_reach_joins_its_water_apart_from_the_rain() -> void:
	var map := _parse("[grid]
#..#
#..#
####
[water]
.uu.
.ff.
....
").map
	assert_int(map.shell_reach["f"].size()).is_equal(2)
	assert_bool(map.reach.has("f")).is_false()

func test_a_shell_reach_on_no_water_is_an_error() -> void:
	var result := _parse("[grid]
#..#
####
[water]
.uu.
....
")
	assert_bool(result.ok()).is_false()
	assert_str(result.errors[0]).contains("stands on no water")

func test_a_pool_rises_with_the_rain_or_a_shell_not_both() -> void:
	var result := _parse("[grid]\n#...#\n#...#\n#####\n[water]\n.ruu.\n.fff.\n.....\n")
	assert_bool(result.ok()).is_false()
	assert_str(result.errors[0]).contains("rises with the rain or with a shell")

func test_secret_cells_stay_air_and_group_eight_connected() -> void:
	var result := _parse("[grid]\n....\n....\n####\n[secret]\n#...\n.#.#\n....\n")
	assert_bool(result.ok()).is_true()
	var map := result.map
	assert_int(map.ground_at(Vector2i(0, 0))).is_equal(Enums.Ground.NONE)
	assert_int(map.secret_at(Vector2i(0, 0))).is_equal(map.secret_at(Vector2i(1, 1)))
	assert_int(map.secret_at(Vector2i(3, 1))).is_not_equal(map.secret_at(Vector2i(1, 1)))
	assert_array(Array(map.secret_ids)).contains_exactly(["test@0,0", "test@3,1"])

func test_a_secret_over_ground_is_an_error() -> void:
	assert_bool(_parse("[grid]\n#..\n###\n[secret]\n#..\n...\n").ok()).is_false()

func test_a_ledge_cannot_be_a_secret() -> void:
	assert_bool(_parse("[grid]\n...\n###\n[secret]\n.=.\n...\n").ok()).is_false()

func test_a_secret_under_water_is_an_error() -> void:
	assert_bool(_parse("[grid]\n#.#\n#.#\n###\n[water]\n.~.\n...\n...\n[secret]\n...\n.#.\n...\n").ok()).is_false()
