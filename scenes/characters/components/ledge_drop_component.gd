class_name LedgeDropComponent
extends Node
## Drops the parent body through a droppable ledge of a room's Solid layer by teleporting its feet into the ledge
## (architecture/drop-through-ledges).

signal dropped(at: Vector2)

## Px the feet go into the ledge; must exceed the 5 px a one-way holds a resting body by and the body's safe_margin
## (gotchas/a-body-resting-on-a-one-way-cannot-be-pushed-down-into-it).
const DROP_DEPTH := 6.0
## Px past the contact point and below the feet, so a point lies in the floor cell.
const INSIDE_FLOOR := 1.0
## Px trimmed from each side of the body when finding the columns under it.
const FOOT_INSET := 0.5

## Downward speed the drop starts with, px/s, so the fall does not hang for its first frames.
@export var drop_speed := 90.0

## Feet px into the ledge; a test sets a smaller one to show the stall the teleport avoids.
var depth := DROP_DEPTH

@onready var _body: CharacterBody2D = get_parent()


## Drops when the body stands on a room's Solid layer over a ledge LedgeDrop allows; returns whether it dropped.
## Reads the floor from the last move_and_slide().
func try_drop() -> bool:
	if not _body.is_on_floor():
		return false
	var room := _floor_room()
	if room == null or room.map == null:
		return false
	var rect := Character.shape_rect(_body)
	if not rect.has_area():
		return false
	var feet_y := rect.end.y + INSIDE_FLOOR
	var first := room.cell_at(Vector2(rect.position.x + FOOT_INSET, feet_y))
	var last := room.cell_at(Vector2(rect.end.x - FOOT_INSET, feet_y))
	if not LedgeDrop.allows_at(room.map.drop_cell, first.x, last.x, first.y, rect.size.y):
		return false
	var at := _body.global_position
	Character.teleport_body(_body, at + Vector2(0.0, depth))
	_body.velocity.y = drop_speed
	dropped.emit(at)
	return true

func _floor_room() -> RoomMapNode:
	for i: int in _body.get_slide_collision_count():
		var collision := _body.get_slide_collision(i)
		if collision.get_angle(_body.up_direction) > _body.floor_max_angle + 0.01:
			continue
		var layer := collision.get_collider() as TileMapLayer
		if layer != null and layer.get_parent() is RoomMapNode:
			return layer.get_parent() as RoomMapNode
		return null
	return null
