class_name GuardianSpawn
extends Resource
## An attack a guardian move fires during its strike: a projectile or a floor hazard (GuardianSpawner).

## Where instances go: ahead of the feet, on Ivo's feet, spread around him, across the arena, on both sides, or where
## the move's motion lands (the origin without a motion).
enum Placement { FRONT, AT_IVO, AROUND_IVO, ACROSS_ARENA, BOTH_SIDES, AT_LANDING }

## A SpawnedAttack scene; its kind tunables are exports on its root.
@export var scene: PackedScene
## Scaled s into the strike when the first instance fires.
@export var at: float = 0.0
## Fires when the guardian lands during the strike instead of at `at`.
@export var on_landing: bool = false
@export var placement: Placement = Placement.FRONT
## Instances fired; BOTH_SIDES fires this many on each side.
@export_range(1, 12) var count: int = 1
## Px between instances.
@export var spacing: float = 64.0
## Scaled s between instances: columns lit in sequence.
@export var interval: float = 0.0
## Px from the guardian's feet, facing east.
@export var offset: Vector2 = Vector2.ZERO

@export_group("Hitbox")
@export var damage: int = 1
@export var knockback_strength: float = 360.0
## Upward knockback in px/s.
@export var knockback_lift: float = 120.0
