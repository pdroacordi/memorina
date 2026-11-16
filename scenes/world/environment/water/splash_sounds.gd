class_name SplashSounds
extends Node2D
## A body of water's splash, heard where the fall broke the surface (systems/sound-effects).

@export var sounds: SplashSoundSet

@onready var _emitter: SfxEmitter = $SfxEmitter


## The emitter every voice goes through, for tests and the playtest log.
func emitter() -> SfxEmitter:
	return _emitter

func on_surface_splashed(point: Vector2, speed: float) -> void:
	_emitter.play_at(sounds.cue_for(speed), point, ImpactLevel.db(speed, sounds.quiet_speed, sounds.full_speed))
