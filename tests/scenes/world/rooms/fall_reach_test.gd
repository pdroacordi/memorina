class_name FallReachTest extends GdUnitTestSuite

## The frame yields below a fall only into rooms that span its whole width.

const ROOM := Rect2(0, 0, 1280, 384)
## Under the frame, below ROOM's floor seam.
const STRIP := Rect2(300, 384, 640, 96)


func test_a_wide_room_below_is_reached() -> void:
	var rooms: Array[Rect2] = [Rect2(0, 384, 1280, 384)]
	assert_that(FallReach.of(STRIP, rooms)).is_equal(Rect2(0, 384, 1280, 384))

func test_two_rooms_below_side_by_side_are_reached() -> void:
	var rooms: Array[Rect2] = [Rect2(0, 384, 640, 384), Rect2(640, 384, 640, 384)]
	assert_that(FallReach.of(STRIP, rooms)).is_equal(Rect2(0, 384, 1280, 384))

## bugs/the-fall-lead-shows-the-void-beside-a-narrower-room-below: a well shaft under part of the frame.
func test_a_narrower_room_below_is_not_reached() -> void:
	var rooms: Array[Rect2] = [Rect2(640, 384, 640, 384)]
	assert_that(FallReach.of(STRIP, rooms)).is_equal(Rect2())

func test_a_narrower_room_below_on_the_left_is_not_reached() -> void:
	var rooms: Array[Rect2] = [Rect2(0, 384, 640, 384)]
	assert_that(FallReach.of(STRIP, rooms)).is_equal(Rect2())

func test_with_no_room_below_nothing_is_reached() -> void:
	var rooms: Array[Rect2] = [ROOM]
	assert_that(FallReach.of(STRIP, rooms)).is_equal(Rect2())
