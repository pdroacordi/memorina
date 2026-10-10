class_name GroundCollisionTest extends GdUnitTestSuite

## One full square per ground material carrying its material; the alternative is one-way.


func test_every_material_has_a_full_square_with_its_ground() -> void:
	var source := GroundCollision.tile_set().get_source(GroundCollision.SOURCE_ID) as TileSetAtlasSource
	for ground: int in [Enums.Ground.EARTH, Enums.Ground.STONE, Enums.Ground.WOOD]:
		var data := source.get_tile_data(GroundCollision.coords(ground), 0)
		assert_int(data.get_custom_data(GroundCollision.GROUND_DATA)).is_equal(ground)
		assert_int(data.get_collision_polygons_count(0)).is_equal(1)
		var points := data.get_collision_polygon_points(0, 0)
		assert_int(points.size()).is_equal(4)
		assert_float(absf(points[0].x) + absf(points[2].x)).is_equal(float(RoomMap.CELL_PX))
		assert_bool(data.is_collision_polygon_one_way(0, 0)).is_false()

func test_the_alternative_is_one_way() -> void:
	var source := GroundCollision.tile_set().get_source(GroundCollision.SOURCE_ID) as TileSetAtlasSource
	var data := source.get_tile_data(GroundCollision.coords(Enums.Ground.EARTH), GroundCollision.ONE_WAY)
	assert_bool(data.is_collision_polygon_one_way(0, 0)).is_true()

func test_it_collides_on_the_world_layer() -> void:
	assert_int(GroundCollision.tile_set().get_physics_layer_collision_layer(0)).is_equal(GroundCollision.COLLISION_LAYER)
