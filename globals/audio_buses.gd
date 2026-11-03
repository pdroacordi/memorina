class_name AudioBuses
extends RefCounted
## The audio bus names; must match default_bus_layout.tres (architecture/music-system).

## Background music; the only bus a duck touches.
const MUSIC := &"Music"
## Every played or sung note: the Memorina, performances, calls, teachers, melodies, the guitar.
const NOTES := &"Notes"
## Story and world sounds that are not notes.
const SFX := &"Sfx"
