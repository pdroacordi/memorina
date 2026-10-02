class_name LandingStats
extends Resource
## Tuning data for hard-landing detection and recovery.

## Downward speed threshold for a hard landing.
@export var hard_land_speed: float = 400.0
## Recovery duration in seconds after a hard landing.
@export var hard_land_time: float = 0.75
