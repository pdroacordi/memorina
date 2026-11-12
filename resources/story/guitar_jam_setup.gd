class_name GuitarJamSetup
extends Resource
## A free jam on the guitar beside her song (flashback 1, systems/story "GuitarJam"): every note sounds, out of tune, and
## nothing is ever played right.

## Her line the presses are measured against.
@export var melody: Melody
## Presses before the jam ends.
@export var max_presses: int = 12
## Mismatches against `melody` at which she laughs.
@export var laugh_at: int = 3
## Scaled seconds of the laugh stand-in.
@export var laugh_seconds: float = 1.2
## Scaled seconds with no press, once he has played, before the jam ends.
@export var end_after_silence: float = 2.5
## Scaled seconds with no press at all before the jam ends.
@export var end_before_first: float = 8.0
## Seconds; a press closer than this to the last one is dropped, as the Memorina drops mashing.
@export var min_gap: float = 0.08
## Cents each press is off, cycled by press; every one at least GuitarJam.MIN_DETUNE_CENTS from 0.
@export var detune_cents: PackedFloat32Array = PackedFloat32Array([38.0, -46.0, 31.0, -52.0, 44.0, -35.0])
