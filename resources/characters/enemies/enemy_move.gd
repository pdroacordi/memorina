class_name EnemyMove
extends Resource
## One creature attack: when it is thrown, how long each phase lasts and what its hitbox carries
## (docs/knowledge/systems/creatures.md). Shared names and units with GuardianAttack.

## Standing still with the tell clip looping, s.
@export var telegraph: float = 0.6
## Hitbox live, s; for a lunge, the longest run.
@export var active: float = 0.2
## Standing after the hit window (daze, stuck), s.
@export var recovery: float = 0.8
## From the end of recovery until the next move may start, s.
@export var cooldown: float = 0.8
## Box the target must be inside for the move to start, px from the feet, authored facing east.
@export var reach: Rect2 = Rect2(0.0, -64.0, 64.0, 80.0)
## Speed along the facing during ACTIVE, px/s; 0 stands.
@export var lunge_speed: float = 0.0
## A wall or a ledge ends ACTIVE early and starts the recovery.
@export var ends_on_wall: bool = false
## During ACTIVE a hit neither knocks back nor cancels.
@export var armoured: bool = false
## Name of the child Hitbox armed during ACTIVE.
@export var hitbox: StringName = &""

@export_group("Hitbox")
@export var damage: int = 1
## Knockback on the target, px/s.
@export var knockback_strength: float = 420.0
## Upward knockback on the target, px/s.
@export var knockback_lift: float = 120.0
