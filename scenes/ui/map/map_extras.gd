class_name MapExtras
extends RefCounted
## What the map draws from purchases, never from `map_seen`: the rooms of a bought region and the rumour marks
## (systems/seeds-and-the-seller).


## The surface rooms of the regions in `regions`, in `infos` order.
static func known_rooms(infos: Array[MapRoomInfo], regions: PackedStringArray) -> Array[MapRoomInfo]:
	var known: Array[MapRoomInfo] = []
	for info: MapRoomInfo in infos:
		if not info.interior and regions.has(info.region_key):
			known.append(info)
	return known

## One world point per piece whose room is in `infos`: the centre of its region's surface rooms, moved into the nearest
## of them so a mark never stands in the void. Pieces of one region share the point; `steps` spreads them.
static func rumour_points(infos: Array[MapRoomInfo], pieces: Array[FoundPiece]) -> PackedVector2Array:
	var points := PackedVector2Array()
	for piece: FoundPiece in pieces:
		var region := _region_of(infos, piece.room)
		if region.is_empty():
			continue
		var rooms := known_rooms(infos, PackedStringArray([region]))
		if rooms.is_empty():
			continue
		points.append(_inside(rooms, _union(rooms).get_center()))
	return points

## Per point, its offset in mark steps along x: points that share a place spread evenly about it.
static func steps(points: PackedVector2Array) -> PackedFloat32Array:
	var offsets := PackedFloat32Array()
	offsets.resize(points.size())
	for i: int in points.size():
		var before := 0
		var total := 0
		for j: int in points.size():
			if points[j] == points[i]:
				total += 1
				if j < i:
					before += 1
		offsets[i] = before - (total - 1) * 0.5
	return offsets

static func _region_of(infos: Array[MapRoomInfo], room_id: StringName) -> String:
	for info: MapRoomInfo in infos:
		if info.room_id == room_id:
			return info.region_key
	return ""

static func _union(rooms: Array[MapRoomInfo]) -> Rect2:
	var union := rooms[0].bounds
	for info: MapRoomInfo in rooms:
		union = union.merge(info.bounds)
	return union

## `point` if a room holds it a cell from its edges, else the nearest such point of the nearest room.
static func _inside(rooms: Array[MapRoomInfo], point: Vector2) -> Vector2:
	var best := point
	var best_distance := INF
	for info: MapRoomInfo in rooms:
		var inner := info.bounds.grow(-MapGrid.CELL_PX)
		if not inner.has_area():
			inner = info.bounds
		var clamped := point.clamp(inner.position, inner.end)
		var distance := clamped.distance_squared_to(point)
		if distance < best_distance:
			best = clamped
			best_distance = distance
	return best
