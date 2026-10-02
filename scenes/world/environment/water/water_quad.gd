@tool
class_name WaterQuad extends Node2D

## Water draw rectangle; absolute z ordering shares the screen copy across water bodies (docs/knowledge/gotchas/screen-texture-copy-scope.md).

const Z := 50

## Draws this quad in the creature pass.
@export var creature_layer := false

## Local draw rectangle set by WaterBody.
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
