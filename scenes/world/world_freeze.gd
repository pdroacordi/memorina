class_name WorldFreeze extends Node

## The one writer of the world's clock. The instrument freezes everything
## while a performance plays (docs/design/02_mecanicas.md section 6.2); a
## pause menu will call the same two methods. Whatever must keep moving
## through a freeze - the sheet, the instrument's sound, Ivo's idle - is
## marked PROCESS_MODE_ALWAYS in its own scene, not excepted here.

func freeze() -> void:
	get_tree().paused = true

func thaw() -> void:
	get_tree().paused = false
