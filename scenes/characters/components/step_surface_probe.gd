class_name StepSurfaceProbe
extends Node
## The surface under the parent body's feet, read from its floor collision; shallow water it wades in wins
## (systems/sound-effects).

## A floor body that is not a room's Solid layer and has no `step_surface` property sounds as this.
const DEFAULT_SURFACE := Enums.Surface.STONE
## The property a floor body (ice, a root bridge) may declare its Enums.Surface in.
const STEP_SURFACE := &"step_surface"

var _floor: Enums.Surface = Enums.Surface.NONE
# WaterVolumes with `wade` the body is inside; balanced because an Area2D reports a disabled or removed body as exited.
var _wading: int = 0

@onready var _body: CharacterBody2D = get_parent()


## The surface of `collider`, a floor the body touched through the body `rid`.
static func surface_of(collider: Object, rid: RID) -> Enums.Surface:
	var layer := collider as TileMapLayer
	if layer != null and layer.get_parent() is RoomMapNode:
		return (layer.get_parent() as RoomMapNode).surface_at(layer.get_coords_for_body_rid(rid))
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
			_floor = surface_of(collision.get_collider(), collision.get_collider_rid())
			return

func surface() -> Enums.Surface:
	return Enums.Surface.SHALLOW_WATER if _wading > 0 else _floor

func enter_wading() -> void:
	_wading += 1

func exit_wading() -> void:
	_wading = maxi(_wading - 1, 0)
