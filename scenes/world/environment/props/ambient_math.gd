class_name AmbientMath
extends RefCounted
## The memory clock of an ambient prop: time that advances only where the world is remembered
## (design 03 section 2, architecture/props-and-ambient-life).


## `time` advanced by `delta` at the rate the memory gives (0..1); nothing below `stop_threshold`.
static func advance(time: float, delta: float, memory: float, stop_threshold: float) -> float:
	var rate := clampf(memory, 0.0, 1.0)
	if rate < stop_threshold:
		return time
	return time + delta * rate

## The frame shown at `time`: `sequence` entries in order (or 0..frame_count-1), shifted by `phase` (0..1 of a loop).
static func frame_at(time: float, frames_per_second: float, frame_count: int, phase: float, sequence: PackedInt32Array) -> int:
	var length := sequence.size() if not sequence.is_empty() else frame_count
	if length <= 0:
		return 0
	var step := posmod(floori(time * frames_per_second + phase * length), length)
	return sequence[step] if not sequence.is_empty() else step

## A stable 0..1 phase for a placed prop, so neighbours do not move in step; an explicit integer hash, the same on every load.
static func phase_for(point: Vector2) -> float:
	var x := roundi(point.x)
	var y := roundi(point.y)
	var h := (x * 73856093) ^ (y * 19349663)
	h = (h ^ (h >> 13)) * 1274126177
	h = h ^ (h >> 16)
	return float(posmod(h, 10007)) / 10007.0
