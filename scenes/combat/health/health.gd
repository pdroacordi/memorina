class_name Health
extends Node
## Generic, character-agnostic health pool. Tracks a clamped hit-point value
## and announces damage, healing and death; it holds no opinion on what should
## happen next.

signal damaged(amount: int, current: int)
signal healed(amount: int, current: int)
signal died

@export var max_hp: int = 3

var current_hp: int = max_hp


## Exported overrides land after _init() but before _ready(), so _ready is the
## earliest point at which max_hp is trustworthy for a scene-configured value.
func _ready() -> void:
	current_hp = max_hp

## Clamps damage so hp never goes below 0. `died` fires exactly once per
## reaching 0 — this script only announces death and never frees its owner or
## picks a death policy, since the design has no traditional game over: death
## respawns the player at the last bench, which is a decision for the host node.
func take_damage(amount: int) -> void:
	var was_alive: bool = is_alive()
	current_hp = maxi(current_hp - amount, 0)
	damaged.emit(amount, current_hp)

	if was_alive and current_hp == 0:
		died.emit()

func heal(amount: int) -> void:
	current_hp = mini(current_hp + amount, max_hp)
	healed.emit(amount, current_hp)

func is_alive() -> bool:
	return current_hp > 0

## Restores to full — the hook for benches, which the design docs say fully
## heal the hero on rest.
func reset() -> void:
	current_hp = max_hp
