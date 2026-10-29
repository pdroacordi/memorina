class_name MapExtrasTest extends GdUnitTestSuite

## A bought map names only its region's surface rooms; a rumour's mark stands inside a room of its piece's region, and
## marks sharing a place spread apart (systems/seeds-and-the-seller).

var _infos: Array[MapRoomInfo] = []


func before_test() -> void:
	_infos.clear()
	# An L of two lake rooms with void at the union's centre, an interior, and a woods room.
	_infos.append(MapRoomInfo.new(&"lake_a", "a", "REGION_LAKE", Rect2(0, 0, 1280, 384), false))
	_infos.append(MapRoomInfo.new(&"lake_b", "b", "REGION_LAKE", Rect2(0, 384, 640, 1152), false))
	_infos.append(MapRoomInfo.new(&"lake_hut", "c", "REGION_LAKE", Rect2(0, 12000, 640, 384), true))
	_infos.append(MapRoomInfo.new(&"woods_a", "d", "REGION_WOODS", Rect2(2000, 0, 640, 384), false))

func _piece(room: StringName) -> FoundPiece:
	var piece := FoundPiece.new()
	piece.room = room
	return piece

func test_known_rooms_are_the_surface_rooms_of_bought_regions() -> void:
	var known := MapExtras.known_rooms(_infos, PackedStringArray(["REGION_LAKE"]))
	var ids: Array[StringName] = []
	for info: MapRoomInfo in known:
		ids.append(info.room_id)
	assert_array(ids).contains_exactly([&"lake_a", &"lake_b"])
	assert_array(MapExtras.known_rooms(_infos, PackedStringArray())).is_empty()

## The union's centre (640, 768) is void; the mark moves into the nearest lake room, a cell from its edges.
func test_a_rumour_point_lies_inside_a_room_of_its_region() -> void:
	var pieces: Array[FoundPiece] = [_piece(&"lake_hut")]
	var points := MapExtras.rumour_points(_infos, pieces)
	assert_int(points.size()).is_equal(1)
	var inside := false
	for info: MapRoomInfo in _infos:
		if not info.interior and info.region_key == "REGION_LAKE" and info.bounds.grow(-63.0).has_point(points[0]):
			inside = true
	assert_bool(inside).is_true()

func test_a_piece_whose_room_is_not_known_has_no_point() -> void:
	var pieces: Array[FoundPiece] = [_piece(&"elsewhere")]
	assert_int(MapExtras.rumour_points(_infos, pieces).size()).is_equal(0)

func test_marks_in_one_region_step_apart() -> void:
	var pieces: Array[FoundPiece] = [_piece(&"lake_a"), _piece(&"woods_a"), _piece(&"lake_b")]
	var points := MapExtras.rumour_points(_infos, pieces)
	assert_object(points[0]).is_equal(points[2])
	var steps := MapExtras.steps(points)
	assert_float(steps[0]).is_equal(-0.5)
	assert_float(steps[1]).is_equal(0.0)
	assert_float(steps[2]).is_equal(0.5)

func test_a_mark_is_a_five_pixel_diamond() -> void:
	var rows := MapCanvas.diamond(Vector2i(10, 10))
	assert_int(rows.size()).is_equal(5)
	assert_object(rows[2]).is_equal(Rect2i(8, 10, 5, 1))
	assert_object(rows[0]).is_equal(Rect2i(10, 8, 1, 1))
