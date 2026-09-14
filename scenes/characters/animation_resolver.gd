class_name AnimationResolver
extends Node
## Decides which clip its character should be showing right now. One concrete
## resolver per character scene, mounted beside AnimationDriver; it owns that
## character's entire clip vocabulary, so no other script ever names a clip.
## resolve() is an ordered priority chain — the first matching branch wins.

## Injected by the owning Character, the composition root.
var driver: AnimationDriver


func resolve() -> StringName:
	return &""

func is_death_finished() -> bool:
	return false
