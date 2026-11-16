class_name BodySoundSet
extends Resource
## A creature's or guardian's body sounds, played by BodySounds (systems/sound-effects); null is silent.

@export var struck: SoundCue
## A hit turned away by a front guard.
@export var blocked: SoundCue
## At most CorruptionEdge.vanish_time long: the emitter is freed with the body (body_sound_set_test).
@export var death: SoundCue
