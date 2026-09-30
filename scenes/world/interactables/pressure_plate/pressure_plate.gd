class_name PressurePlate extends Node2D

## A stone plate in the floor that holds something open while enough weight
## stands on it (design 02 section 8, Verao Espacial 1: "uma porta so fica
## aberta enquanto houver peso na placa"). Ivo is enough; so is his burned
## shadow, a released load or a crate. It knows nothing of what it opens: a
## gate or a lift links to it (room map param `trigger_path`) and listens.

signal activated
signal deactivated

## How much must stand on it, in Ivos.
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
