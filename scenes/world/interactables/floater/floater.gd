class_name Floater extends AnimatableBody2D

## A one-way platform that rises with water (design 02 section 8); it moves vertically only.

## How deep its bottom sits below the waterline, px.
@export var draft := 4.0

var _rest_y := 0.0
# Store the intended position because sync_to_physics applies transform changes on the next physics step.
var _ride_y := 0.0
var _water: WaterBody
var _looked := false

func _ready() -> void:
	# A moving or removed floater is not a valid return position.
	add_to_group(SafeGroundTracker.UNSAFE)
	sync_to_physics = true
	_rest_y = global_position.y
	_ride_y = _rest_y

func _physics_process(_delta: float) -> void:
	# Resolve water in the first physics frame because its layer may be placed after this entity.
	if not _looked:
		_looked = true
		_water = WaterBody.at(self, global_position)
	_ride_y = _rest_y
	# Water held back by Redoma does not support the floater.
	if _water and not _water.is_dry() and not _water.is_held_out(global_position.x):
		_ride_y = minf(_rest_y, roundf(_water.surface_y(global_position.x) + draft))
	global_position.y = _ride_y

## Whether the water has lifted it off where it rests.
func is_afloat() -> bool:
	return _ride_y < _rest_y

## The world y its bottom is carried to this frame.
func ride_y() -> float:
	return _ride_y
