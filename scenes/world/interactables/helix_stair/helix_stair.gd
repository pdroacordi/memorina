class_name HelixStair extends Node2D

## A helix stair, legend `@` (systems/helix-stair): its two ends and the view of the tower turning around its rider.

## The axis base: the `@` cell's bottom-left corner, half a cell left of the entity's origin.
const AXIS := Vector2(-RoomMap.CELL_PX * 0.5, 0.0)
## Px of an end zone. It overlaps the 12 px climb sensor up to 12 px from the end, so the rider boards only within its
## board_reach (bugs/boarding-a-helix-end-can-move-the-feet-twelve-px-in-one-frame).
const END_SIZE := Vector2(12.0, 48.0)
## Px of Ivo's capsule, the body the column check keeps clear of solid ground.
const BODY_RADIUS := 11.0
const BODY_HEIGHT := 54.0
## Px of the capsule the column check allows into a solid cell.
const SWEEP_GRAZE := 1.0
## Px of gallery the head needs on the hand side.
const LANDING_PX := 48.0
## Px the shell's inner faces may stand off the wall's silhouette.
const FACE_TOLERANCE := 2.0
## Px of view above the head when the stair stands in no room map.
const VIEW_ABOVE_HEAD := 64.0

## The numbers the path, the ends and the view come from.
@export var shape: HelixStairShape
## The colours and dimensions the view draws the tower in.
@export var look: HelixLook
## 1: the stair climbs toward the right at its front; -1 mirrors it.
@export_range(-1, 1, 2) var hand := 1

## Radians the tower is turned by: the rider's progress, 0 at the foot, head_u at the head.
var _angle := 0.0
var _view: HelixView


## Why the stair placed at `cell` with `params` cannot be ridden in `map`, as messages; empty when it can.
static func check(cell: Vector2i, params: Dictionary, map: RoomMap) -> PackedStringArray:
	var found := PackedStringArray()
	var stair_shape := _shape_of(params)
	if stair_shape == null:
		found.append("shape '%s' is not a HelixStairShape" % str(params.get("shape", "")))
		return found
	found.append_array(stair_shape.problems())
	var stair_hand := int(params.get("hand", 1))
	if stair_hand != 1 and stair_hand != -1:
		found.append("hand must be 1 or -1")
	if not found.is_empty():
		return found
	var base := Vector2(cell.x, cell.y + 1) * RoomMap.CELL_PX
	var head := base - Vector2(0.0, stair_shape.head_rise())
	if not (_ground_under(map, base + Vector2(-1.0, 0.0)) and _ground_under(map, base + Vector2(1.0, 0.0))):
		found.append("the foot at %s has no floor under it" % base)
	if not (_ground_under(map, head + Vector2(-1.0, 0.0)) and _ground_under(map, head + Vector2(1.0, 0.0))):
		found.append("the head at %s has no gallery under it" % head)
	var y := base.y
	while y >= head.y:
		if _body_meets_solid(map, Vector2(base.x, y)):
			found.append("the body meets solid ground at %s on the way up" % Vector2(base.x, y).round())
			break
		y -= 2.0
	var steps: Array = range(1, int(LANDING_PX), 4)
	steps.append(int(LANDING_PX))
	for step: int in steps:
		var at := head + Vector2(stair_hand * step, 0.0)
		if not _ground_under(map, at) or _body_meets_solid(map, at):
			found.append("the head at %s has no %d px of gallery on its hand side" % [head, int(LANDING_PX)])
			break
	found.append_array(_faces_problems(map, base, head, HelixProjection.silhouette(stair_shape)))
	return found

## The `shape` param's resource, or null.
static func _shape_of(params: Dictionary) -> HelixStairShape:
	var path := str(params.get("shape", ""))
	if path.begins_with("res://") and ResourceLoader.exists(path):
		return load(path) as HelixStairShape
	return null

## The shell's inner faces stand at the silhouette on every row from the floor up to the gallery.
static func _faces_problems(map: RoomMap, base: Vector2, head: Vector2, silhouette: float) -> PackedStringArray:
	var found := PackedStringArray()
	var axis_col := floori(base.x / RoomMap.CELL_PX)
	for row: int in range(floori(head.y / RoomMap.CELL_PX), floori(base.y / RoomMap.CELL_PX)):
		var left := axis_col - 1
		while left > map.origin.x and not map.is_solid(Vector2i(left, row)):
			left -= 1
		var right := axis_col
		while right < map.origin.x + map.size.x - 1 and not map.is_solid(Vector2i(right, row)):
			right += 1
		var left_face := (left + 1) * RoomMap.CELL_PX
		var right_face := right * RoomMap.CELL_PX
		if absf(left_face - (base.x - silhouette)) > FACE_TOLERANCE or absf(right_face - (base.x + silhouette)) > FACE_TOLERANCE:
			found.append("row %d: the shell's inner faces stand at %d and %d px, not at the silhouette %.1f px either side of the axis" % [row, left_face, right_face, silhouette])
			break
	return found

static func _ground_under(map: RoomMap, feet: Vector2) -> bool:
	return map.ground_at(Vector2i(((feet + Vector2(0.0, 1.0)) / RoomMap.CELL_PX).floor())) != Enums.Ground.NONE

## Whether the capsule standing on `feet` reaches more than SWEEP_GRAZE into a solid cell. One-way cells pass: upward by
## the sweep, downward by the rider's teleport (systems/helix-stair).
static func _body_meets_solid(map: RoomMap, feet: Vector2) -> bool:
	var top := feet.y - BODY_HEIGHT + BODY_RADIUS
	var bottom := feet.y - BODY_RADIUS
	var first := Vector2i(((Vector2(feet.x, top) - Vector2.ONE * BODY_RADIUS) / RoomMap.CELL_PX).floor())
	var last := Vector2i(((Vector2(feet.x, bottom) + Vector2.ONE * BODY_RADIUS) / RoomMap.CELL_PX).floor())
	for y: int in range(first.y, last.y + 1):
		for x: int in range(first.x, last.x + 1):
			if not map.is_solid(Vector2i(x, y)):
				continue
			var cell := Rect2(Vector2(x, y) * RoomMap.CELL_PX, Vector2.ONE * RoomMap.CELL_PX)
			var dx := maxf(maxf(cell.position.x - feet.x, feet.x - cell.end.x), 0.0)
			var dy := maxf(maxf(cell.position.y - bottom, top - cell.end.y), 0.0)
			if Vector2(dx, dy).length() < BODY_RADIUS - SWEEP_GRAZE:
				return true
	return false

func _ready() -> void:
	if shape == null or look == null:
		push_error("%s: a helix stair needs a shape and a look" % name)
		return
	add_child(_end(false))
	add_child(_end(true))
	var half := 2.0 * ceilf(HelixProjection.silhouette(shape) * 0.5)
	var top := _view_top()
	_view = HelixView.new()
	_view.name = "View"
	_view.setup(self, Vector2(-half, top), Vector2i(int(half * 2.0), int(-top)))
	add_child(_view)

func head_u() -> float:
	return HelixMath.head_u(shape)

## The axis height at progress `u`, world px.
func feet_global(u: float) -> Vector2:
	return to_global(AXIS + HelixMath.feet(shape, u))

## Where the feet stand at progress `u`, on a tread top, world px.
func stand_global(u: float) -> Vector2:
	return to_global(AXIS + HelixMath.stand(shape, u))

## Radians the tower is turned by.
func angle() -> float:
	return _angle

## The rider stands at progress `u`: the tower turns by it.
func set_rider_angle(u: float) -> void:
	_angle = u

## The rider left: the tower rests as he left it at an end, at the head on the gallery, else at the foot.
func clear_rider(at_head: bool) -> void:
	_angle = head_u() if at_head else 0.0

func view() -> HelixView:
	return _view

## The feet cells (map cells) for the reach audit: the floor beside the foot on the other side, the gallery beside the
## head on the hand side.
func reach_ends(cell: Vector2i) -> Array[Vector2i]:
	var base := Vector2(cell.x, cell.y + 1) * RoomMap.CELL_PX
	var foot := base + Vector2(-hand, -1.0)
	var head := base + Vector2(hand, -1.0 - shape.head_rise())
	return [Vector2i((foot / RoomMap.CELL_PX).floor()), Vector2i((head / RoomMap.CELL_PX).floor())]

## Px from the axis base up to the room map's top edge, or above the head without a room map.
func _view_top() -> float:
	var room_map := get_parent().get_parent() as RoomMapNode
	if room_map != null and room_map.map != null:
		return room_map.map.origin.y * RoomMap.CELL_PX - position.y - AXIS.y
	return -(shape.head_rise() + VIEW_ABOVE_HEAD)

func _end(at_head: bool) -> HelixEnd:
	var end := HelixEnd.new()
	end.name = "Head" if at_head else "Foot"
	end.stair = self
	end.at_head = at_head
	end.position = AXIS + HelixMath.feet(shape, head_u() if at_head else 0.0)
	var box := RectangleShape2D.new()
	box.size = END_SIZE
	var collision := CollisionShape2D.new()
	collision.shape = box
	collision.position = Vector2(0.0, -END_SIZE.y * 0.5)
	end.add_child(collision)
	return end
