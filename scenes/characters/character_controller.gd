class_name CharacterController
extends Node
## Supplies movement intent to a Character. Player input and enemy AI are
## both controllers — a Character never needs to know where its intent came
## from, only that it can poll `direction` and listen for these signals.
##
## Continuous state (e.g. `direction`) is exposed as a typed read-only
## property that the Character polls; discrete events (jump, roll) are
## signals. See CLAUDE.md's architecture section for why: a "changed" signal
## carrying a level value fires every frame and forces consumers to keep a
## shadow copy, while a polled property sampled on read never goes stale.


# Declared with the overridable getter form (`get = _get_direction`) rather
# than an inline `get:` block. An inline getter cannot be overridden by a
# subclass; delegating to a method can, since GDScript dispatches method
# calls dynamically. Do not "simplify" this back to an inline getter — doing
# so silently breaks every subclass that overrides _get_direction().
var direction: float:
	get = _get_direction

## Neutral default (no intent), overridden by subclasses (hardware input,
## enemy AI, ...). Sampled on read rather than cached, per the CLAUDE.md rule:
## caching in _physics_process would reintroduce a one-frame lag, since Godot
## processes parents before children.
func _get_direction() -> float:
	return 0.0
