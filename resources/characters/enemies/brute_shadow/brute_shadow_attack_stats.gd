class_name BruteShadowAttackStats
extends Resource
## Stores Brute Shadow melee attack timing and range.

## Must match the attack animation length in brute_shadow.tscn.
@export var attack_duration: float = 0.9166667
## Melee reach, in px.
@export var attack_range: float = 40.0
## Delay between attacks, in seconds.
@export var attack_cooldown: float = 1.0
