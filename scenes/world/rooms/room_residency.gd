class_name RoomResidency
extends RefCounted
## Which rooms have contents: the current room and every room touching it run, a few recent ones idle (systems/rooms).

## Rooms kept loaded but idle besides the current room and its neighbours.
const MAX_IDLE_ROOMS := 2

## Loaded rooms, most recently near first.
var _resident: Array[Room] = []


## `room` and every room in `rooms` whose bounds share an edge or a corner with it.
static func touching(room: Room, rooms: Array[Node]) -> Array[Room]:
	var near: Array[Room] = [room]
	for node: Node in rooms:
		var other := node as Room
		if other != null and other != room and touches(room, other):
			near.append(other)
	return near

## Whether the bounds of `a` and `b` share an edge or a corner.
static func touches(a: Room, b: Room) -> bool:
	return a.get_bounds().grow(1.0).intersects(b.get_bounds())

## Runs `current` and its neighbours, so the ground across a seam exists; idles the rest and evicts the oldest.
func settle(current: Room, rooms: Array[Node]) -> void:
	var near := touching(current, rooms)
	for room: Room in near:
		# A running room keeps its contents even when expired: it rebuilds when it next comes back into reach.
		if not room.is_active():
			room.activate()
		_resident.erase(room)
		_resident.push_front(room)
	# Last, so the room Ivo stands in is the most recent: a door trip from it idles it rather than evicting it.
	_resident.erase(current)
	_resident.push_front(current)
	var idle := 0
	for room: Room in _resident.duplicate():
		if room in near:
			continue
		idle += 1
		if idle > MAX_IDLE_ROOMS:
			room.evict()
			_resident.erase(room)
		else:
			room.deactivate()

## After a rest: rebuilds every other room and expires `current`, so its dead return on its next visit, never under Ivo's feet.
func wake(current: Room, rooms: Array[Node]) -> void:
	for room: Room in _resident.duplicate():
		if room != current:
			room.evict()
			_resident.erase(room)
	current.expire()
	settle(current, rooms)
