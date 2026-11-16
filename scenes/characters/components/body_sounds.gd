class_name BodySounds
extends Node2D
## A creature's or guardian's body sounds, heard from where it stands (systems/sound-effects).
## Its owner pushes `sounds` from its stats and connects struck, blocked and died.

@export var sounds: BodySoundSet

var _dead: bool = false

@onready var _emitter: SfxEmitter = $SfxEmitter


## The emitter every voice goes through, for tests and the playtest log.
func emitter() -> SfxEmitter:
	return _emitter

# A killing hit emits `died` before `struck`: the death sound stands alone.
func on_struck() -> void:
	if not _dead and sounds != null:
		_emitter.play(sounds.struck)

func on_blocked() -> void:
	if sounds != null:
		_emitter.play(sounds.blocked)

func on_died() -> void:
	_dead = true
	if sounds != null:
		_emitter.play(sounds.death)
