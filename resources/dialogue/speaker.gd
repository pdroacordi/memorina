class_name Speaker
extends Resource
## Who says a line: the name plate and the portrait the dialogue box shows (systems/dialogue).

@export var id: StringName = &""
## `SPEAKER_<ID>`; empty shows no name plate.
@export var name_key: String = ""
## Null leaves the portrait slot empty; the text never moves either way.
@export var portrait: Texture2D
## Pitch of the voice blips, 0.5..2 (the voice cue's pitch times this); 0 is silent (SND-05).
@export_range(0.0, 2.0, 0.05) var voice_pitch: float = 1.0
