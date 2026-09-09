class_name RollStats
extends Resource
## Tuning data for the ground roll: distance, timing and the buffer/coyote
## windows around it, so a new character with different handling is a new
## .tres asset rather than a new script or a scene full of property overrides.

@export var roll_time: float = 0.3
@export var roll_distance: float = 128.0
@export var roll_cooldown: float = 0.5
@export var roll_coyote_time_max: float = 0.12
@export var roll_buffer_max: float = 0.12
