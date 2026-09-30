class_name Floater extends AnimatableBody2D

## Something that floats - a fallen log - riding the water under it (design 02
## section 8, Primavera Logico 2: Chuva fills the basin and the log rises with
## the water to a high passage). It lies where it was placed, on the basin's
## floor, until the water reaches it; then it sits `draft` px into the water and
## rides the waterline, waves and all, and sinks back to the floor as the water
## goes. A one-way platform on the Props layer, so Ivo jumps up through it and
## rides it up.
##
## It moves only up and down: the water does not carry it sideways.

## How deep its bottom sits below the waterline, px.
@export var draft := 4.0

var _rest_y := 0.0
# Where it is carried this frame. Kept here, not read back from the body: with
# sync_to_physics a moved transform only lands on the next physics step.
var _ride_y := 0.0
var _water: WaterBody
var _looked := false

func _ready() -> void:
	# It moves or goes away: never a place to be sent back to.
	add_to_group(SafeGroundTracker.UNSAFE)
	sync_to_physics = true
	_rest_y = global_position.y
	_ride_y = _rest_y

func _physics_process(_delta: float) -> void:
	# Looked up once, in the first physics frame: the water bodies of a room
	# are placed by their layers, which may come after this entity.
	if not _looked:
		_looked = true
		_water = WaterBody.at(self, global_position)
	_ride_y = _rest_y
	# Water a Redoma holds back is not under it: it rests on the bed.
	if _water and not _water.is_dry() and not _water.is_held_out(global_position.x):
		_ride_y = minf(_rest_y, roundf(_water.surface_y(global_position.x) + draft))
	global_position.y = _ride_y

## Whether the water has lifted it off where it rests.
func is_afloat() -> bool:
	return _ride_y < _rest_y

## The world y its bottom is carried to this frame.
func ride_y() -> float:
	return _ride_y
