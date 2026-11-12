class_name HoldRiseTest extends GdUnitTestSuite

## Holding Up raises the swing (flashback 3, systems/story): a step every 0.5 s held, letting go recedes, 2 s finishes,
## a full recede plus 1.5 s idle gives it up.

const STEP := 0.05


func _run(rise: HoldRise, seconds: float, held: bool) -> void:
	var left := seconds
	while left > 0.0001:
		rise.tick(minf(STEP, left), held)
		left -= STEP

func test_a_step_every_half_second_held() -> void:
	var rise := HoldRise.new()
	assert_int(rise.level()).is_equal(0)
	_run(rise, 0.45, true)
	assert_int(rise.level()).is_equal(0)
	_run(rise, 0.1, true)
	assert_int(rise.level()).is_equal(1)
	_run(rise, 0.5, true)
	assert_int(rise.level()).is_equal(2)
	assert_bool(rise.is_finished()).is_false()

func test_two_seconds_held_finish_it() -> void:
	var rise := HoldRise.new()
	_run(rise, 1.95, true)
	assert_bool(rise.is_finished()).is_false()
	_run(rise, 0.05, true)
	assert_bool(rise.is_finished()).is_true()
	assert_int(rise.level()).is_equal(4)
	_run(rise, 5.0, false)
	assert_int(rise.level()).is_equal(4)
	assert_bool(rise.is_abandoned()).is_false()

func test_letting_go_recedes_at_the_same_pace() -> void:
	var rise := HoldRise.new()
	_run(rise, 1.5, true)
	assert_int(rise.level()).is_equal(3)
	_run(rise, 0.5, false)
	assert_int(rise.level()).is_equal(2)
	_run(rise, 1.0, false)
	assert_int(rise.level()).is_equal(0)
	assert_bool(rise.is_abandoned()).is_false()

func test_holding_again_climbs_from_where_it_receded() -> void:
	var rise := HoldRise.new()
	_run(rise, 1.5, true)
	_run(rise, 0.5, false)
	_run(rise, 1.0, true)
	assert_bool(rise.is_finished()).is_true()

func test_a_full_recede_left_idle_gives_it_up() -> void:
	var rise := HoldRise.new()
	_run(rise, 1.0, true)
	_run(rise, 1.0, false)
	_run(rise, 1.4, false)
	assert_bool(rise.is_abandoned()).is_false()
	_run(rise, 0.1, false)
	assert_bool(rise.is_abandoned()).is_true()
	_run(rise, 3.0, true)
	assert_int(rise.level()).is_equal(0)
	assert_bool(rise.is_finished()).is_false()

func test_holding_resets_the_idle() -> void:
	var rise := HoldRise.new()
	_run(rise, 1.2, false)
	_run(rise, 0.1, true)
	_run(rise, 0.1, false)
	_run(rise, 1.2, false)
	assert_bool(rise.is_abandoned()).is_false()
	_run(rise, 0.3, false)
	assert_bool(rise.is_abandoned()).is_true()

func test_never_holding_gives_it_up_after_the_idle() -> void:
	var rise := HoldRise.new()
	_run(rise, 1.5, false)
	assert_bool(rise.is_abandoned()).is_true()
