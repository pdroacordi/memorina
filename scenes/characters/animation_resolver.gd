class_name AnimationResolver
extends Node
## Resolves a character's animation clip from its current state.

## Injected by the owning Character, the composition root.
var driver: AnimationDriver


func resolve() -> StringName:
	return &""

func is_death_finished() -> bool:
	return false
