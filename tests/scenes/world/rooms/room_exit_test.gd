class_name RoomExitTest extends GdUnitTestSuite

## Sideways a body leaves once it is out; up or down only past SEAM_MARGIN, or standing.

const ROOM := Rect2(0, 0, 640, 384)
const BODY := Vector2(16, 48)


func _body_at(feet: Vector2) -> Rect2:
	return Rect2(feet - Vector2(BODY.x * 0.5, BODY.y), BODY)

func test_a_body_inside_has_not_left() -> void:
	assert_bool(RoomExit.has_left(ROOM, _body_at(Vector2(320, 200)), false)).is_false()

func test_a_body_astride_an_edge_has_not_left() -> void:
	assert_bool(RoomExit.has_left(ROOM, _body_at(Vector2(320, 20)), false)).is_false()

func test_sideways_it_leaves_once_out() -> void:
	assert_bool(RoomExit.has_left(ROOM, _body_at(Vector2(649, 200)), false)).is_true()

## bugs/a-hop-from-a-floor-just-below-a-seam-swaps-the-room-up-and-back.
func test_a_hop_just_over_the_top_edge_stays() -> void:
	assert_bool(RoomExit.has_left(ROOM, _body_at(Vector2(320, -10)), false)).is_false()

func test_past_the_margin_it_leaves() -> void:
	assert_bool(RoomExit.has_left(ROOM, _body_at(Vector2(320, -RoomExit.SEAM_MARGIN)), false)).is_true()

func test_standing_over_the_edge_it_leaves() -> void:
	assert_bool(RoomExit.has_left(ROOM, _body_at(Vector2(320, 0)), true)).is_true()

func test_falling_below_it_leaves_past_the_margin() -> void:
	assert_bool(RoomExit.has_left(ROOM, _body_at(Vector2(320, 384 + 48 + 10)), false)).is_false()
	assert_bool(RoomExit.has_left(ROOM, _body_at(Vector2(320, 384 + 48 + RoomExit.SEAM_MARGIN)), false)).is_true()

## bugs/the-safety-net-fires-when-ivo-drops-across-a-seam-above-two-open-tops.
func test_above_an_open_top_he_is_not_lost() -> void:
	var near: Array[Rect2] = [ROOM]
	assert_bool(RoomExit.is_lost(_body_at(Vector2(320, -100)), near)).is_false()

func test_falling_into_a_neighbour_column_he_is_not_lost() -> void:
	var neighbour := Rect2(-640, 0, 640, 384)
	var near: Array[Rect2] = [ROOM, neighbour]
	# Sideways out of ROOM, centre above the neighbour's open top, feet below it.
	assert_bool(RoomExit.is_lost(_body_at(Vector2(-20, 10)), near)).is_false()

func test_beside_every_room_he_is_lost() -> void:
	var near: Array[Rect2] = [ROOM]
	assert_bool(RoomExit.is_lost(_body_at(Vector2(700, 200)), near)).is_true()

func test_below_every_room_he_is_lost() -> void:
	var near: Array[Rect2] = [ROOM]
	assert_bool(RoomExit.is_lost(_body_at(Vector2(320, 384 + 200)), near)).is_true()
