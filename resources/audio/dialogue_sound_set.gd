class_name DialogueSoundSet
extends Resource
## The dialogue box's cues, played by DialogueBox (systems/dialogue); null is silent.

## A blip every few typed letters, pitched by `Speaker.voice_pitch`.
@export var voice: SoundCue
@export var open: SoundCue
## A press that goes on to the next line.
@export var advance: SoundCue
@export var close: SoundCue
## Focus steps between choices.
@export var move: SoundCue
## A choice is taken.
@export var confirm: SoundCue
