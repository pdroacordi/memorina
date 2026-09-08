class_name LandingStats
extends Resource
## Tuning data for hard-landing detection and the recovery lockout that
## follows, so a new character with different handling is a new .tres asset
## rather than a new script or a scene full of property overrides.

## Downward speed at or above which a landing counts as "hard".
@export var hard_land_speed: float = 400.0
## How long the character is locked in recovery after a hard landing.
@export var hard_land_time: float = 0.75
