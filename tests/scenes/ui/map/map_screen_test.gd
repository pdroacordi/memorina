class_name MapScreenTest extends GdUnitTestSuite

## The map draws the rooms with seen cells, opens on a clamped centre, steps its zoom and pans in pack px.

const MAP := preload("res://scenes/ui/map/map_screen.tscn")
const ROOM := preload("res://scenes/world/rooms/home_village/downtown.tscn")

var _room: Room
var _key: String
var _map: MapScreen
var _canvas: MapCanvas


func before_test() -> void:
	_room = auto_free(ROOM.instantiate()) as Room
	add_child(_room)
	_key = SceneKey.of(_room)
	_map = auto_free(MAP.instantiate()) as MapScreen
	add_child(_map)
	_canvas = _map.get_node("%Canvas") as MapCanvas

func after_test() -> void:
	SaveSystem.player_data.map_seen.erase(_key)

func test_a_room_never_seen_draws_nothing() -> void:
	_map.open()
	assert_bool(_canvas.seen_rect().has_area()).is_false()
	assert_object(_map.centre()).is_equal(Vector2.ZERO)

func test_the_seen_area_is_the_marked_cells_in_world_px() -> void:
	_see(Rect2i(2, 1, 10, 6))
	_map.open()
	var origin := _room.get_bounds().position
	assert_object(_canvas.seen_rect()).is_equal(Rect2(origin + Vector2(128, 64), Vector2(640, 384)))

## Without Ivo the centre is the world origin, clamped into what was seen.
func test_the_centre_is_clamped_into_the_seen_area() -> void:
	_see(Rect2i(2, 1, 10, 6))
	_map.open()
	assert_bool(_canvas.seen_rect().grow(0.01).has_point(_map.centre())).is_true()

func test_it_opens_at_four_pack_px_per_cell_and_steps_between_one_and_eight() -> void:
	_see(Rect2i(0, 0, 4, 4))
	_map.open()
	assert_int(_map.cell_px()).is_equal(4)
	_map.zoom(1)
	_map.zoom(1)
	assert_int(_map.cell_px()).is_equal(8)
	for i: int in 5:
		_map.zoom(-1)
	assert_int(_map.cell_px()).is_equal(1)

## A pan of 16 pack px at 4 px per cell is 4 world cells; a pan past the seen area stops at its edge.
func test_a_pan_moves_in_pack_px_and_stops_at_the_seen_edge() -> void:
	_see(Rect2i(0, 0, 30, 10))
	_map.open()
	var seen := _canvas.seen_rect()
	_map.pan_by(-_map.centre() + seen.get_center())
	var start := _map.centre()
	_map.pan_by(Vector2(16, 0))
	assert_float(_map.centre().x - start.x).is_equal_approx(256.0, 0.001)
	_map.pan_by(Vector2(100000, 100000))
	assert_object(_map.centre()).is_equal(seen.end)

## The canvas sits on whole pack px at every zoom, so cells never straddle a screen pixel pair.
func test_the_canvas_lands_on_whole_pack_px() -> void:
	_see(Rect2i(0, 0, 30, 10))
	_map.open()
	for step: int in MapScreen.CELL_PX_STEPS.size():
		_map.pan_by(Vector2(3.3, -1.7))
		var position := _canvas.position
		assert_object(position).is_equal(position.round())
		_map.zoom(1 if step < 2 else -1)

## Geometry is cached per room; a room seen further since the last open is rebuilt.
func test_a_reopen_shows_what_was_seen_since() -> void:
	_see(Rect2i(0, 0, 10, 6))
	_map.open()
	_map.close()
	_see(Rect2i(0, 0, 20, 6))
	_map.open()
	assert_float(_canvas.seen_rect().size.x).is_equal(20.0 * MapGrid.CELL_PX)

## Bytes with a header and no seen cell draw nothing, on every open.
func test_a_room_whose_bytes_hold_no_cell_draws_nothing_twice() -> void:
	SaveSystem.set_map_seen(_key, MapGrid.new(Vector2i(30, 10)).to_bytes())
	_map.open()
	_map.close()
	_map.open()
	assert_bool(_canvas.seen_rect().has_area()).is_false()

## A walk direction held through the open does not pan until it is let go (bugs/a-direction-held-when-the-map-opens-pans-it-off-ivo).
func test_a_direction_held_through_the_open_does_not_pan() -> void:
	_see(Rect2i(0, 0, 30, 10))
	_map.open()
	var start := _map.centre()
	_map.pan_held(Vector2(1, 0), 0.05)
	_map.pan_held(Vector2(1, 0), 0.05)
	assert_object(_map.centre()).is_equal(start)
	_map.pan_held(Vector2.ZERO, 0.05)
	_map.pan_held(Vector2(1, 0), 0.05)
	assert_float(_map.centre().x).is_greater(start.x)

## Each axis re-arms on its own: Up pans while Right is still held from the walk.
func test_each_axis_arms_on_its_own() -> void:
	_see(Rect2i(0, 0, 30, 10))
	_map.open()
	_map.pan_by(Vector2(0, 10))
	var start := _map.centre()
	_map.pan_held(Vector2(1, 0), 0.05)
	_map.pan_held(Vector2(1, -1), 0.05)
	assert_float(_map.centre().x).is_equal(start.x)
	assert_float(_map.centre().y).is_less(start.y)

## A one-second hitch pans no farther than one capped step.
func test_a_hitch_pans_one_capped_step() -> void:
	_see(Rect2i(0, 0, 30, 10))
	_map.open()
	_map.pan_held(Vector2.ZERO, 0.0)
	var start := _map.centre()
	_map.pan_held(Vector2(1, 0), 1.0)
	var step := _map.pan_speed * MapScreen.MAX_PAN_SECONDS * MapGrid.CELL_PX / _map.cell_px()
	assert_float(_map.centre().x - start.x).is_equal_approx(step, 0.001)

## Reopening forgets the arming: a direction held into the next open is ignored again.
func test_reopening_disarms_the_pan() -> void:
	_see(Rect2i(0, 0, 30, 10))
	_map.open()
	_map.pan_held(Vector2.ZERO, 0.0)
	_map.close()
	_map.open()
	var start := _map.centre()
	_map.pan_held(Vector2(1, 0), 0.05)
	assert_object(_map.centre()).is_equal(start)

func test_closing_stops_the_pan_clock() -> void:
	_map.open()
	assert_bool(_map.is_processing()).is_true()
	_map.close()
	assert_bool(_map.is_processing()).is_false()
	assert_bool(_map.visible).is_false()

func _see(cells: Rect2i) -> void:
	var grid := MapGrid.new(MapGrid.dims_for(_room.get_bounds()))
	grid.mark_cells(cells)
	SaveSystem.set_map_seen(_key, grid.to_bytes())
