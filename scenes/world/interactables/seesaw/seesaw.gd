class_name Seesaw extends Node2D

## A plank on a pivot that leans toward the heavier side (design 02 section 8,
## Verao Espacial 2: with weight on one end, the other rises to a high ledge -
## the shadow holds the low end while Ivo climbs the other). The plank is an
## AnimatableBody2D, so whoever stands on it rides it; the WeightSensor riding
## the plank weighs everything on it by where it stands (SeesawBalance).

## How far the plank turns per unit of torque (px times Ivos), in degrees.
@export var degrees_per_torque := 0.35
@export var max_degrees := 24.0
## Degrees per second it turns toward where it settles.
@export var turn_speed := 60.0

@onready var _plank: AnimatableBody2D = $Plank
@onready var _sensor: WeightSensor = $Plank/Sensor

func _ready() -> void:
	_plank.sync_to_physics = true

func _physics_process(delta: float) -> void:
	var loads: Array[Vector2] = []
	for node: Node2D in _sensor.pressing():
		var along := _plank.to_local(node.global_position).x
		loads.append(Vector2(along, Weight.of(node).mass))
	var target := SeesawBalance.settle_angle(loads, degrees_per_torque, max_degrees)
	_plank.rotation = move_toward(_plank.rotation, target, deg_to_rad(turn_speed) * delta)
