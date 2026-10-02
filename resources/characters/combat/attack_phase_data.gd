class_name AttackPhaseData
extends Resource
## Combo phase data; `duration` must equal the length of the clip named by `state_name`.

@export var state_name: StringName
@export var duration: float = 0.35
## Combo input window in seconds remaining before this phase ends.
@export var combo_window: float = 0.15
@export var damage: int = 1
@export var knockback_strength: float = 0.0
@export var knockback_lift: float = 0.0
