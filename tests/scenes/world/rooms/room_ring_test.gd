class_name RoomRingTest extends GdUnitTestSuite

## The camera yields at most RoomRing.WIDTH px past the current room, and every pixel it can show there has exactly one
## resident owner (systems/rooms "Room ring", bugs/the-drawn-frame-correction-flips-between-candidates-and-drops-ivo-out-of-frame).

const IVO := "res://scenes/characters/ivo/ivo.tscn"
const GAME := "res://scenes/world/game.tscn"
const REGION_SCRIPT := preload("res://scenes/world/rooms/region.gd")
const DEBUG_TRIALS := preload("res://scenes/world/debug/debug_trials.gd")
## "<room> <column>,<row>" of a run's left feet cell in its `.room` file -> why a full jump from it may leave the frame.
const NEAR_TOP := {
	"village_lane_west 1,1": "The gatehouse roof: a double jump's optional perch over the west fence.",
	"lighthouse_top 1,1": "The lantern's roof over the arena: unreachable, the room's floor is 20 rows below it.",
}
## The 640x360 view at zoom 1.
const VIEW := Vector2(640, 360)
## Ivo's 22x54 body grown by the camera's 8 px margin.
const TOUCH := Vector2(38, 70)
## Px the body moves per sweep step.
const STEP := 2.0
## Px between owner samples in a frame.
const SAMPLE := 32.0

var _loaded: ReachWorldLoader.Loaded
var _bounds: Array[Rect2] = []
var _regions: Array[String] = []
## Whether each room is a song trial's, mounted by DebugTrials.
var _trials: Array[bool] = []


func before() -> void:
	_loaded = ReachWorldLoader.load_world()
	_load_rooms()

## A full jump from FLOOR_ROWS under an open top keeps Ivo's body and the camera's margin inside the ring.
func test_the_ring_holds_a_full_jump_from_floor_rows_down() -> void:
	var ivo := (load(IVO) as PackedScene).instantiate()
	var height := ((ivo.get_node("CollisionShape2D") as CollisionShape2D).shape as CapsuleShape2D).height
	ivo.free()
	var camera := GameCamera.new()
	var margin := camera.subject_margin
	camera.free()
	var top := RoomRing.FLOOR_ROWS * RoomMap.CELL_PX - MapGuide.ivo_reach().peak() - height - margin
	assert_float(top).is_greater_equal(-RoomRing.WIDTH)

## Two world rooms that do not touch are more than two rings apart, so the nearest room to any pixel in a room's ring is
## that room or one it touches: resident whenever the room is current. The song trials are exempt: DebugTrials sets their
## regions 2400 px apart, leaving 32 px (autumn to spring) and 256 px (the catch to the door trial) between rooms; each room
## judges ownership only among the rooms it touches, so the sweeps below, which include the trials, still find one resident
## owner for every pixel.
func test_rooms_that_do_not_touch_are_two_rings_apart() -> void:
	var close: Array[String] = []
	for i: int in _bounds.size():
		for j: int in range(i + 1, _bounds.size()):
			var a := _bounds[i]
			var b := _bounds[j]
			if _trials[i] or _trials[j]:
				continue
			if not a.grow(1.0).intersects(b) and a.grow(RoomRing.WIDTH * 2.0).intersects(b):
				close.append("%s and %s" % [a, b])
	assert_array(close).is_empty()

func test_every_floor_nearer_an_open_top_is_listed() -> void:
	var found := _near_top_floors()
	var unlisted: Array[String] = []
	for key: String in found:
		if not NEAR_TOP.has(key):
			unlisted.append(key)
	assert_array(unlisted) \
		.override_failure_message("Floors fewer than %d rows under an open top; lower them or list why no route jumps from them:\n%s" \
			% [RoomRing.FLOOR_ROWS, "\n".join(unlisted)]) \
		.is_empty()

func test_no_listed_floor_is_stale() -> void:
	var found := _near_top_floors()
	var stale: Array[String] = []
	for key: String in NEAR_TOP:
		if not key in found:
			stale.append(key)
	assert_array(stale).is_empty()

## Every room as the current one, the body swept STEP px at a time along lines across its edges and over its top: the frame
## moves no more than the body did, holds the body wherever it is inside the ring, and stays inside the ring; sampled
## frames have exactly one resident owner per pixel.
func test_a_body_swept_around_every_room_stays_in_a_drawn_frame() -> void:
	var failures: Array[String] = []
	for i: int in _bounds.size():
		var room := _bounds[i]
		var reach := RoomRing.reach(room)
		for line: PackedVector2Array in _lines(room):
			var last := Rect2()
			var last_body := Vector2.INF
			var steps := 0
			for body: Vector2 in _sweep(line[0], line[1]):
				var touch := Rect2(body - TOUCH * 0.5, TOUCH)
				var frame := _frame(room, touch)
				if last_body != Vector2.INF:
					var moved := frame.position.distance_to(last.position)
					if moved > body.distance_to(last_body) + 0.5:
						failures.append("%s: frame jumped %.1f px for a %.1f px move at %s" % [room, moved, body.distance_to(last_body), body])
				if reach.encloses(touch) and not frame.grow(0.01).encloses(touch):
					failures.append("%s: body at %s inside the ring but cut by the frame %s" % [room, body, frame])
				if not reach.grow(0.01).encloses(frame):
					failures.append("%s: frame %s leaves the ring" % [room, frame])
				if steps % 48 == 0:
					var hole := _unowned(i, frame)
					if hole != "":
						failures.append("%s: frame %s %s" % [room, frame, hole])
				last = frame
				last_body = body
				steps += 1
				if failures.size() > 20:
					break
	assert_array(failures).is_empty()

## A walk across a seam between two rooms of one region glides the frame from the old clamp to the new: every frame of
## the glide has exactly one resident owner per pixel. The left room's neighbours run until the glide ends (Game).
func test_a_glide_between_touching_rooms_shows_no_void() -> void:
	var failures: Array[String] = []
	for i: int in _bounds.size():
		for j: int in _bounds.size():
			if i == j or _regions[i] != _regions[j] or not RoomResidency.share_an_edge(_bounds[i], _bounds[j]):
				continue
			for body: Vector2 in _seam_points(_bounds[i], _bounds[j]):
				var touch := Rect2(body - TOUCH * 0.5, TOUCH)
				var from := _frame(_bounds[i], touch)
				var to := _frame(_bounds[j], touch)
				var order := RoomRing.glide_order(from, to, RoomRing.reach(_bounds[i]), RoomRing.reach(_bounds[j]))
				for weight: float in [0.9, 0.75, 0.5, 0.25, 0.1]:
					var frame := Rect2(to.position + RoomRing.glide_offset(from.position - to.position, weight, order), VIEW)
					var hole := _unowned(j, frame, i)
					if hole != "":
						failures.append("glide %s -> %s at %s, weight %.2f: %s" % [_bounds[i], _bounds[j], body, weight, hole])
	assert_array(failures).is_empty()

## bugs/a-glide-skips-the-drawn-frame-correction-and-snaps-when-it-ends: each leg of an ordered glide eases over its own
## half, so no frame of it steps further than an ease-out over that half allows, and a leg's axis rests while the other moves.
func test_an_ordered_glide_eases_each_leg_over_its_half() -> void:
	var from := Vector2(300.0, -200.0)
	var frames := 27
	for order: RoomRing.GlideOrder in [RoomRing.GlideOrder.TOGETHER, RoomRing.GlideOrder.X_FIRST, RoomRing.GlideOrder.Y_FIRST]:
		var share := float(frames) if order == RoomRing.GlideOrder.TOGETHER else frames * 0.5
		var last := from
		for k: int in range(1, frames + 1):
			var now := RoomRing.glide_offset(from, 1.0 - float(k) / frames, order)
			var step := (now - last).abs()
			# A cubic ease-out moves at most 3x its average speed.
			assert_float(step.x).is_less_equal(3.0 * absf(from.x) / share + 0.01)
			assert_float(step.y).is_less_equal(3.0 * absf(from.y) / share + 0.01)
			if order == RoomRing.GlideOrder.X_FIRST and k <= frames / 2:
				assert_float(now.y).is_equal(from.y)
			if order == RoomRing.GlideOrder.Y_FIRST and k <= frames / 2:
				assert_float(now.x).is_equal(from.x)
			last = now
		assert_vector(last).is_equal(Vector2.ZERO)

# GameCamera's frame with no look-ahead, lead or glide: clamped to the room, then yielded within its ring to hold `touch`.
func _frame(room: Rect2, touch: Rect2) -> Rect2:
	var half := VIEW * 0.5
	var reach := RoomRing.reach(room)
	var clamped := touch.get_center().clamp(room.position + half, room.end - half)
	var kept := clamped.clamp(touch.end - half, touch.position + half)
	var centre := kept.clamp(reach.position + half, reach.end - half)
	return Rect2(centre - half, VIEW)

# "" when every sampled pixel of `frame` has exactly one owner among the current room `current` and the rooms touching
# it (and, in a glide, the room `left` and its neighbours), each judging by BackdropMath.keeps with its own touching rooms;
# else the first bad pixel.
func _unowned(current: int, frame: Rect2, left: int = -1) -> String:
	var resident: Array[int] = [current]
	for k: int in _bounds.size():
		if k == current or resident.has(k):
			continue
		if _bounds[current].grow(1.0).intersects(_bounds[k]) or (left >= 0 and _bounds[left].grow(1.0).intersects(_bounds[k])):
			resident.append(k)
	var neighbours: Dictionary[int, Array] = {}
	for k: int in resident:
		var list: Array[Rect2] = []
		for other: int in _bounds.size():
			if other != k and _bounds[k].grow(1.0).intersects(_bounds[other]):
				list.append(_bounds[other])
		neighbours[k] = list
	for y: float in _samples(frame.position.y, frame.end.y):
		for x: float in _samples(frame.position.x, frame.end.x):
			var point := Vector2(x, y)
			var owners := 0
			for k: int in resident:
				var list: Array[Rect2] = neighbours[k]
				if BackdropMath.keeps(point, _bounds[k], list, RoomRing.WIDTH):
					owners += 1
			if owners != 1:
				return "has %d owners at %s" % [owners, point]
	return ""

# Lines across the room's four edges and over its top.
func _lines(room: Rect2) -> Array[PackedVector2Array]:
	var w := RoomRing.WIDTH
	var lines: Array[PackedVector2Array] = []
	for y: float in [room.position.y - w + 40.0, room.position.y - 40.0, room.position.y + 30.0, room.end.y - 30.0, room.end.y + 40.0]:
		lines.append(PackedVector2Array([Vector2(room.position.x - w, y), Vector2(room.end.x + w, y)]))
	for x: float in [room.position.x - 40.0, room.position.x + 20.0, room.end.x - 20.0, room.end.x + 40.0]:
		lines.append(PackedVector2Array([Vector2(x, room.position.y - w), Vector2(x, room.end.y + w)]))
	return lines

func _sweep(from: Vector2, to: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	var count := ceili(from.distance_to(to) / STEP)
	for k: int in count + 1:
		points.append(from.lerp(to, float(k) / float(count)))
	return points

# Points along the shared edge of `a` and `b`, a little on `b`'s side, every 64 px.
func _seam_points(a: Rect2, b: Rect2) -> PackedVector2Array:
	var points := PackedVector2Array()
	var shared := a.grow(1.0).intersection(b)
	var inward := b.get_center() - a.get_center()
	var nudge := Vector2(signf(inward.x) * 12.0 if shared.size.x <= 1.0 else 0.0, signf(inward.y) * 12.0 if shared.size.y <= 1.0 else 0.0)
	var along := shared.size.x > shared.size.y
	var length := shared.size.x if along else shared.size.y
	var at := 0.0
	while at <= length:
		var point := shared.position + (Vector2(at, 0.0) if along else Vector2(0.0, at))
		points.append(point + nudge)
		at += 64.0
	return points

# Pixel centres (whole px + 0.5, where the GPU samples) every SAMPLE px from `from` to `to`.
func _samples(from: float, to: float) -> Array[float]:
	var at: Array[float] = []
	var value := ceilf(from) + 0.5
	while value < to - 0.5:
		at.append(value)
		value += SAMPLE
	at.append(floorf(to - 0.5) + 0.5)
	return at

# Every room game.tscn places, and the song trials DebugTrials mounts in debug builds: its bounds and its region.
func _load_rooms() -> void:
	var state := (load(GAME) as PackedScene).get_state()
	for i: int in state.get_node_count():
		if _property(state, i, &"script") == DEBUG_TRIALS:
			_load_trials(state, i)
		var scene := state.get_node_instance(i)
		if scene == null or scene.get_state().get_node_count() == 0 or _property(scene.get_state(), 0, &"script") != REGION_SCRIPT:
			continue
		_add_region(scene, _property(state, i, &"position", _property(scene.get_state(), 0, &"position", Vector2.ZERO)))

func _load_trials(state: SceneState, node: int) -> void:
	var trials := DEBUG_TRIALS.new() as DebugTrials
	var regions: Array = _property(state, node, &"regions", trials.regions)
	var origin: Vector2 = _property(state, node, &"origin", trials.origin)
	var spacing: Vector2 = _property(state, node, &"spacing", trials.spacing)
	trials.free()
	for k: int in regions.size():
		_add_region(regions[k] as PackedScene, origin + spacing * k, true)

func _add_region(scene: PackedScene, at: Vector2, trial: bool = false) -> void:
	var region := scene.instantiate() as Node2D
	for child: Node in region.get_children():
		if child is Room:
			var room := child as Room
			var shape := room.get_node("CollisionShape2D") as CollisionShape2D
			var size := (shape.shape as RectangleShape2D).size
			_bounds.append(Rect2(at + room.position + shape.position - size * 0.5, size))
			_regions.append(scene.resource_path)
			_trials.append(trial)
	region.free()

func _property(state: SceneState, node: int, property: StringName, fallback: Variant = null) -> Variant:
	for j: int in state.get_node_property_count(node):
		if state.get_node_property_name(node, j) == property:
			return state.get_node_property_value(node, j)
	return fallback

# "<room> <column>,<row>" per run of standable cells in rows 1..FLOOR_ROWS-1 under columns no room lies above. Row 0 is a
# wall's top, reached only from above the room.
func _near_top_floors() -> Array[String]:
	var grid := _loaded.grid
	var keys: Array[String] = []
	for i: int in grid.room_count():
		var cells := grid.room_rect(i)
		for row: int in range(1, RoomRing.FLOOR_ROWS):
			var run := -1
			for column: int in cells.size.x + 1:
				var cell := cells.position + Vector2i(column, row)
				var standable := column < cells.size.x and grid.room_at(Vector2i(cell.x, cells.position.y - 1)) < 0 \
					and _open_floor(grid, cell, cells.position.y)
				if standable and run < 0:
					run = column
				elif not standable and run >= 0:
					keys.append("%s %d,%d" % [grid.room_id(i), run, row])
					run = -1
	return keys

func _open_floor(grid: ReachGrid, cell: Vector2i, top: int) -> bool:
	if (grid.flags(cell) & (ReachGrid.SOLID | ReachGrid.ONE_WAY)) == 0:
		return false
	for y: int in range(top, cell.y):
		if grid.flags(Vector2i(cell.x, y)) & ReachGrid.SOLID:
			return false
	return true
