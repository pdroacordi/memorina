class_name BackdropClipTest extends GdUnitTestSuite

## Every pixel a room's backdrop keeps lies in its drawn cells, in every room the game and DebugTrials place, so a layer
## clipped to them draws exactly the pixels it drew unclipped (systems/backdrops, "Clipped quads").

var _rooms: Array[Dictionary] = []


func before() -> void:
	_rooms = WorldRoomsFixture.rooms()

## Pixel centres at both ends and the middle of every stretch between two room edges or ring lines: a hold changes only
## on those lines, so these reach every cell of the grid drawn_cells walks.
func _samples(own: Rect2, rects: Array[Rect2], axis: int) -> PackedFloat64Array:
	var low := own.position[axis] - RoomRing.WIDTH - 2.0
	var high := own.end[axis] + RoomRing.WIDTH + 2.0
	var lines: Array[float] = [low, high]
	for rect: Rect2 in rects:
		for line: float in [rect.position[axis], rect.end[axis], rect.position[axis] - RoomRing.WIDTH, rect.end[axis] + RoomRing.WIDTH]:
			if line > low and line < high:
				lines.append(line)
	lines.sort()
	var at := PackedFloat64Array()
	for i: int in lines.size() - 1:
		if lines[i + 1] - lines[i] < 1.0:
			continue
		at.append(floorf(lines[i]) + 0.5)
		at.append(floorf((lines[i] + lines[i + 1]) * 0.5) + 0.5)
		at.append(ceilf(lines[i + 1]) - 0.5)
	return at

func test_drawn_cells_hold_every_pixel_each_world_room_keeps() -> void:
	assert_int(_rooms.size()).is_greater(50)
	var misses := PackedStringArray()
	var checked := 0
	for room: Dictionary in _rooms:
		var own: Rect2 = room.bounds
		var near := WorldRoomsFixture.neighbours(own, _rooms)
		var all: Array[Rect2] = [own]
		all.append_array(near)
		var whole := BackdropMath.drawn_cells(own, near, RoomRing.WIDTH, 0)
		var under := BackdropMath.drawn_cells(own, near, RoomRing.WIDTH, 1)
		var over := BackdropMath.drawn_cells(own, near, RoomRing.WIDTH, 2)
		for y: float in _samples(own, all, 1):
			for x: float in _samples(own, all, 0):
				var p := Vector2(x, y)
				if not BackdropMath.keeps(p, own, near, RoomRing.WIDTH):
					continue
				checked += 1
				var part := over if BackdropMath.over_top(p, own) else under
				if not _holds(whole, p) or not _holds(part, p):
					misses.append("%s keeps %s outside its cells" % [room.id, p])
	assert_int(checked).is_greater(10000)
	assert_array(misses).is_empty()

## A room never draws inside a neighbour, so its cells never reach into one.
func test_drawn_cells_stay_out_of_every_neighbour() -> void:
	var misses := PackedStringArray()
	for room: Dictionary in _rooms:
		var own: Rect2 = room.bounds
		var near := WorldRoomsFixture.neighbours(own, _rooms)
		for cell: Rect2 in BackdropMath.drawn_cells(own, near, RoomRing.WIDTH):
			for other: Rect2 in near:
				if cell.intersects(other):
					misses.append("%s: cell %s inside neighbour %s" % [room.id, cell, other])
	assert_array(misses).is_empty()

func _holds(cells: Array[Rect2], point: Vector2) -> bool:
	for cell: Rect2 in cells:
		if cell.has_point(point):
			return true
	return false
