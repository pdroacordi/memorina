class_name WindProfile extends Resource

## Defines the repeating wind cycle; see docs/design/03_mundo_e_ambiente.md section 5.4.

## Calm duration between gusts, in seconds.
@export var calm_time := 2.5
## Rise duration, in seconds.
@export var rise_time := 0.6
## Gust duration, in seconds.
@export var gust_time := 1.6
## Fall duration, in seconds.
@export var fall_time := 0.9
## Calm strength as a fraction of full, 0..1.
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
