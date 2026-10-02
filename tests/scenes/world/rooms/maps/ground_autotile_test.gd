class_name GroundAutotileTest extends GdUnitTestSuite

## Verifies atlas tile selection from the eight solid neighbours.

const ALL := GroundAutotile.N | GroundAutotile.E | GroundAutotile.S | GroundAutotile.W \
		| GroundAutotile.NE | GroundAutotile.SE | GroundAutotile.SW | GroundAutotile.NW

func test_a_buried_cell_is_the_plain_middle() -> void:
	assert_vector(GroundAutotile.tile_for(ALL)).is_equal(Vector2i(1, 1))

func test_open_sky_above_is_the_grassy_top() -> void:
	var mask := GroundAutotile.E | GroundAutotile.S | GroundAutotile.W
	assert_vector(GroundAutotile.tile_for(mask)).is_equal(Vector2i(1, 0))

func test_the_top_row_has_corners_at_its_ends() -> void:
	assert_vector(GroundAutotile.tile_for(GroundAutotile.E | GroundAutotile.S)).is_equal(Vector2i(0, 0))
	assert_vector(GroundAutotile.tile_for(GroundAutotile.W | GroundAutotile.S)).is_equal(Vector2i(2, 0))

func test_open_below_is_the_rounded_bottom() -> void:
	var mask := GroundAutotile.N | GroundAutotile.E | GroundAutotile.W
	assert_vector(GroundAutotile.tile_for(mask)).is_equal(Vector2i(1, 2))

func test_sides_face_the_open_side() -> void:
	var left := GroundAutotile.N | GroundAutotile.E | GroundAutotile.S
	var right := GroundAutotile.N | GroundAutotile.W | GroundAutotile.S
	assert_vector(GroundAutotile.tile_for(left)).is_equal(Vector2i(0, 1))
	assert_vector(GroundAutotile.tile_for(right)).is_equal(Vector2i(2, 1))

func test_a_one_wide_wall_has_edges_on_both_sides() -> void:
	assert_vector(GroundAutotile.tile_for(GroundAutotile.N | GroundAutotile.S)).is_equal(Vector2i(3, 1))

func test_a_one_wide_pillar_has_a_top_and_a_bottom() -> void:
	assert_vector(GroundAutotile.tile_for(GroundAutotile.S)).is_equal(Vector2i(6, 3))
	assert_vector(GroundAutotile.tile_for(GroundAutotile.N)).is_equal(Vector2i(6, 4))

func test_a_one_high_run_is_a_platform() -> void:
	assert_vector(GroundAutotile.tile_for(GroundAutotile.E)).is_equal(GroundAutotile.PLATFORM_LEFT)
	assert_vector(GroundAutotile.tile_for(GroundAutotile.E | GroundAutotile.W)).is_equal(GroundAutotile.PLATFORM_MIDDLE)
	assert_vector(GroundAutotile.tile_for(GroundAutotile.W)).is_equal(GroundAutotile.PLATFORM_RIGHT)

func test_a_lone_cell_takes_the_platform_end() -> void:
	assert_vector(GroundAutotile.tile_for(0)).is_equal(GroundAutotile.PLATFORM_LEFT)

func test_an_open_diagonal_above_is_a_grassy_step_corner() -> void:
	assert_vector(GroundAutotile.tile_for(ALL & ~GroundAutotile.NW)).is_equal(Vector2i(4, 3))
	assert_vector(GroundAutotile.tile_for(ALL & ~GroundAutotile.NE)).is_equal(Vector2i(5, 3))

func test_an_open_diagonal_below_is_a_cave_corner() -> void:
	assert_vector(GroundAutotile.tile_for(ALL & ~GroundAutotile.SE)).is_equal(Vector2i(6, 0))
	assert_vector(GroundAutotile.tile_for(ALL & ~GroundAutotile.SW)).is_equal(Vector2i(8, 0))

func test_stone_is_the_same_shape_one_block_over() -> void:
	assert_vector(GroundAutotile.in_material(Vector2i(1, 0), Enums.Ground.STONE)).is_equal(Vector2i(10, 0))
	assert_vector(GroundAutotile.in_material(Vector2i(1, 0), Enums.Ground.EARTH)).is_equal(Vector2i(1, 0))

func test_platform_pieces_are_recognised_in_either_material() -> void:
	assert_bool(GroundAutotile.is_platform_piece(Vector2i(7, 5))).is_true()
	assert_bool(GroundAutotile.is_platform_piece(Vector2i(16, 5))).is_true()
	assert_bool(GroundAutotile.is_platform_piece(Vector2i(1, 0))).is_false()
