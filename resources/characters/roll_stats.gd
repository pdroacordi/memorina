class_name RollStats
extends Resource
## Tuning data for the ground roll: distance, timing and the buffer/coyote
## windows around it, so a new character with different handling is a new
## .tres asset rather than a new script or a scene full of property overrides.

## Duration of the MOVEMENT phase only — the burst during which the roll
## actually drives the character forward. The roll stays committed (i-frames,
## no jumping) past this point, through roll_recovery_time as well.
@export var roll_time: float = 0.3
@export var roll_distance: float = 128.0
## Tail after the movement phase during which the character is still
## committed to the roll but no longer being driven forward. Keeping this
## separate from roll_time is what lets travel distance, dash speed and
## animation length be tuned independently instead of being locked together
## by distance = speed x time.
@export var roll_recovery_time: float = 0.0
@export var roll_cooldown: float = 0.5
@export var roll_coyote_time_max: float = 0.12
@export var roll_buffer_max: float = 0.12
