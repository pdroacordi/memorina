class_name FinaleStats
extends Resource
## The final battle's tuning on the mentor's GuardianStats (design 02 section 5; architecture/grd-06-final-battle).

## Track B, the season the mentor tried to hold ("Primavera (Recommended)", user, 2026-10-30).
@export var second_song: Song
## Normal winter lucidity windows before the revelation; at least one (design 5.1).
@export var winter_cycles: int = 1
## Notes the revelation takes to reach its peak.
@export var revelation_notes: int = 3
## Real seconds after which the revelation peaks with no notes played.
@export var revelation_max_seconds: float = 5.0
## Real seconds of the freeze frame at the shatter.
@export var freeze_frame_seconds: float = 0.3
## Real seconds the revelation's effects take to settle after the shatter.
@export var stabilise_seconds: float = 0.4
## Notes revealed on each two-track call.
@export_range(0, 6) var dual_revealed: int = 4
## Damage per mixed input since the revelation, past the window's first (a warning); the last entry repeats.
@export var mixed_damage: Array[int] = [0, 1, 1, 2]
## Window drain added per mixed input in the window: drain = 1 + mixed_drain x mixed.
@export var mixed_drain: float = 0.6
## Veil added per mixed input past the window's first, 0..1.
@export var veil_per_mixed: float = 0.35
## The final call, phrase by phrase, after a track is chosen (design drafts/musica_aiva.md).
@export var final_phrases: Array[Song] = []
## The moves from the revelation on: the winter moves and the second season's.
@export var revealed_attacks: Array[GuardianAttack] = []
@export var dissonance_color: Color = Color(0.62, 0.46, 0.78)
## Played when the last phrase is answered; its SCENE_SEEN is the seam to the epilogue (STORY-07).
@export var restoration_scene: Cutscene
