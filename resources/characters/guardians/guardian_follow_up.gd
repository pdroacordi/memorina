class_name GuardianFollowUp
extends Resource
## One link of a guardian string: the move that may follow a strike with no cooldown (GuardianRepertoire.next_link).

## The move thrown next; null throws the move it follows again (a .tres cannot list itself).
@export var attack: GuardianAttack
## Chance the link is taken, 0..1, scaled by the stage's chain_scale and clamped to 1.
@export_range(0.0, 1.0) var chance: float = 1.0
## The cure stage from which the link may be taken.
@export var from_stage: int = 0
## Taken only when the strike ended against a wall or the arena edge ahead (a charge-back, a wall bounce).
@export var needs_wall: bool = false
