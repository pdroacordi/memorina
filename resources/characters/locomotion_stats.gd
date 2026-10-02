class_name LocomotionStats
extends Resource
## Ground and air movement tuning for a character.

@export var move_speed  : float = 96.0
@export var acceleration: float = 1024.0
@export var deceleration: float = 2048.0
## Airborne acceleration multiplier.
@export var air_control : float = 0.8
## Airborne deceleration multiplier.
@export var air_brakes  : float = 0.8

@export_group("Wind")
## Fraction of wind velocity applied to airborne movement.
@export var air_wind    : float = 1.0
## Ground wind deadzone in px/s; see design 03 section 5.4.
@export var wind_deadzone: float = 90.0
@export var wind_grip   : float = 0.4
## Vertical acceleration per px/s of airborne wind.
@export var wind_lift   : float = 1.5
