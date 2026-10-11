class_name BruteShadowAttackStats
extends Resource
## Stores Brute Shadow melee attack timing and range.

## Must match the attack animation length in brute_shadow.tscn.
@export var attack_duration: float = 1.1666667
## Distance to the target, in px, at which a swing starts; must not exceed the swing's keyed reach.
@export var attack_range: float = 40.0
## Distance to the target, in px, at which the chase stops; inside Ivo's combo reach (`combat_reach_test`).
@export var stop_distance: float = 32.0
## Delay between attacks, in seconds.
@export var attack_cooldown: float = 1.0
