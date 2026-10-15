class_name Speaker
extends Resource
## Who says a line: the name plate and the portrait the dialogue box shows (systems/dialogue).

@export var id: StringName = &""
## `SPEAKER_<ID>`; empty shows no name plate.
@export var name_key: String = ""
## Null leaves the portrait slot empty; the text never moves either way.
@export var portrait: Texture2D
