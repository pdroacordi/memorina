class_name MusicCue
extends Resource
## A piece of background music and its named stems (architecture/music-system).

@export var id: StringName = &""
## An AudioStreamSynchronized whose sub-streams are the stems, or a plain stream played as one stem.
@export var stream: AudioStream
## Stem names; index i names sub-stream i.
@export var stems: Array[StringName] = []
## Starting level per stem, 0..1; a stem not listed starts at 1.
@export var levels: Dictionary[StringName, float] = {}
@export var bpm: float = 120.0
@export var beats_per_bar: int = 4
@export var loops: bool = true
## Real seconds to fade in when the cue starts.
@export var fade_in: float = 1.0
## Real seconds to fade out when the cue is left or released.
@export var fade_out: float = 1.0


## The stem count matches the stream's sub-streams.
func validate() -> PackedStringArray:
	var problems := PackedStringArray()
	if stream == null:
		problems.append("%s: no stream" % id)
		return problems
	var count := (stream as AudioStreamSynchronized).stream_count if stream is AudioStreamSynchronized else 1
	if stems.size() != count:
		problems.append("%s: %d stems named for %d streams" % [id, stems.size(), count])
	for stem: StringName in levels:
		if not stems.has(stem):
			problems.append("%s: level for unknown stem %s" % [id, stem])
	return problems

## The starting level of `stem`, 0..1.
func level(stem: StringName) -> float:
	return levels.get(stem, 1.0)
