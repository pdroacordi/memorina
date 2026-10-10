class_name WangSheetTest extends GdUnitTestSuite

## The legacy conversion picks the right quarter, placeholders follow the masks, and pack fills the contract's slots.

const TILE := WangSheet.TILE
const GREY := Color8(128, 128, 128)
const LIP := Color8(0, 200, 0)


## A synthetic legacy sheet: every 32 px tile is one flat colour encoding its column and row.
func _blob() -> Image:
	var sheet := Image.create_empty(18 * TILE, 18 * TILE, false, Image.FORMAT_RGBA8)
	for y: int in 18:
		for x: int in 18:
			sheet.fill_rect(Rect2i(x * TILE, y * TILE, TILE, TILE), _code(Vector2i(x, y)))
	return sheet

func _code(at: Vector2i) -> Color:
	return Color8(at.x * 10, at.y * 10, 200, 255)

func test_mask_zero_is_empty() -> void:
	var tiles := WangSheet.tiles_from_blob(_blob(), 0, 0)
	assert_int(tiles.size()).is_equal(16)
	assert_bool(tiles[0].is_invisible()).is_true()

func test_the_full_tile_is_the_fill() -> void:
	var full := WangSheet.tiles_from_blob(_blob(), 0, 0)[GroundAutotile.FULL]
	assert_that(full.get_pixel(3, 3)).is_equal(_code(Vector2i(1, 1)))
	assert_that(full.get_pixel(28, 28)).is_equal(_code(Vector2i(1, 1)))

## An exposed top (SW|SE): its lower quarters are the cells' top quarters with open sky above.
func test_an_exposed_top_reads_the_top_edge() -> void:
	var top := WangSheet.tiles_from_blob(_blob(), 0, 0)[GroundAutotile.SW | GroundAutotile.SE]
	assert_that(top.get_pixel(20, 20)).is_equal(_code(Vector2i(1, 0)))
	assert_float(top.get_pixel(5, 5).a).is_equal(0.0)

## Only SE solid: the SE quadrant shows that cell's NW quarter, an outer corner.
func test_a_lone_corner_reads_the_outer_corner() -> void:
	var corner := WangSheet.tiles_from_blob(_blob(), 0, 0)[GroundAutotile.SE]
	assert_that(corner.get_pixel(20, 20)).is_equal(_code(Vector2i(0, 0)))

func test_the_stone_block_and_bands_offset_the_source() -> void:
	var stone_winter := WangSheet.tiles_from_blob(_blob(), 9, 2)[GroundAutotile.FULL]
	assert_that(stone_winter.get_pixel(3, 3)).is_equal(_code(Vector2i(10, 13)))

func test_placeholder_lips_only_exposed_tops() -> void:
	var tiles := WangSheet.placeholder_tiles(GREY, LIP)
	assert_that(tiles[GroundAutotile.SW | GroundAutotile.SE].get_pixel(8, 17)).is_equal(LIP)
	assert_that(tiles[GroundAutotile.FULL].get_pixel(8, 17)).is_equal(GREY)

func test_pack_puts_tiles_and_ledges_in_their_slots() -> void:
	var red := Image.create_empty(TILE, TILE, false, Image.FORMAT_RGBA8)
	red.fill(Color8(255, 0, 0))
	var blue := Image.create_empty(TILE, TILE, false, Image.FORMAT_RGBA8)
	blue.fill(Color8(0, 0, 255))
	var tiles: Array[Image] = []
	for mask: int in 16:
		tiles.append(red)
	var bands: Array[Dictionary] = [{}, {"tiles": tiles, "ledge": [blue, blue, blue, blue]}, {}]
	var sheet := WangSheet.pack(bands)
	assert_vector(Vector2i(sheet.get_size())).is_equal(BiomeTileset.SHEET_SIZE)
	var full := GroundAutotile.wang_coords(GroundAutotile.FULL) + Vector2i(0, GroundAutotile.BAND_ROWS)
	assert_that(sheet.get_pixel(full.x * TILE + 1, full.y * TILE + 1)).is_equal(Color8(255, 0, 0))
	var ledge := Vector2i(GroundAutotile.LEDGE_SINGLE, GroundAutotile.LEDGE_ROW + GroundAutotile.BAND_ROWS)
	assert_that(sheet.get_pixel(ledge.x * TILE + 1, ledge.y * TILE + 1)).is_equal(Color8(0, 0, 255))
	assert_float(sheet.get_pixel(1, 1).a).is_equal(0.0)

func _flat(color: Color) -> Image:
	var image := Image.create_empty(TILE, TILE, false, Image.FORMAT_RGBA8)
	image.fill(color)
	return image

## A full tile is the body itself: no edge, no rim, no lip inside the ground.
func test_a_composed_full_tile_is_the_body() -> void:
	var lip := Image.create_empty(TILE, 8, false, Image.FORMAT_RGBA8)
	lip.fill(LIP)
	var tiles := WangSheet.compose(_flat(GREY), lip, 4, 5, 3, Color8(0, 0, 0))
	for y: int in TILE:
		for x: int in TILE:
			assert_that(tiles[GroundAutotile.FULL].get_pixel(x, y)).is_equal(GREY)

func test_an_exposed_top_carries_the_lip_on_its_walk_line() -> void:
	var lip := Image.create_empty(TILE, 8, false, Image.FORMAT_RGBA8)
	lip.fill(LIP)
	var top := WangSheet.compose(_flat(GREY), lip, 4, 5, 3, Color8(0, 0, 0))[GroundAutotile.SW | GroundAutotile.SE]
	# The lip's walk line (its row 4) lies on the cell edge, the tile's midline; it spills 4 px into the air above.
	assert_that(top.get_pixel(8, 16)).is_equal(LIP)
	assert_that(top.get_pixel(8, 12)).is_equal(LIP)
	assert_float(top.get_pixel(8, 11).a).is_equal(0.0)

func test_an_outer_corner_is_rounded() -> void:
	var tiles := WangSheet.compose(_flat(GREY), Image.create_empty(TILE, 8, false, Image.FORMAT_RGBA8), 4, 5, 3, Color8(0, 0, 0))
	# Only NW solid: its outer corner is at the tile centre, so the pixel nearest the centre is cut.
	assert_float(tiles[GroundAutotile.NW].get_pixel(15, 15).a).is_equal(0.0)
	assert_float(tiles[GroundAutotile.NW].get_pixel(5, 5).a).is_equal(1.0)
