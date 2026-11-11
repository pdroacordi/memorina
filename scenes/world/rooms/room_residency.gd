class_name RoomResidency
extends RefCounted
## Which rooms have contents: the current room and every room touching it run, a few recent ones idle (systems/rooms).
## A neighbour that must be built waits in a queue and is built one per frame, or at once when the view or Ivo reaches it.

## Rooms kept loaded but idle besides the current room and its neighbours.
const MAX_IDLE_ROOMS := 2
## Rooms built per frame besides the due ones: one build is 4-6 ms (performance/2026-11-11-tech12-baseline).
const BUILDS_PER_FRAME := 1
## World px around Ivo's body within which a waiting room's ground must exist: a fall's steps over a slow frame.
const BODY_MARGIN := 128.0

## Loaded rooms, most recently near first.
var _resident: Array[Room] = []
## Neighbours that run once built, in the order settle found them.
var _waiting: Array[Room] = []


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

## Whether rects `a` and `b` share a stretch of edge, not only a corner.
static func share_an_edge(a: Rect2, b: Rect2) -> bool:
	var shared := a.grow(1.0).intersection(b)
	return maxf(shared.size.x, shared.size.y) > 1.0

## Which waiting rooms to build this frame, by index: every one whose `shown` cells meet `view` or whose `bounds` lie within
## BODY_MARGIN of `body` (none without area), then the nearest to `view` up to `extra` more. Behind a full black (`covered`)
## only those `extra`: nothing shows, and the arrival drains the queue before it fades in.
static func due(bounds: Array[Rect2], shown: Array, view: Rect2, body: Rect2, covered: bool,
		extra: int = BUILDS_PER_FRAME) -> PackedInt32Array:
	var picked := PackedInt32Array()
	if not covered:
		var reach := body.grow(BODY_MARGIN)
		for i: int in bounds.size():
			var cells: Array = shown[i]
			if (body.has_area() and reach.intersects(bounds[i])) or cells.any(func(cell: Rect2) -> bool: return view.intersects(cell)):
				picked.append(i)
	var added := 0
	while added < extra and picked.size() < bounds.size():
		var nearest := -1
		var nearest_gap := INF
		for i: int in bounds.size():
			var gap := _gap(view, bounds[i])
			if not i in picked and gap < nearest_gap:
				nearest = i
				nearest_gap = gap
		picked.append(nearest)
		added += 1
	return picked

# World px between two rects along the farther axis, 0 when they meet.
static func _gap(a: Rect2, b: Rect2) -> float:
	var dx := maxf(a.position.x - b.end.x, b.position.x - a.end.x)
	var dy := maxf(a.position.y - b.end.y, b.position.y - a.end.y)
	return maxf(maxf(dx, dy), 0.0)

## Runs `current` and its neighbours, so the ground across a seam exists; idles the rest and evicts the oldest. Rooms in
## `keep` run too: a glide still frames the ring of the room it left, which they draw (systems/rooms, Glides). The
## current room and idle neighbours run at once; a neighbour to build waits for `build_due`.
func settle(current: Room, rooms: Array[Node], keep: Array[Room] = []) -> void:
	var near := touching(current, rooms)
	for room: Room in keep:
		if not room in near:
			near.append(room)
	for room: Room in near:
		# A running room keeps its contents even when expired: it rebuilds when it next comes back into reach.
		if not room.is_active():
			if room == current or room.is_cached():
				_waiting.erase(room)
				room.activate()
			elif not room in _waiting:
				_waiting.append(room)
		_resident.erase(room)
		_resident.push_front(room)
	for room: Room in _waiting.duplicate():
		if not room in near:
			_waiting.erase(room)
			if room.contents() == null:
				_resident.erase(room)
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

## Builds the waiting rooms `due` picks for this frame's `view` and Ivo's `body`. Call after the camera's step and before
## the frame draws: a build's deferred add lands in this frame. In the frame a room was `entered`, only the due ones: that
## frame already pays for the swap (performance/2026-11-11-tech12-baseline, "After the fixes").
func build_due(view: Rect2, body: Rect2, covered: bool, entered: bool = false) -> void:
	if _waiting.is_empty():
		return
	var bounds: Array[Rect2] = []
	var shown: Array = []
	for room: Room in _waiting:
		bounds.append(room.get_bounds())
		shown.append(room.shown_cells())
	var built: Array[Room] = []
	for i: int in due(bounds, shown, view, body, covered, 0 if entered else BUILDS_PER_FRAME):
		built.append(_waiting[i])
	for room: Room in built:
		_waiting.erase(room)
		room.activate()

## Whether a neighbour still waits to be built.
func is_waiting() -> bool:
	return not _waiting.is_empty()

## After a rest: rebuilds every other room and expires `current`, so its dead return on its next visit, never under Ivo's feet.
func wake(current: Room, rooms: Array[Node]) -> void:
	for room: Room in _resident.duplicate():
		if room != current:
			room.evict()
			_resident.erase(room)
	_waiting.clear()
	current.expire()
	settle(current, rooms)
