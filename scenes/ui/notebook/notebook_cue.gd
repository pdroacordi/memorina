class_name NotebookCue
extends Control
## A small ink triangle in the page margin: more rows above (`up`) or below the list.

const INK := Color(0.32, 0.2, 0.25, 0.8)

@export var up: bool = false


func _draw() -> void:
	var w := size.x
	var h := size.y
	var points := PackedVector2Array([Vector2(0, h), Vector2(w, h), Vector2(w * 0.5, 0)]) if up \
			else PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w * 0.5, h)])
	draw_colored_polygon(points, INK)
