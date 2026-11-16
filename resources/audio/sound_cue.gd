class_name SoundCue
extends Resource
## One sound effect: an engine stream plus what the engine lacks (architecture/sound-effects-system).

const MAX_VOICES := 4

## Normally an AudioStreamRandomizer in PLAYBACK_RANDOM_NO_REPEATS mode, for variants and jitter.
@export var stream: AudioStream
## Level of every voice, dB.
@export_range(-40.0, 6.0, 0.5, "suffix:dB") var volume_db: float = 0.0
## Voices of this cue that sound at once in one emitter; a new one steals the oldest.
@export_range(1, MAX_VOICES) var max_voices: int = 1
## Real seconds between two starts of this cue, across every emitter; 0 never gates.
@export_range(0.0, 2.0, 0.01, "suffix:s") var cooldown: float = 0.0
## A world-object sound, muffled with the greyhush on SfxWorld; Ivo, creatures and menus are not.
@export var world: bool = false


func bus() -> StringName:
	return AudioBuses.SFX_WORLD if world else AudioBuses.SFX
