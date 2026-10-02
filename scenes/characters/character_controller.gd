class_name CharacterController
extends Node
## Supplies movement intent to a Character (CLAUDE.md architecture section).


# The method getter remains overridable by subclasses.
var direction: float:
	get = _get_direction

## Neutral default; subclasses provide current intent (CLAUDE.md architecture section).
func _get_direction() -> float:
	return 0.0
