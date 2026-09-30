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

@export_group("Wind")
## Wind is a velocity the air carries (Airflow). In the air the body steers
## toward its input speed PLUS this fraction of the wind, so a tailwind
## carries a jump further and a headwind shortens it - bounded, never a
## runaway force.
@export var air_wind    : float = 1.0
## On the ground, feet grip: a wind slower than this (px/s) moves nothing, so
## a breeze never breaks a standing performance, and a gust past it slides the
## body at wind_grip of the excess (design 03 section 5.4: "a execucao so
## quebra quando a forca acumulada passa de um limiar").
@export var wind_deadzone: float = 90.0
@export var wind_grip   : float = 0.4
## Upward (or downward) wind as vertical acceleration per px/s of wind, while
## airborne.
@export var wind_lift   : float = 1.5
