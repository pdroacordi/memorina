class_name WeatherShelter extends Node2D

## An authored lee (room map `l`): stills only the region's weather in a box standing on its cell, never a current or
## a song's gale (design 03 section 5.4.4; architecture/regional-weather-push).

const CELL := float(RoomMap.CELL_PX)

## Box width in cells, centred on the cell.
@export var width_cells: int = 3
## Box height in cells, rising from the cell's floor.
@export var height_cells: int = 3


func _ready() -> void:
	var wind := RegionWind.find_in(self)
	if wind != null:
		wind.register_shelter(self)

func _exit_tree() -> void:
	var wind := RegionWind.find_in(self)
	if wind != null:
		wind.unregister_shelter(self)

## The box in local px; the origin is the cell's bottom centre.
func rect() -> Rect2:
	var size := Vector2(width_cells, height_cells) * CELL
	return Rect2(Vector2(-size.x * 0.5, -size.y), size)

func covers(global_point: Vector2) -> bool:
	return rect().has_point(to_local(global_point))
