class_name GuitarAttempt
extends Resource
## One try at the morning song on the guitar: where the next note is not there, and when the strings give up
## (systems/story, GuitarPhrase).

@export var melody: Melody
## Notes Ivo can play before the gap; the note at this index never comes.
@export var gap_index: int = 5
## Seconds with no press, once at the gap, before the beat ends.
@export var end_after_silence: float = 2.0
## Presses at the gap (muted thumps) before the beat ends.
@export var end_after_dead_presses: int = 3
## Seconds; a press closer than this to the last one is dropped, as the Memorina drops mashing.
@export var min_gap: float = 0.08
