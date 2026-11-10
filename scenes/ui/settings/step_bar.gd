class_name StepBar
extends Control
## Ten cells for a 0..10 value; redraws only when the value changes, so it needs no clock under a hold.

## Px of a cell, and px between cells.
const CELL := Vector2(8, 6)
const GAP := 3.0
const EMPTY_ALPHA := 0.3

var color: Color = Color(0.32, 0.2, 0.25, 1):
	set(value):
		color = value
		queue_redraw()

var _value: int = 0


func _draw() -> void:
	for i: int in SettingsMath.VOLUME_STEPS:
		var cell := Color(color, 1.0 if i < _value else EMPTY_ALPHA)
		draw_rect(Rect2(Vector2(i * (CELL.x + GAP), 0.0), CELL), cell)

func set_value(value: int) -> void:
	if value == _value:
		return
	_value = value
	queue_redraw()

func value() -> int:
	return _value

## The bar's width for ten cells, px.
static func width() -> float:
	return SettingsMath.VOLUME_STEPS * CELL.x + (SettingsMath.VOLUME_STEPS - 1) * GAP
