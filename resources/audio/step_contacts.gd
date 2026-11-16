class_name StepContacts
extends Resource
## Contact times per looping clip: when a foot or a hand meets what carries it (systems/sound-effects).

## Clip name (a PlayerAnimationResolver const) -> contact seconds in [0, clip length).
@export var contacts: Dictionary[StringName, PackedFloat32Array] = {}


## The contact seconds of `clip`; empty for a clip that makes no step.
func contacts_of(clip: StringName) -> PackedFloat32Array:
	return contacts.get(clip, PackedFloat32Array())
