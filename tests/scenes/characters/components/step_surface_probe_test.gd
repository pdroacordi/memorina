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

class SurfacedBody extends StaticBody2D:
	var step_surface: Enums.Surface = Enums.Surface.WOOD


func test_a_body_with_a_step_surface_answers_it() -> void:
	var body := auto_free(SurfacedBody.new()) as SurfacedBody
	assert_int(StepSurfaceProbe.surface_of(body, RID())).is_equal(Enums.Surface.WOOD)

func test_a_plain_body_is_the_default() -> void:
	var body := auto_free(StaticBody2D.new()) as StaticBody2D
	assert_int(StepSurfaceProbe.surface_of(body, RID())).is_equal(StepSurfaceProbe.DEFAULT_SURFACE)

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
