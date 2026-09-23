@tool
class_name WaterQuad extends Node2D

## A rectangle for a water shader to draw on. The surface and the veil are both
## one of these; the shader on the material decides what it looks like.
##
## Z IS THE WATER CONVENTION. Every body of water draws at the same absolute z,
## so the one automatic screen copy taken before the first of them serves all of
## them (docs/knowledge/gotchas/screen-texture-copy-scope.md). Anything the
## water should reflect draws below Z; anything that should cover the water
## draws above it.

const Z := 50

## Draws inside the creature pass instead of the world: the veil that tints a
## creature standing in the water.
@export var creature_layer := false

## Local rect to draw, set by the WaterBody.
var rect := Rect2():
	set(value):
		rect = value
		queue_redraw()

# z_index / z_as_relative are authored in the water scenes, not written here:
# a @tool write would resave them into every level that places water.
func _ready() -> void:
	assert(z_index == Z and not z_as_relative, "A WaterQuad must draw at absolute WaterQuad.Z")
	if creature_layer and not Engine.is_editor_hint():
		CreatureMask.join_layer(self)

func _draw() -> void:
	draw_rect(rect, Color.WHITE)
