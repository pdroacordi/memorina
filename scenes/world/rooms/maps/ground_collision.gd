class_name GroundCollision
extends RefCounted
## The hidden, cell-aligned collision TileSet every room shares: one full square per Enums.Ground, alternative ONE_WAY for ledges.
## Collision never comes from the art (architecture/biome-tilesets).

const SOURCE_ID := 0
const ONE_WAY := 1
## The custom data layer holding each tile's Enums.Ground.
const GROUND_DATA := "ground"
## Physics layer 1, "World".
const COLLISION_LAYER := 1

static var _tile_set: TileSet


static func tile_set() -> TileSet:
	if _tile_set == null:
		_tile_set = _build()
	return _tile_set

static func coords(ground: Enums.Ground) -> Vector2i:
	return Vector2i(ground, 0)

static func _build() -> TileSet:
	var built := TileSet.new()
	var cell := RoomMap.CELL_PX
	built.tile_size = Vector2i(cell, cell)
	built.add_physics_layer()
	built.set_physics_layer_collision_layer(0, COLLISION_LAYER)
	built.add_custom_data_layer()
	built.set_custom_data_layer_name(0, GROUND_DATA)
	built.set_custom_data_layer_type(0, TYPE_INT)
	var source := TileSetAtlasSource.new()
	source.texture = ImageTexture.create_from_image(Image.create_empty(cell * Enums.Ground.size(), cell, false, Image.FORMAT_RGBA8))
	source.texture_region_size = Vector2i(cell, cell)
	built.add_source(source, SOURCE_ID)
	var half := cell * 0.5
	var square := PackedVector2Array([Vector2(-half, -half), Vector2(half, -half), Vector2(half, half), Vector2(-half, half)])
	for ground: int in Enums.Ground.values():
		if ground == Enums.Ground.NONE:
			continue
		var at := coords(ground)
		source.create_tile(at)
		source.create_alternative_tile(at, ONE_WAY)
		for alternative: int in [0, ONE_WAY]:
			var data := source.get_tile_data(at, alternative)
			data.add_collision_polygon(0)
			data.set_collision_polygon_points(0, 0, square)
			data.set_collision_polygon_one_way(0, 0, alternative == ONE_WAY)
			data.set_custom_data(GROUND_DATA, ground)
	return built
