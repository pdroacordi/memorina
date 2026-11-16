class_name SfxMuffleMath
extends RefCounted
## The SfxWorld low-pass cutoff for a memory value (architecture/sound-effects-system, option c).

## Hz at memory 1: nothing audible is cut.
const OPEN_HZ := 20000.0
## Hz at memory 0.
const MUFFLED_HZ := 1200.0


## Hz for `memory` (0..1): even steps in pitch, as MusicMix.cutoff_hz, so each tenth of memory lowers it alike.
static func cutoff(memory: float) -> float:
	return OPEN_HZ * pow(MUFFLED_HZ / OPEN_HZ, 1.0 - clampf(memory, 0.0, 1.0))

## The filter is off at full memory.
static func is_open(memory: float) -> bool:
	return memory >= 1.0
