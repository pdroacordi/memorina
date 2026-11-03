class_name BarClock
extends RefCounted
## Bar arithmetic for music changes that land on a bar line.

## Below this many seconds from a bar line, the bar counts as now.
const ON_BAR := 0.001


## Seconds from `position` (s into the piece) to the next bar line; 0 when on one.
static func next_bar(position: float, bpm: float, beats_per_bar: int) -> float:
	var bar := bar_seconds(bpm, beats_per_bar)
	if bar <= 0.0:
		return 0.0
	var into := fmod(maxf(position, 0.0), bar)
	return 0.0 if into < ON_BAR or bar - into < ON_BAR else bar - into

static func bar_seconds(bpm: float, beats_per_bar: int) -> float:
	return 0.0 if bpm <= 0.0 else 60.0 / bpm * beats_per_bar
