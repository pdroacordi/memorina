class_name YearMath
extends RefCounted
## Where a year stands after `elapsed` seconds of advance: the season, the next one and the turn between them, 0..1.


## {season, next, turn}: each season holds for `season_seconds - turn_seconds`, then `turn` rises 0..1, eased.
static func at(elapsed: float, stats: YearStats, start: Enums.Season) -> Dictionary:
	var count := stats.order.size()
	var first := maxi(stats.order.find(start), 0)
	var wrapped := fposmod(elapsed, stats.cycle_seconds())
	var step := mini(int(wrapped / stats.season_seconds), count - 1)
	var local := wrapped - step * stats.season_seconds
	var hold := stats.season_seconds - stats.turn_seconds
	var turn := 0.0
	if local > hold and stats.turn_seconds > 0.0:
		turn = smoothstep(0.0, 1.0, (local - hold) / stats.turn_seconds)
	return {
		"season": stats.order[(first + step) % count],
		"next": stats.order[(first + step + 1) % count],
		"turn": turn,
	}
