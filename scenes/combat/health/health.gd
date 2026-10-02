class_name Health
extends Node
## Character-agnostic hit-point pool that signals damage, healing, and death.

signal damaged(amount: int, current: int)
signal healed(amount: int, current: int)
signal died

@export var max_hp: int = 3

var current_hp: int = max_hp


## Scene export overrides are applied before _ready(), so initialize current_hp here.
func _ready() -> void:
	current_hp = max_hp

## Emits `died` only on the transition to 0; the host owns the death policy.
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

## Restores full health and emits `healed` only if health changed.
func reset() -> void:
	var restored := max_hp - current_hp
	current_hp = max_hp
	if restored > 0:
		healed.emit(restored, current_hp)
