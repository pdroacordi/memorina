extends SceneTree

## Builds resources/world/tiles/floor_tileset.tres, the one TileSet every
## room's ground draws with, from floor_tiles.png.
##
## Only band 0 (the top six rows) is referenced: the seasonal_art shader swaps
## in the matching band per pixel. The other bands' tiles are still DEFINED
## (bare, no collision or data), because the TileSet's texture padding only
## bakes the regions of defined tiles - leave them out and every season but
## the first samples transparent padding, and the ground vanishes under a
## pulse of another season. Columns 0-8 are EARTH, columns 9-17 the
## STONE derived from them (tools/art/derive_stone_tiles.gd), and every tile
## carries its material in the `ground` custom data layer, which is what
## Enraizar and GroundAutotile read. The thin platform pieces also get an
## alternative (1) whose collision is one-way, for `=` in a room map.
##
## Rerun after changing the sheet's layout:
##   "<godot>" --headless --path . -s res://tools/maps/build_floor_tileset.gd

const SHEET := "res://assets/sprites/world/tilesets/floor_tiles.png"
const OUTPUT := "res://resources/world/tiles/floor_tileset.tres"
const TILE := 32
const BAND_ROWS := 6
const EARTH_COLUMNS := 9
## Tiles with fewer opaque pixels than this are decoration (stalactite tips)
## and get no collision.
const SOLID_COVERAGE := 200

func _init() -> void:
	var texture: Texture2D = load(SHEET)
	var image := texture.get_image()
	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(TILE, TILE)
	tile_set.add_physics_layer()
	tile_set.set_physics_layer_collision_layer(0, 1)
	tile_set.add_custom_data_layer()
	tile_set.set_custom_data_layer_name(0, GroundAutotile.GROUND_DATA)
	tile_set.set_custom_data_layer_type(0, TYPE_INT)

	var source := TileSetAtlasSource.new()
	source.texture = texture
	source.texture_region_size = Vector2i(TILE, TILE)
	tile_set.add_source(source, GroundAutotile.SOURCE_ID)
	for row: int in image.get_height() / TILE:
		for column: int in EARTH_COLUMNS * 2:
			var coverage := _coverage(image, column, row)
			if coverage == 0:
				continue
			var coords := Vector2i(column, row)
			source.create_tile(coords)
			if row >= BAND_ROWS:
				continue
			var ground := Enums.Ground.EARTH if column < EARTH_COLUMNS else Enums.Ground.STONE
			_setup(source.get_tile_data(coords, 0), ground, coverage >= SOLID_COVERAGE, false)
			if GroundAutotile.is_platform_piece(coords):
				var alternative := source.create_alternative_tile(coords, GroundAutotile.ONE_WAY_ALTERNATIVE)
				_setup(source.get_tile_data(coords, alternative), ground, true, true)
	var err := ResourceSaver.save(tile_set, OUTPUT)
	assert(err == OK, "Could not save %s: %s" % [OUTPUT, error_string(err)])
	print("Wrote %s" % OUTPUT)
	quit()

func _setup(data: TileData, ground: Enums.Ground, solid: bool, one_way: bool) -> void:
	data.set_custom_data(GroundAutotile.GROUND_DATA, ground)
	if not solid:
		return
	var half := TILE / 2.0
	data.add_collision_polygon(0)
	data.set_collision_polygon_points(0, 0, PackedVector2Array([
		Vector2(-half, -half), Vector2(half, -half), Vector2(half, half), Vector2(-half, half)]))
	data.set_collision_polygon_one_way(0, 0, one_way)

func _coverage(image: Image, column: int, row: int) -> int:
	var count := 0
	for y: int in TILE:
		for x: int in TILE:
			if image.get_pixel(column * TILE + x, row * TILE + y).a > 0.0:
				count += 1
	return count
