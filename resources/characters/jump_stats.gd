class_name JumpStats
extends Resource
## Tuning data for a single jump and the vertical-motion feel around it, so a
## new character with different handling is a new .tres asset rather than a
## new script or a scene full of property overrides.

@export var jump_height: float = 80.0
## Multiplier on base gravity while rising.
@export var rise_gravity_mult: float = 0.85
## Multiplier on base gravity while falling.
@export var fall_gravity_mult: float = 1.0
@export var terminal_velocity: float = 500.0
@export var coyote_time_max: float = 0.12
@export var jump_buffer_max: float = 0.12
## Upward velocity is multiplied by this when the jump button is released early.
@export var jump_cut_mult: float = 0.5
## Vertical-speed magnitude below which the character counts as "at the apex".
@export var apex_threshold: float = 40.0
## Extra gravity multiplier applied at the apex, for float-y hang time.
@export var apex_gravity_mult: float = 0.5
