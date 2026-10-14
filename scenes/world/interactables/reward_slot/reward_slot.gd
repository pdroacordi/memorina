class_name RewardSlot
extends Node2D
## A place the layout promises a reward, filled later by slot_id (architecture/reward-slots-reserve-their-place-in-the-room-text).

## Append only: maps store the number.
enum Kind {
	## A STORY-06 collectible: a letter, a diary page, a photo.
	COLLECTIBLE,
	## A LIFE-04 cache, undecided until LIFE-04 is.
	CACHE,
}

const MARKER_COLOURS: Dictionary[Kind, Color] = {
	Kind.COLLECTIBLE: Color("#f2c84b"),
	Kind.CACHE: Color("#a0662f"),
}
## px, the marker's half width.
const MARKER_HALF := 6.0
## px above the floor to the marker's centre, clear of the grass.
const MARKER_LIFT := 22.0
## Over grass and ground; under a closed secret's world copy, which must hide it.
const MARKER_Z := RoomMapNode.SECRET_Z - 10

## Unique across every map; the filling system's catalog keys its content by it.
@export var slot_id: StringName
@export var kind: Kind = Kind.COLLECTIBLE


func _ready() -> void:
	z_index = MARKER_Z


func _draw() -> void:
	# Release builds draw nothing: a slot gives nothing until STORY-06 or LIFE-04 fills it.
	if not OS.is_debug_build():
		return
	var centre := Vector2(0.0, -MARKER_LIFT)
	var points := PackedVector2Array([
		centre + Vector2(0.0, -MARKER_HALF),
		centre + Vector2(MARKER_HALF, 0.0),
		centre + Vector2(0.0, MARKER_HALF),
		centre + Vector2(-MARKER_HALF, 0.0),
	])
	draw_colored_polygon(points, MARKER_COLOURS[kind])
	points.append(points[0])
	draw_polyline(points, Color.BLACK, 2.0)
