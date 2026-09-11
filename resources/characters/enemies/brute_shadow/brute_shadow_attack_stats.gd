class_name BruteShadowAttackStats
extends Resource
## Tuning data for BruteShadowAI's melee attack.

## Matches the "attack" animation's length (brute_shadow.tscn) so the
## gameplay state and the animation stay in lockstep.
@export var attack_duration: float = 0.9166667
@export var attack_range: float = 40.0
@export var attack_cooldown: float = 1.0
