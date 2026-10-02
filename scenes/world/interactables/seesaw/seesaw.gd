class_name Seesaw extends Node2D

## The offset pivot lets the shadow on the long arm raise Ivo on the short arm; see design 02 section 8.

## Plank length, px (whole plank, both arms).
@export var length := 160.0
## Pivot position along the plank, 0 at left and 1 at right.
@export_range(0.05, 0.95) var pivot_at := 0.5

## Angular response per torque unit (px times Ivos), in degrees.
@export var degrees_per_torque := 0.35
@export var max_degrees := 24.0
## Degrees per second it turns toward where it settles.
@export var turn_speed := 60.0

# The loads on the plank this frame, reused.
var _loads: Array[Vector2] = []

@onready var _plank: AnimatableBody2D = $Plank
@onready var _plank_shape: CollisionShape2D = $Plank/CollisionShape2D
@onready var _plank_sprite: Sprite2D = $Plank/Sprite2D
@onready var _sensor: WeightSensor = $Plank/Sensor
@onready var _sensor_shape: CollisionShape2D = $Plank/Sensor/CollisionShape2D

func _ready() -> void:
	# It moves or goes away: never a place to be sent back to.
	_plank.add_to_group(SafeGroundTracker.UNSAFE)
	_plank.sync_to_physics = true
	# The plank's centre, from the pivot (the plank body's origin).
	var centre := (0.5 - pivot_at) * length
	for shape: CollisionShape2D in [_plank_shape, _sensor_shape]:
		var box := (shape.shape as RectangleShape2D).duplicate() as RectangleShape2D
		box.size.x = length
		shape.shape = box
		shape.position.x = centre
	# Keep the repeating art's dark middle band aligned with the pivot.
	var art := _plank_sprite.texture.get_size()
	_plank_sprite.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	_plank_sprite.region_enabled = true
	_plank_sprite.region_rect = Rect2(art.x * 0.5 - pivot_at * length, 0.0, length, art.y)
	_plank_sprite.position.x = centre

## The height of the plank's surface at its ends above the pivot, px, when
## tilted by `angle` (radians, positive = right side down): (left, right).
func end_rise(angle: float) -> Vector2:
	return Vector2(pivot_at * length * sin(angle), -(1.0 - pivot_at) * length * sin(angle))

## How far the plank's ends reach sideways from the pivot, px, at `angle`:
## (left, right), both positive.
func end_reach(angle: float) -> Vector2:
	return Vector2(pivot_at * length, (1.0 - pivot_at) * length) * cos(angle)

func _physics_process(delta: float) -> void:
	_loads.clear()
	for node: Node2D in _sensor.pressing():
		var along := _plank.to_local(node.global_position).x
		_loads.append(Vector2(along, Weight.of(node).mass))
	var target := SeesawBalance.settle_angle(_loads, degrees_per_torque, max_degrees)
	_plank.rotation = move_toward(_plank.rotation, target, deg_to_rad(turn_speed) * delta)
