class_name WindProfile extends Resource

## How a natural current breathes: calm, rising, a gust, falling, and round
## again. The calms are the window to play in (design 03 section 5.4, item 1:
## "as calmarias entre rajadas sao a janela") - timing, the thread through the
## whole game, taught by the weather.

## Seconds at calm_strength between gusts.
@export var calm_time := 2.5
## Seconds to rise from calm to full.
@export var rise_time := 0.6
## Seconds at full strength.
@export var gust_time := 1.6
## Seconds to fall back to calm.
@export var fall_time := 0.9
## Strength during the calm, as a fraction of full. Not zero: a calm still
## carries leaves.
@export_range(0.0, 1.0) var calm_strength := 0.15

func period() -> float:
	return calm_time + rise_time + gust_time + fall_time

## The current strength, 0..1, `time` seconds into the cycle.
func strength(time: float) -> float:
	var t := fposmod(time, maxf(period(), 0.0001))
	if t < calm_time:
		return calm_strength
	t -= calm_time
	if t < rise_time:
		return lerpf(calm_strength, 1.0, smoothstep(0.0, 1.0, t / rise_time))
	t -= rise_time
	if t < gust_time:
		return 1.0
	t -= gust_time
	return lerpf(1.0, calm_strength, smoothstep(0.0, 1.0, t / maxf(fall_time, 0.0001)))
