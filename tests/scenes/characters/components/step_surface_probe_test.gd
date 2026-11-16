class_name StepSurfaceProbeTest extends GdUnitTestSuite

## A floor body answers its own step_surface, or STONE; a room's Solid layer answers its cell's surface; the wading
## count is balanced and never negative.

const ROOM := """[room]
origin = 0, 0
tileset = frozen_lake

[grid]
....
....
##SS
"""

# Wider than one 16-cell physics quadrant: snow under columns 0..19, stone under 20..39.
const WIDE_ROOM := """[room]
origin = 0, 0
tileset = frozen_lake

[grid]
........................................
........................................
####################SSSSSSSSSSSSSSSSSSSS
"""

class SurfacedBody extends StaticBody2D:
	var step_surface: Enums.Surface = Enums.Surface.WOOD


func test_a_body_with_a_step_surface_answers_it() -> void:
	var body := auto_free(SurfacedBody.new()) as SurfacedBody
	assert_int(StepSurfaceProbe.surface_of(body, Vector2.ZERO)).is_equal(Enums.Surface.WOOD)

func test_a_plain_body_is_the_default() -> void:
	var body := auto_free(StaticBody2D.new()) as StaticBody2D
	assert_int(StepSurfaceProbe.surface_of(body, Vector2.ZERO)).is_equal(StepSurfaceProbe.DEFAULT_SURFACE)

func test_a_room_cell_answers_its_biome_surface() -> void:
	var result := RoomMapParser.parse(ROOM, RoomLegend.load_default())
	assert_bool(result.ok()).is_true()
	var room := RoomMapNode.new()
	room.map = result.map
	add_child(room)
	auto_free(room)
	assert_int(room.surface_at(Vector2i(0, 2))).is_equal(Enums.Surface.SNOW)
	assert_int(room.surface_at(Vector2i(3, 2))).is_equal(Enums.Surface.STONE)
	assert_int(room.surface_at(Vector2i(0, 0))).is_equal(Enums.Surface.NONE)
	assert_int(room.surface_at(Vector2i(9, 9))).is_equal(Enums.Surface.NONE)

func test_wading_is_counted_and_balanced() -> void:
	var holder := auto_free(CharacterBody2D.new()) as CharacterBody2D
	var probe := StepSurfaceProbe.new()
	holder.add_child(probe)
	add_child(holder)
	probe.exit_wading()
	assert_int(probe.surface()).is_equal(Enums.Surface.NONE)
	probe.enter_wading()
	probe.enter_wading()
	probe.exit_wading()
	assert_int(probe.surface()).is_equal(Enums.Surface.SHALLOW_WATER)
	probe.exit_wading()
	assert_int(probe.surface()).is_equal(Enums.Surface.NONE)

func test_a_body_landing_on_room_ground_reads_the_cell_under_it() -> void:
	var result := RoomMapParser.parse(WIDE_ROOM, RoomLegend.load_default())
	assert_bool(result.ok()).is_true()
	var room := RoomMapNode.new()
	room.map = result.map
	add_child(room)
	auto_free(room)
	for column: int in [3, 18, 25, 37]:
		var body := CharacterBody2D.new()
		var shape := CollisionShape2D.new()
		var box := RectangleShape2D.new()
		box.size = Vector2(8.0, 16.0)
		shape.shape = box
		body.add_child(shape)
		var probe := StepSurfaceProbe.new()
		body.add_child(probe)
		body.position = Vector2(column * RoomMap.CELL_PX + RoomMap.CELL_PX * 0.5, 40.0)
		add_child(body)
		for _frame: int in 30:
			await get_tree().physics_frame
			body.velocity = Vector2(0.0, 300.0)
			body.move_and_slide()
			probe.update()
			if body.is_on_floor():
				break
		assert_bool(body.is_on_floor()).override_failure_message("column %d never landed" % column).is_true()
		var expected := Enums.Surface.SNOW if column < 20 else Enums.Surface.STONE
		assert_int(probe.surface()).override_failure_message("column %d" % column).is_equal(expected)
		body.free()
