class_name EnemyStats
extends Resource
## What a creature variant may change; Enemy pushes it into its children at _ready
## (docs/knowledge/systems/creatures.md). A species is a scene plus one of these.

@export var health: int = 3
@export var contact_damage: int = 1
## Knockback of touching the body, px/s.
@export var contact_knockback: float = 300.0

@export_group("Senses")
## Radius EnemySight watches, px.
@export var sight_radius: float = 320.0
## Radius at which Ivo's body wakes it, px.
@export var wake_radius: float = 200.0
## Fully dissolved, with every area off, until woken and gathered.
@export var hidden_until_woken: bool = true

@export_group("Ground")
## Farthest it follows a target from home, px; 0 = no leash.
@export var leash: float = 0.0
@export var wanders: bool = false
## Horizontal distance to the target at which a walker stops closing in, px.
@export var stop_distance: float = 48.0
@export var locomotion: LocomotionStats

@export_group("Guard")
## Hits from in front below the top of its body are blocked: no damage, a white flash (HitGuard; the crab's shell).
@export var front_guard: bool = false

@export_group("Moves")
## In priority order: the first whose reach holds the target is thrown.
@export var moves: Array[EnemyMove] = []

@export_group("Wander")
## Walking and standing phases of a wander, s.
@export var min_wander_duration: float = 1.0
@export var max_wander_duration: float = 3.0
@export var min_idle_duration: float = 0.8
@export var max_idle_duration: float = 3.0


## Every problem with this data; empty when it is usable.
func validate() -> PackedStringArray:
	var problems := PackedStringArray()
	if health <= 0:
		problems.append("health must be positive")
	if sight_radius <= 0.0 or wake_radius <= 0.0:
		problems.append("sight_radius and wake_radius must be positive")
	if locomotion == null:
		problems.append("locomotion is missing")
	if min_wander_duration <= 0.0 or min_wander_duration > max_wander_duration \
			or min_idle_duration <= 0.0 or min_idle_duration > max_idle_duration:
		problems.append("wander and idle durations must be positive, min <= max")
	if moves.is_empty():
		problems.append("moves is empty")
	var farthest := 0.0
	for move: EnemyMove in moves:
		if move == null:
			problems.append("a move is null")
			continue
		if move.hitbox.is_empty():
			problems.append("a move names no hitbox")
		if move.telegraph < 0.0 or move.active <= 0.0 or move.recovery < 0.0 or move.cooldown < 0.0:
			problems.append("move durations must be positive (active above 0)")
		if not move.reach.has_area():
			problems.append("a move's reach is empty")
		farthest = maxf(farthest, move.reach.end.x)
	if stop_distance < 0.0 or (not moves.is_empty() and stop_distance > farthest):
		problems.append("stop_distance %.1f is outside every move's reach (%.1f)" % [stop_distance, farthest])
	return problems
