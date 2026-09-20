class_name WorldFreeze extends Node

## The one writer of the world's clock. The instrument freezes everything
## while a performance plays (docs/design/02_mecanicas.md section 6.2); a
## pause menu will call the same two methods. Whatever must keep moving
## through a freeze - the sheet, the instrument's sound, Ivo's idle - is
## marked PROCESS_MODE_ALWAYS in its own scene, not excepted here.
##
## The ability recall (section 4) slows the world instead of stopping it:
## "tempo desacelera". Everything keeps moving, just slowly, so the attack
## that forced the memory is still coming while the hand finds the button.

## How slow the world runs during a recall. 1.0 would be no signal at all.
@export_range(0.05, 1.0) var slow_scale: float = 0.25

func freeze() -> void:
	get_tree().paused = true

func thaw() -> void:
	get_tree().paused = false

func slow() -> void:
	Engine.time_scale = slow_scale

func restore() -> void:
	Engine.time_scale = 1.0
