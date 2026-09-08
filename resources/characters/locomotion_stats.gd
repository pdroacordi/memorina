class_name LocomotionStats
extends Resource
## Tuning data for horizontal ground and air movement, so a new character with
## different handling is a new .tres asset rather than a new script or a scene
## full of property overrides.

@export var move_speed  : float = 96.0
@export var acceleration: float = 1024.0
@export var deceleration: float = 2048.0
## Multiplier applied to acceleration while airborne.
@export var air_control : float = 0.8
## Multiplier applied to deceleration while airborne.
@export var air_brakes  : float = 0.8
