class_name RoomMapNodeTest extends GdUnitTestSuite

## Entity links resolve regardless of the order in the room file.

const ROOM := """[room]
origin = 0, 0
tileset = legacy

[grid]
......
.G..P.
######

[entities]
1,1 = {"id": "door", "trigger_path": "plate"}
4,1 = {"id": "plate"}
"""

func test_a_link_to_an_entity_listed_later_resolves() -> void:
	var result := RoomMapParser.parse(ROOM, RoomLegend.load_default())
	assert_bool(result.ok()).is_true()
	var room := RoomMapNode.new()
	room.map = result.map
	add_child(room)
	auto_free(room)
	var plate := room.get_node("Entities/plate") as PressurePlate
	assert_object(plate).is_not_null()
	assert_int(plate.activated.get_connections().size()).is_equal(1)

const POOL := """[room]
origin = 0, 0
tileset = legacy

[grid]
#....#
#....#
#....#
######

[water]
.rrrr.
.~~~~.
.~~~~.
......
"""

## A reach above pool water pours one rising pool that stands at the water painted under it.
func test_a_pool_with_a_reach_rests_at_its_water() -> void:
	var result := RoomMapParser.parse(POOL, RoomLegend.load_default())
	assert_bool(result.ok()).is_true()
	var room := RoomMapNode.new()
	room.map = result.map
	add_child(room)
	auto_free(room)
	var layer := room.get_node("Water_~") as WaterLayer
	assert_int(layer.get_child_count()).is_equal(1)
	var pool := layer.get_child(0)
	assert_object(pool.get_node_or_null("Rain")).is_not_null()
	var water := pool.get_node("Water") as WaterBody
	assert_float(water.rest_depth).is_equal(32.0)

## Back walls, ground per look, ledges, the hidden Solid layer, water, then entities.
func test_it_builds_its_layers_in_order() -> void:
	var result := RoomMapParser.parse("[room]\ntileset = legacy\n[grid]\n.==..\n..SS.\n#####\n[back]\n%%...\n.....\n.....\n", RoomLegend.load_default())
	assert_bool(result.ok()).is_true()
	var room := auto_free(RoomMapNode.new()) as RoomMapNode
	room.map = result.map
	add_child(room)
	var names := room.get_children().map(func(child: Node) -> String: return child.name)
	assert_array(names).contains_exactly(["Back_Wood", "Ground_Earth", "Ground_Stone", "Ledges", "Solid", "Entities"])
	var ground := room.get_node("Ground_Earth") as TileMapLayer
	assert_vector(ground.position).is_equal(Vector2(-16, -16))
	var solid := room.get_node("Solid") as TileMapLayer
	assert_bool(solid.visible).is_false()
	assert_vector(solid.position).is_equal(Vector2.ZERO)

## The hidden layer still collides: a point query at a solid cell's centre hits it, and the ledge is one-way.
func test_the_hidden_solid_layer_collides() -> void:
	var result := RoomMapParser.parse("[room]\ntileset = legacy\n[grid]\n.==.\n....\n####\n", RoomLegend.load_default())
	var room := auto_free(RoomMapNode.new()) as RoomMapNode
	room.map = result.map
	add_child(room)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var query := PhysicsPointQueryParameters2D.new()
	query.position = room.to_global(Vector2(48, 80))
	assert_int(room.get_world_2d().direct_space_state.intersect_point(query).size()).is_greater(0)
	assert_int(room.ground_at(room.to_global(Vector2(48, 80)))).is_equal(Enums.Ground.EARTH)
	assert_int(room.ground_at(room.to_global(Vector2(48, 48)))).is_equal(Enums.Ground.NONE)
	var ledge := room.get_node("Solid") as TileMapLayer
	assert_int(ledge.get_cell_alternative_tile(Vector2i(1, 0))).is_equal(GroundCollision.ONE_WAY)

## The legacy sheets draw no variants: a full tile that drew from the variant row would be a hole in the fill.
func test_a_variant_the_sheet_lacks_falls_back_to_the_fill() -> void:
	var result := RoomMapParser.parse("[room]\ntileset = legacy\n[grid]\n" + "########\n".repeat(8), RoomLegend.load_default())
	var room := auto_free(RoomMapNode.new()) as RoomMapNode
	room.map = result.map
	add_child(room)
	var ground := room.get_node("Ground_Earth") as TileMapLayer
	for cell: Vector2i in ground.get_used_cells():
		assert_int(ground.get_cell_atlas_coords(cell).y).is_less(GroundAutotile.VARIANT_ROW)

## Grass grows on an exposed earth top outside and never inside an interior (systems/grass, Indoors).
func test_an_interior_grows_no_grass() -> void:
	var result := RoomMapParser.parse("[room]\ntileset = village\n[grid]\n......\n......\n######\n", RoomLegend.load_default())
	assert_bool(result.ok()).is_true()
	for interior: bool in [false, true]:
		var room := Room.new()
		room.interior = interior
		var shape := CollisionShape2D.new()
		shape.name = "CollisionShape2D"
		room.add_child(shape)
		var node := RoomMapNode.new()
		node.map = result.map
		room.add_child(node)
		add_child(auto_free(room))
		assert_bool(node.has_node("Grass")).is_equal(not interior)

func test_setting_the_map_twice_leaves_one_set_of_children() -> void:
	var result := RoomMapParser.parse("[room]\ntileset = legacy\n[grid]\n.B.\n###\n", RoomLegend.load_default())
	var room := auto_free(RoomMapNode.new()) as RoomMapNode
	room.map = result.map
	add_child(room)
	var first := room.get_child_count()
	room.map = result.map
	assert_int(room.get_child_count()).is_equal(first)
	# The replaced children are queued for freeing: let the frame end so none is left orphaned.
	await get_tree().process_frame

## bugs/a-rooms-ground-art-hangs-into-the-room-below-at-a-mismatched-seam: the ground draws only inside the map.
func test_the_ground_is_clipped_to_the_map() -> void:
	var result := RoomMapParser.parse("[room]\norigin = 2, 1\ntileset = legacy\n[grid]\n....\n####\n", RoomLegend.load_default())
	var room := auto_free(RoomMapNode.new()) as RoomMapNode
	room.map = result.map
	add_child(room)
	var material := (room.get_node("Ground_Earth") as TileMapLayer).material as ShaderMaterial
	assert_that(material.get_shader_parameter(&"clip_rect")).is_equal(Vector4(64, 32, 128, 64))
