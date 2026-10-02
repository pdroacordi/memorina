class_name GuardianAttack
extends Resource
## Guardian attack tuning; `duration` must match the selected animation clip.

## Resolver attack clip index.
@export_range(0, 2) var clip_index: int = 0
@export var duration: float = 1.0
## Telegraph duration in seconds.
@export var telegraph: float = 0.4
## Attack range in px.
@export var attack_range: float = 64.0
## Vertical attack range in px; combined with `attack_range` as an axis-aligned box.
@export var attack_height: float = 96.0
@export var cooldown: float = 1.5
## Horizontal lunge speed in px/s, in the facing direction.
@export var lunge_speed: float = 0.0
## Upward impulse in px/s; tune so airtime matches the attack clip.
@export var leap_impulse: float = 0.0
## Relative selection weight; recall attacks use GuardianStats.recall_after_attacks.
@export var weight: float = 1.0

@export_group("Hitbox")
@export var damage: int = 1
@export var knockback_strength: float = 420.0
## Upward knockback in px/s.
@export var knockback_lift: float = 120.0

@export_group("Recall")
## Opens recall only while the player lacks this skill; the teaching attack is unavoidable.
@export var recall: AbilityRecallStats
