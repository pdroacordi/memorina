class_name RoomResidencyTest extends GdUnitTestSuite

## The current room and every room touching it run; a room left behind idles, and the oldest idle one is evicted.

const SIZE := Vector2(640, 384)

var _contents: PackedScene
var _rooms: Array[Node] = []


func before_test() -> void:
	_contents = PackedScene.new()
	var root := Node2D.new()
	_contents.pack(root)
	root.free()
	_rooms.clear()

## A row of rooms, one SIZE wide each, at x = 0, 640, 1280...
func _row(count: int) -> Array[Node]:
	for i: int in count:
		_rooms.append(_room(Vector2(SIZE.x * i, 0)))
	return _rooms

func _room(at: Vector2) -> Room:
	var room := auto_free(Room.new()) as Room
	room.contents_scene = _contents
	var shape := CollisionShape2D.new()
	shape.name = "CollisionShape2D"
	var rect := RectangleShape2D.new()
	rect.size = SIZE
	shape.shape = rect
	shape.position = SIZE * 0.5
	room.add_child(shape)
	room.position = at
	add_child(room)
	return room

## Lets the deferred contents enter the tree, so none is left orphaned when the rooms are freed.
func _flush() -> void:
	await get_tree().process_frame

func test_touching_finds_edge_and_corner_neighbours_only() -> void:
	var middle := _room(Vector2.ZERO)
	var right := _room(Vector2(640, 0))
	var corner := _room(Vector2(640, 384))
	var far := _room(Vector2(1920, 0))
	var near := RoomResidency.touching(middle, [middle, right, corner, far] as Array[Node])
	assert_array(near).contains_exactly_in_any_order([middle, right, corner])

func test_the_current_room_and_its_neighbours_run() -> void:
	var rooms := _row(4)
	RoomResidency.new().settle(rooms[1], rooms)
	assert_bool((rooms[0] as Room).is_active()).is_true()
	assert_bool((rooms[1] as Room).is_active()).is_true()
	assert_bool((rooms[2] as Room).is_active()).is_true()
	assert_object((rooms[3] as Room).contents()).is_null()
	await _flush()

## A glide still frames the room left behind, so its neighbours keep running until the glide ends and settle runs again.
func test_rooms_kept_for_a_glide_run_until_the_next_settle() -> void:
	var rooms := _row(4)
	var residency := RoomResidency.new()
	residency.settle(rooms[1], rooms)
	residency.settle(rooms[2], rooms, RoomResidency.touching(rooms[1] as Room, rooms))
	assert_bool((rooms[0] as Room).is_active()).is_true()
	residency.settle(rooms[2], rooms)
	assert_bool((rooms[0] as Room).is_active()).is_false()
	await _flush()

func test_a_room_out_of_reach_idles() -> void:
	var rooms := _row(4)
	var residency := RoomResidency.new()
	residency.settle(rooms[0], rooms)
	residency.settle(rooms[2], rooms)
	assert_bool((rooms[0] as Room).is_active()).is_false()
	assert_object((rooms[0] as Room).contents()).is_not_null()
	await _flush()

func test_the_oldest_idle_room_is_evicted() -> void:
	var rooms := _row(8)
	var residency := RoomResidency.new()
	# Walk 0 -> 2 -> 4 -> 6: rooms 0..3 fall out of reach in turn; only MAX_IDLE_ROOMS of them stay loaded.
	for i: int in [0, 2, 4, 6]:
		residency.settle(rooms[i], rooms)
	var loaded := rooms.filter(func(room: Node) -> bool: return (room as Room).contents() != null)
	assert_int(loaded.size()).is_equal(3 + RoomResidency.MAX_IDLE_ROOMS)
	assert_object((rooms[0] as Room).contents()).is_null()
	await _flush()

## bugs/a-door-trip-evicts-the-room-ivo-left: a door to an isolated room keeps the room Ivo left loaded.
func test_a_door_trip_keeps_the_room_ivo_left() -> void:
	var rooms := _row(3)
	var interior := _room(Vector2(0, 12000))
	rooms.append(interior)
	var residency := RoomResidency.new()
	residency.settle(rooms[1], rooms)
	var left := (rooms[1] as Room).contents()
	residency.settle(interior, rooms)
	assert_object((rooms[1] as Room).contents()).is_same(left)
	assert_bool((rooms[1] as Room).is_active()).is_false()
	await _flush()

func test_an_expired_room_still_in_reach_keeps_its_contents() -> void:
	var rooms := _row(3)
	var residency := RoomResidency.new()
	residency.settle(rooms[0], rooms)
	var before := (rooms[0] as Room).contents()
	(rooms[0] as Room).expire()
	residency.settle(rooms[1], rooms)
	assert_object((rooms[0] as Room).contents()).is_same(before)
	await _flush()

func test_wake_rebuilds_the_neighbours_and_keeps_the_current_room() -> void:
	var rooms := _row(3)
	var residency := RoomResidency.new()
	residency.settle(rooms[1], rooms)
	await _flush()
	var neighbour := (rooms[0] as Room).contents()
	var current := (rooms[1] as Room).contents()
	residency.wake(rooms[1], rooms)
	assert_object((rooms[0] as Room).contents()).is_not_same(neighbour)
	assert_bool((rooms[0] as Room).is_active()).is_true()
	assert_object((rooms[1] as Room).contents()).is_same(current)
	await _flush()
