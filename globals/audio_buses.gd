class_name AudioBuses
extends RefCounted
## The audio bus names; must match default_bus_layout.tres (architecture/music-system).

## The engine's bus every other bus sends to; only Settings writes its volume.
const MASTER := &"Master"
## Background music; the only bus a duck touches.
const MUSIC := &"Music"
## Every played or sung note: the Memorina, performances, calls, teachers, melodies, the guitar.
const NOTES := &"Notes"
## Story, body and menu sounds that are not notes.
const SFX := &"Sfx"
## World-object sounds (doors, pickups, splashes); sends to Sfx, its volume stays 0 dB, its low-pass is SfxMuffle's.
const SFX_WORLD := &"SfxWorld"
