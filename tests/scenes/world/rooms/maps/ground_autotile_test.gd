class_name GroundAutotileTest extends GdUnitTestSuite

## Sheet slots, the fill variant hash and the edge-adjacent underlay rule (architecture/biome-tilesets).

const AIR := -1
const EARTH := BiomeTileset.Look.EARTH
const STONE := BiomeTileset.Look.STONE
const WOOD := BiomeTileset.Look.WOOD


func test_every_mask_lands_in_the_four_by_four_block() -> void:
	var seen := {}
	for mask: int in range(1, 16):
		var at := GroundAutotile.wang_coords(mask)
		assert_bool(at.x >= 0 and at.x < 4 and at.y >= 0 and at.y < 4).is_true()
		seen[at] = true
	assert_int(seen.size()).is_equal(15)
	assert_bool(seen.has(GroundAutotile.wang_coords(0))).is_false()

func test_variants_and_ledges_have_their_rows() -> void:
	assert_vector(GroundAutotile.variant_coords(1)).is_equal(Vector2i(0, GroundAutotile.VARIANT_ROW))
	assert_vector(GroundAutotile.variant_coords(4)).is_equal(Vector2i(3, GroundAutotile.VARIANT_ROW))

func test_the_four_ledge_cases() -> void:
	assert_int(GroundAutotile.ledge_coords(false, true).x).is_equal(GroundAutotile.LEDGE_LEFT)
	assert_int(GroundAutotile.ledge_coords(true, true).x).is_equal(GroundAutotile.LEDGE_MIDDLE)
	assert_int(GroundAutotile.ledge_coords(true, false).x).is_equal(GroundAutotile.LEDGE_RIGHT)
	assert_int(GroundAutotile.ledge_coords(false, false).x).is_equal(GroundAutotile.LEDGE_SINGLE)

func test_the_fill_variant_is_stable_bounded_and_varied() -> void:
	assert_int(GroundAutotile.fill_variant(Vector2i(7, -3))).is_equal(GroundAutotile.fill_variant(Vector2i(7, -3)))
	var seen := {}
	for y: int in 16:
		for x: int in 16:
			var variant := GroundAutotile.fill_variant(Vector2i(x, y))
			assert_bool(variant >= 0 and variant <= GroundAutotile.MAX_VARIANTS).is_true()
			seen[variant] = true
	assert_int(seen.size()).is_greater(1)

func test_one_look_counts_only_its_corners() -> void:
	assert_int(GroundAutotile.corner_mask(PackedInt32Array([AIR, AIR, EARTH, EARTH]), EARTH)).is_equal(GroundAutotile.SW | GroundAutotile.SE)

## Cobbles beside earth: the earth runs on under the stone corner next to it.
func test_a_later_look_beside_an_earlier_one_is_underlaid() -> void:
	assert_int(GroundAutotile.corner_mask(PackedInt32Array([AIR, AIR, EARTH, STONE]), EARTH)).is_equal(GroundAutotile.SW | GroundAutotile.SE)

func test_stone_on_earth_fills_the_earth_and_tops_the_stone() -> void:
	var corners := PackedInt32Array([STONE, STONE, EARTH, EARTH])
	assert_int(GroundAutotile.corner_mask(corners, EARTH)).is_equal(GroundAutotile.FULL)
	assert_int(GroundAutotile.corner_mask(corners, STONE)).is_equal(GroundAutotile.NW | GroundAutotile.NE)

## A stone block in the air shows no earth.
func test_stone_alone_draws_no_earth() -> void:
	assert_int(GroundAutotile.corner_mask(PackedInt32Array([AIR, AIR, STONE, STONE]), EARTH)).is_equal(0)

func test_a_diagonal_touch_is_not_underlaid() -> void:
	assert_int(GroundAutotile.corner_mask(PackedInt32Array([EARTH, AIR, AIR, STONE]), EARTH)).is_equal(GroundAutotile.NW)

## bugs/stone-under-earth-draws-a-seasonal-lip-inside-the-ground: earth on stone covers the stone's top.
func test_stone_under_earth_draws_no_top() -> void:
	var corners := PackedInt32Array([EARTH, EARTH, STONE, STONE])
	assert_int(GroundAutotile.corner_mask(corners, STONE)).is_equal(0)
	assert_int(GroundAutotile.corner_mask(corners, EARTH)).is_equal(GroundAutotile.FULL)

## bugs/an-earth-cell-boxed-in-by-stone-grows-a-corner-tuft: no inner corner inside the ground.
func test_earth_boxed_in_by_stone_fills_its_tile() -> void:
	assert_int(GroundAutotile.corner_mask(PackedInt32Array([STONE, STONE, STONE, EARTH]), EARTH)).is_equal(GroundAutotile.FULL)

func test_a_look_absent_from_a_buried_tile_draws_nothing() -> void:
	assert_int(GroundAutotile.corner_mask(PackedInt32Array([STONE, STONE, STONE, STONE]), EARTH)).is_equal(0)

func test_wood_over_stone_over_earth() -> void:
	var corners := PackedInt32Array([WOOD, STONE, EARTH, AIR])
	assert_int(GroundAutotile.corner_mask(corners, EARTH)).is_equal(GroundAutotile.SW | GroundAutotile.NW)
	assert_int(GroundAutotile.corner_mask(corners, STONE)).is_equal(GroundAutotile.NE | GroundAutotile.NW)
	assert_int(GroundAutotile.corner_mask(corners, WOOD)).is_equal(GroundAutotile.NW)
