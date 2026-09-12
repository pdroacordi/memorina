class_name AttackPhaseData
extends Resource
## One beat of a combo: which AnimationTree state plays it, how long it lasts,
## and the hitbox tuning for that beat. `duration` must equal the length of the
## clip `state_name` plays - same manually-kept coupling as RollStats' timing
## fields, drifting it either cuts the animation short or holds control past
## the point where it visually ends.

@export var state_name: StringName
@export var duration: float = 0.35
## Trailing slice of `duration`, measured as time REMAINING, during which a
## fresh attack input chains into the next phase instead of being dropped.
@export var combo_window: float = 0.15
@export var damage: int = 1
@export var knockback_strength: float = 0.0
@export var knockback_lift: float = 0.0
