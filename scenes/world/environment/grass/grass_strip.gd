class_name GrassStrip
extends Node2D
## Draws one grass run's blades: a rect over the run for grass_blades.gdshader (architecture/generated-grass).

## The local rect the blades can reach: the run, blade height above it and a blade's lean past each end.
var area := Rect2()


func _draw() -> void:
	draw_rect(area, Color.WHITE)
