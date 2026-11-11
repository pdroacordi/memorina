class_name RoomResidencyTest extends GdUnitTestSuite

## The current room and every room touching it run; a room left behind idles, and the oldest idle one is evicted. A
## neighbour to build waits and is built one per frame, or at once when the view or Ivo reaches it (systems/rooms).

const SIZE := Vector2(640, 384)
## A view far from every test room: only the per-frame build runs.
const AWAY := Rect2(0, 100000, 640, 360)

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

## Builds every waiting neighbour, one per frame as behind the black.
func _build_all(residency: RoomResidency) -> void:
	while residency.is_waiting():
		residency.build_due(AWAY, Rect2(), true)

func _shown(rects: Array[Rect2]) -> Array:
	var shown: Array = []
	for rect: Rect2 in rects:
		shown.append([rect])
	return shown

func test_due_builds_the_nearest_to_the_view_when_none_shows() -> void:
	var bounds: Array[Rect2] = [Rect2(2000, 0, 640, 384), Rect2(700, 0, 640, 384), Rect2(-3000, 0, 640, 384)]
	var due := RoomResidency.due(bounds, _shown(bounds), Rect2(0, 0, 640, 360), Rect2(), false)
	assert_array(Array(due)).contains_exactly([1])

func test_due_builds_every_room_the_view_meets() -> void:
	var bounds: Array[Rect2] = [Rect2(600, 0, 640, 384), Rect2(-620, 0, 640, 384), Rect2(5000, 0, 640, 384)]
	var due := RoomResidency.due(bounds, _shown(bounds), Rect2(0, 0, 640, 360), Rect2(), false)
	assert_array(Array(due)).contains_exactly_in_any_order([0, 1, 2])

## A room whose drawing only touches the view's edge shows nothing yet; one a pixel past it shows.
func test_due_reads_touching_as_not_shown() -> void:
	var bounds: Array[Rect2] = [Rect2(640, 0, 640, 384), Rect2(0, -384, 640, 384)]
	var due := RoomResidency.due(bounds, _shown(bounds), Rect2(0, 0, 640, 360), Rect2(), false)
	assert_int(due.size()).is_equal(RoomResidency.BUILDS_PER_FRAME)
	var nudged := RoomResidency.due(bounds, _shown(bounds), Rect2(1, 0, 640, 360), Rect2(), false)
	assert_bool(0 in nudged).is_true()

func test_due_builds_the_room_under_ivo_at_once() -> void:
	var bounds: Array[Rect2] = [Rect2(0, 400, 640, 384), Rect2(0, 3000, 640, 384), Rect2(5000, 0, 640, 384)]
	var nothing: Array = [[], [], []]
	var body := Rect2(300, 400 - RoomResidency.BODY_MARGIN - 20, 20, 54)
	var due := RoomResidency.due(bounds, nothing, Rect2(0, -2000, 640, 360), body, false)
	assert_bool(0 in due).is_true()
	assert_int(due.size()).is_equal(1 + RoomResidency.BUILDS_PER_FRAME)

func test_due_behind_the_black_builds_one() -> void:
	var bounds: Array[Rect2] = [Rect2(600, 0, 640, 384), Rect2(-620, 0, 640, 384)]
	var due := RoomResidency.due(bounds, _shown(bounds), Rect2(0, 0, 640, 360), Rect2(300, 200, 20, 54), true)
	assert_int(due.size()).is_equal(1)

## The frame a room is entered pays for the swap: no extra build, but a room in view is still built at once.
func test_due_with_no_extra_builds_only_what_shows() -> void:
	var bounds: Array[Rect2] = [Rect2(600, 0, 640, 384), Rect2(2000, 0, 640, 384)]
	var due := RoomResidency.due(bounds, _shown(bounds), Rect2(0, 0, 640, 360), Rect2(), false, 0)
	assert_array(Array(due)).contains_exactly([0])
	var far: Array[Rect2] = [Rect2(2000, 0, 640, 384)]
	assert_int(RoomResidency.due(far, _shown(far), Rect2(0, 0, 640, 360), Rect2(), false, 0).size()).is_equal(0)

func test_the_frame_a_room_is_entered_builds_no_extra_neighbour() -> void:
	var rooms := _row(3)
	var residency := RoomResidency.new()
	residency.settle(rooms[1], rooms)
	residency.build_due(AWAY, Rect2(), false, true)
	assert_object((rooms[0] as Room).contents()).is_null()
	assert_object((rooms[2] as Room).contents()).is_null()
	residency.build_due(AWAY, Rect2(), false)
	var built := rooms.filter(func(room: Node) -> bool: return (room as Room).contents() != null)
	assert_int(built.size()).is_equal(1 + RoomResidency.BUILDS_PER_FRAME)
	_build_all(residency)
	await _flush()

func test_due_with_nothing_waiting_builds_nothing() -> void:
	var none: Array[Rect2] = []
	assert_int(RoomResidency.due(none, [], Rect2(0, 0, 640, 360), Rect2(), false).size()).is_equal(0)

func test_touching_finds_edge_and_corner_neighbours_only() -> void:
	var middle := _room(Vector2.ZERO)
	var right := _room(Vector2(640, 0))
	var corner := _room(Vector2(640, 384))
	var far := _room(Vector2(1920, 0))
	var near := RoomResidency.touching(middle, [middle, right, corner, far] as Array[Node])
	assert_array(near).contains_exactly_in_any_order([middle, right, corner])

func test_the_current_room_and_its_neighbours_run() -> void:
	var rooms := _row(4)
	var residency := RoomResidency.new()
	residency.settle(rooms[1], rooms)
	_build_all(residency)
	assert_bool((rooms[0] as Room).is_active()).is_true()
	assert_bool((rooms[1] as Room).is_active()).is_true()
	assert_bool((rooms[2] as Room).is_active()).is_true()
	assert_object((rooms[3] as Room).contents()).is_null()
	await _flush()

func test_the_current_room_runs_at_once_and_its_neighbours_wait() -> void:
	var rooms := _row(3)
	var residency := RoomResidency.new()
	residency.settle(rooms[1], rooms)
	assert_bool((rooms[1] as Room).is_active()).is_true()
	assert_object((rooms[0] as Room).contents()).is_null()
	assert_object((rooms[2] as Room).contents()).is_null()
	assert_bool(residency.is_waiting()).is_true()
	residency.build_due(AWAY, Rect2(), false)
	var built := rooms.filter(func(room: Node) -> bool: return (room as Room).contents() != null)
	assert_int(built.size()).is_equal(1 + RoomResidency.BUILDS_PER_FRAME)
	residency.build_due(AWAY, Rect2(), false)
	assert_bool(residency.is_waiting()).is_false()
	await _flush()

func test_a_neighbour_the_view_meets_is_built_in_the_same_frame() -> void:
	var rooms := _row(3)
	var residency := RoomResidency.new()
	residency.settle(rooms[1], rooms)
	# A frame 40 px wider than the middle room on each side: both neighbours draw in it.
	residency.build_due(Rect2(600, 0, 720, 360), Rect2(), false)
	assert_bool((rooms[0] as Room).is_active()).is_true()
	assert_bool((rooms[2] as Room).is_active()).is_true()
	await _flush()

func test_an_idle_neighbour_wakes_without_waiting() -> void:
	var rooms := _row(4)
	var residency := RoomResidency.new()
	residency.settle(rooms[1], rooms)
	_build_all(residency)
	residency.settle(rooms[3], rooms)
	_build_all(residency)
	assert_bool((rooms[0] as Room).is_active()).is_false()
	assert_object((rooms[0] as Room).contents()).is_not_null()
	residency.settle(rooms[1], rooms)
	assert_bool((rooms[0] as Room).is_active()).is_true()
	assert_bool(residency.is_waiting()).is_false()
	await _flush()

func test_a_room_out_of_reach_stops_waiting() -> void:
	var rooms := _row(5)
	var residency := RoomResidency.new()
	residency.settle(rooms[1], rooms)
	residency.settle(rooms[3], rooms)
	_build_all(residency)
	assert_object((rooms[0] as Room).contents()).is_null()
	assert_bool((rooms[4] as Room).is_active()).is_true()
	await _flush()

## A glide still frames the room left behind, so its neighbours keep running until the glide ends and settle runs again.
func test_rooms_kept_for_a_glide_run_until_the_next_settle() -> void:
	var rooms := _row(4)
	var residency := RoomResidency.new()
	residency.settle(rooms[1], rooms)
	_build_all(residency)
	residency.settle(rooms[2], rooms, RoomResidency.touching(rooms[1] as Room, rooms))
	_build_all(residency)
	assert_bool((rooms[0] as Room).is_active()).is_true()
	residency.settle(rooms[2], rooms)
	assert_bool((rooms[0] as Room).is_active()).is_false()
	await _flush()

func test_a_room_out_of_reach_idles() -> void:
	var rooms := _row(4)
	var residency := RoomResidency.new()
	residency.settle(rooms[0], rooms)
	_build_all(residency)
	residency.settle(rooms[2], rooms)
	_build_all(residency)
	assert_bool((rooms[0] as Room).is_active()).is_false()
	assert_object((rooms[0] as Room).contents()).is_not_null()
	await _flush()

func test_the_oldest_idle_room_is_evicted() -> void:
	var rooms := _row(8)
	var residency := RoomResidency.new()
	# Walk 0 -> 2 -> 4 -> 6: rooms 0..3 fall out of reach in turn; only MAX_IDLE_ROOMS of them stay loaded.
	for i: int in [0, 2, 4, 6]:
		residency.settle(rooms[i], rooms)
		_build_all(residency)
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
	_build_all(residency)
	var left := (rooms[1] as Room).contents()
	residency.settle(interior, rooms)
	assert_object((rooms[1] as Room).contents()).is_same(left)
	assert_bool((rooms[1] as Room).is_active()).is_false()
	await _flush()

func test_an_expired_room_still_in_reach_keeps_its_contents() -> void:
	var rooms := _row(3)
	var residency := RoomResidency.new()
	residency.settle(rooms[0], rooms)
	_build_all(residency)
	var before := (rooms[0] as Room).contents()
	(rooms[0] as Room).expire()
	residency.settle(rooms[1], rooms)
	_build_all(residency)
	assert_object((rooms[0] as Room).contents()).is_same(before)
	await _flush()

func test_wake_rebuilds_the_neighbours_and_keeps_the_current_room() -> void:
	var rooms := _row(3)
	var residency := RoomResidency.new()
	residency.settle(rooms[1], rooms)
	_build_all(residency)
	await _flush()
	var neighbour := (rooms[0] as Room).contents()
	var current := (rooms[1] as Room).contents()
	residency.wake(rooms[1], rooms)
	_build_all(residency)
	assert_object((rooms[0] as Room).contents()).is_not_same(neighbour)
	assert_bool((rooms[0] as Room).is_active()).is_true()
	assert_object((rooms[1] as Room).contents()).is_same(current)
	await _flush()
