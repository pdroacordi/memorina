class_name Melody
extends Resource
## A tune as notes and beats: the morning song the guitar plays and the daughter hums (systems/story). Never a Song:
## it is in no SongCatalog and teaches nothing.

## One note per beat entry, in Memorina note inputs.
@export var notes: Array[Enums.Note] = []
## Beats each note lasts, one per note.
@export var beats: PackedFloat32Array = PackedFloat32Array()
## Seconds per beat.
@export var beat_seconds: float = 0.42


## Seconds from the first note to the onset of each of the first `count` notes, at `tempo` times the written speed.
func onsets(count: int = -1, tempo: float = 1.0) -> PackedFloat32Array:
	var times := PackedFloat32Array()
	var shown := notes.size() if count < 0 else mini(count, notes.size())
	var at := 0.0
	for i: int in shown:
		times.append(at)
		at += beats[i] * beat_seconds / tempo
	return times

## Seconds the first `count` notes last, at `tempo` times the written speed.
func duration(count: int = -1, tempo: float = 1.0) -> float:
	var shown := notes.size() if count < 0 else mini(count, notes.size())
	var total := 0.0
	for i: int in shown:
		total += beats[i] * beat_seconds / tempo
	return total

## The problems found, one line each; empty when the melody is sound.
func validate() -> PackedStringArray:
	var problems := PackedStringArray()
	if notes.is_empty():
		problems.append("no notes")
	if beats.size() != notes.size():
		problems.append("%d beats for %d notes" % [beats.size(), notes.size()])
	for beat: float in beats:
		if beat <= 0.0:
			problems.append("a beat of %.2f" % beat)
	if beat_seconds <= 0.0:
		problems.append("beat_seconds %.2f" % beat_seconds)
	return problems
