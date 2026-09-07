extends Node2D

@onready var _camera : Camera2D = $World/Camera2D
@onready var _player : Node2D = $World/Ivo
@onready var _level  : Room = $World/Level

func _ready() -> void:
	_camera.set_bounds(_level.get_bounds())
	_camera.follow(_player)
