class_name SongProgress
extends RefCounted
## How far a song has gone between two marks, 0..1: flashback 5's colour and dusk follow her lullaby.


## 0 at `from` seconds and before, 1 at `to` and after, linear between.
static func at(position: float, from: float, to: float) -> float:
	if to <= from:
		return 1.0 if position >= to else 0.0
	return clampf((position - from) / (to - from), 0.0, 1.0)
