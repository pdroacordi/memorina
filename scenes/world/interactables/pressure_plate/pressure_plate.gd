class_name PressurePlate extends Node2D

## Weight activates the plate (design 02 section 8); linked gates and lifts use room-map `trigger_path`.

signal activated
signal deactivated

## Required mass, in Ivos.
@export var required_mass := 1.0

var _active := false

@onready var _sensor: WeightSensor = $Sensor
@onready var _sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	_sensor.load_changed.connect(_on_load_changed)

func is_active() -> bool:
	return _active

func _on_load_changed(total: float) -> void:
	var active := total >= required_mass - 0.001
	if active == _active:
		return
	_active = active
	_sprite.frame = 1 if active else 0
	if active:
		activated.emit()
	else:
		deactivated.emit()
