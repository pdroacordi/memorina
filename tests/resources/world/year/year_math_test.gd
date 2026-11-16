class_name YearMathTest extends GdUnitTestSuite

## YearMath: each season holds, then turns into the next over turn_seconds, eased; four commits return to the start.

const VILLAGE := preload("res://resources/world/year/village_year.tres")


func _stats() -> YearStats:
	var stats := YearStats.new()
	stats.season_seconds = 240.0
	stats.turn_seconds = 12.0
	return stats

func test_a_season_holds_then_turns_then_commits() -> void:
	var stats := _stats()
	var start := YearMath.at(0.0, stats, Enums.Season.SPRING)
	assert_int(start.season).is_equal(Enums.Season.SPRING)
	assert_int(start.next).is_equal(Enums.Season.SUMMER)
	assert_float(start.turn).is_equal(0.0)
	assert_float(YearMath.at(228.0, stats, Enums.Season.SPRING).turn).is_equal(0.0)
	assert_float(YearMath.at(234.0, stats, Enums.Season.SPRING).turn).is_equal_approx(0.5, 0.0001)
	assert_float(YearMath.at(239.999, stats, Enums.Season.SPRING).turn).is_greater(0.999)
	var committed := YearMath.at(240.0, stats, Enums.Season.SPRING)
	assert_int(committed.season).is_equal(Enums.Season.SUMMER)
	assert_int(committed.next).is_equal(Enums.Season.AUTUMN)
	assert_float(committed.turn).is_equal(0.0)

func test_the_turn_rises_monotonically_within_a_turn() -> void:
	var stats := _stats()
	var last := 0.0
	for tenth: int in range(0, 120):
		var turn: float = YearMath.at(228.0 + tenth * 0.1, stats, Enums.Season.SPRING).turn
		assert_float(turn).is_greater_equal(last)
		last = turn

func test_four_commits_return_to_the_start_from_any_season() -> void:
	var stats := _stats()
	for start: Enums.Season in stats.order:
		var seen: Array[int] = []
		for step: int in range(0, 4):
			seen.append(YearMath.at(step * 240.0 + 1.0, stats, start).season)
		assert_int(seen[0]).is_equal(start)
		assert_int(YearMath.at(4 * 240.0 + 1.0, stats, start).season).is_equal(start)
		seen.sort()
		assert_array(seen).is_equal([0, 1, 2, 3])

func test_the_village_year_is_the_planned_pace() -> void:
	var order: Array[Enums.Season] = []
	order.assign(VILLAGE.order)
	assert_array(order).is_equal([Enums.Season.SPRING, Enums.Season.SUMMER, Enums.Season.AUTUMN, Enums.Season.WINTER])
	assert_float(VILLAGE.season_seconds).is_equal(240.0)
	assert_float(VILLAGE.turn_seconds).is_equal(12.0)
	assert_object(VILLAGE.when[0]).is_same(load("res://resources/save_facts/world_restored.tres"))
