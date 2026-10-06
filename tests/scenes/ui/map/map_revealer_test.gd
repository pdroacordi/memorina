class_name MapRevealerTest extends GdUnitTestSuite

## The revealer marks the cells the camera frame shows in the current room and writes them to the live save.

const ROOM := preload("res://scenes/world/rooms/home_village/downtown.tscn")

var _room: Room
var _key: String
var _camera: GameCamera
var _revealer: MapRevealer


func before_test() -> void:
	_room = auto_free(ROOM.instantiate()) as Room
	add_child(_room)
	_key = SceneKey.of(_room)
	SaveSystem.player_data.map_seen.erase(_key)
	_camera = auto_free(GameCamera.new()) as GameCamera
	add_child(_camera)
	_camera.offset = Vector2.ZERO
	_revealer = auto_free(MapRevealer.new()) as MapRevealer
	_revealer.camera = _camera
	add_child(_revealer)
	_revealer.set_physics_process(false)

func after_test() -> void:
	SaveSystem.player_data.map_seen.erase(_key)

func test_nothing_is_revealed_before_a_room_is_entered() -> void:
	_frame_at(Vector2(0, 0))
	assert_bool(SaveSystem.player_data.map_seen.has(_key)).is_false()

func test_the_frame_reveals_the_cells_it_shows_and_no_more() -> void:
	_revealer.on_room_changed(_room)
	var bounds := _room.get_bounds()
	var view := _camera.view_rect()
	_frame_at(bounds.position + view.size * 0.5)
	var grid := _seen()
	assert_bool(grid.is_seen(0, 0)).is_true()
	var cols := ceili(view.size.x / MapGrid.CELL_PX - 0.5)
	assert_bool(grid.is_seen(cols - 1, 0)).is_true()
	assert_bool(grid.is_seen(cols, 0)).is_false()
	assert_bool(grid.is_seen(29, 9)).is_false()

func test_what_was_seen_stays_seen_as_the_frame_moves_on() -> void:
	_revealer.on_room_changed(_room)
	var bounds := _room.get_bounds()
	var half := _camera.view_rect().size * 0.5
	_frame_at(bounds.position + half)
	_frame_at(bounds.end - half)
	var grid := _seen()
	assert_bool(grid.is_seen(0, 0)).is_true()
	assert_bool(grid.is_seen(29, 9)).is_true()

## Re-entering a room starts from what the save holds.
func test_a_room_entered_again_keeps_its_cells() -> void:
	_revealer.on_room_changed(_room)
	_frame_at(_room.get_bounds().position + _camera.view_rect().size * 0.5)
	var before := SaveSystem.map_seen(_key)
	_revealer.on_room_changed(_room)
	_frame_at(_room.get_bounds().end - _camera.view_rect().size * 0.5)
	var grid := _seen()
	assert_bool(grid.is_seen(0, 0)).is_true()
	assert_bool(MapGrid.from_bytes(before, Vector2i(30, 10)).is_seen(29, 9)).is_false()

## A frame that shows nothing new writes nothing.
func test_an_unchanged_frame_does_not_write() -> void:
	_revealer.on_room_changed(_room)
	var at := _room.get_bounds().position + _camera.view_rect().size * 0.5
	_frame_at(at)
	SaveSystem.player_data.map_seen[_key] = PackedByteArray([9])
	_frame_at(at)
	_frame_at(at + Vector2(1, 0))
	assert_object(SaveSystem.map_seen(_key)).is_equal(PackedByteArray([9]))

func _frame_at(centre: Vector2) -> void:
	_camera.global_position = centre
	_revealer._physics_process(0.0)

func _seen() -> MapGrid:
	return MapGrid.from_bytes(SaveSystem.map_seen(_key), MapGrid.dims_for(_room.get_bounds()))
