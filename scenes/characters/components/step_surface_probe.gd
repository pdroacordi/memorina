class_name StepSurfaceProbe
extends Node
## The surface under the parent body's feet, read from its floor collision; shallow water it wades in wins
## (systems/sound-effects).

## A floor body that is not a room's Solid layer and has no `step_surface` property sounds as this.
const DEFAULT_SURFACE := Enums.Surface.STONE
## The property a floor body (ice, a root bridge) may declare its Enums.Surface in.
const STEP_SURFACE := &"step_surface"
## px into the floor past the contact point, so the point lies in the touched cell.
const INSIDE_FLOOR := 1.0

var _floor: Enums.Surface = Enums.Surface.NONE
# WaterVolumes with `wade` the body is inside; balanced because an Area2D reports a disabled or removed body as exited.
var _wading: int = 0

@onready var _body: CharacterBody2D = get_parent()


## The surface of `collider` at `point`, a global point just inside the floor the body touched.
static func surface_of(collider: Object, point: Vector2) -> Enums.Surface:
	var layer := collider as TileMapLayer
	if layer != null and layer.get_parent() is RoomMapNode:
		var room := layer.get_parent() as RoomMapNode
		# Not get_coords_for_body_rid: it names a physics quadrant (gotchas/tilemaplayer-body-rid-names-a-physics-quadrant-not-a-cell).
		return room.surface_at(room.cell_at(point))
	if collider != null and STEP_SURFACE in collider:
		return collider.get(STEP_SURFACE) as Enums.Surface
	return DEFAULT_SURFACE

## Reads the floor from the last move_and_slide(); call after it. A frame with no floor contact keeps the last one.
func update() -> void:
	if not _body.is_on_floor():
		return
	for i: int in _body.get_slide_collision_count():
		var collision := _body.get_slide_collision(i)
		if collision.get_angle(_body.up_direction) <= _body.floor_max_angle + 0.01:
			_floor = surface_of(collision.get_collider(), collision.get_position() - collision.get_normal() * INSIDE_FLOOR)
			return

func surface() -> Enums.Surface:
	return Enums.Surface.SHALLOW_WATER if _wading > 0 else _floor

func enter_wading() -> void:
	_wading += 1

func exit_wading() -> void:
	_wading = maxi(_wading - 1, 0)
