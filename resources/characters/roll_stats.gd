class_name RollStats
extends Resource
## Tuning data for a character's ground roll.

## Duration of the MOVEMENT phase only — the burst during which the roll
## Movement phase duration in seconds; commitment continues through recovery.
@export var roll_time: float = 0.3
@export var roll_distance: float = 128.0
## Recovery duration in seconds, separate so distance, speed, and animation timing can be tuned independently.
@export var roll_recovery_time: float = 0.0
@export var roll_cooldown: float = 0.5
@export var roll_coyote_time_max: float = 0.12
@export var roll_buffer_max: float = 0.12
