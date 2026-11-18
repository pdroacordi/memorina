class_name GuardianMoveClockTest extends GdUnitTestSuite

## A string's phases with no spill, chained links, an uncancellable recovery (architecture/grd-12-guardian-fight-engine).

const STEP := 0.1

var _clock: GuardianMoveClock


func before_test() -> void:
	_clock = GuardianMoveClock.new()

func test_a_move_runs_telegraph_then_strike_then_waits_for_the_ai() -> void:
	var move := _move(0.2, 0.3)
	assert_bool(_clock.start(move)).is_true()
	assert_int(_clock.phase).is_equal(GuardianMoveClock.Phase.TELEGRAPH)
	assert_int(_clock.tick(STEP)).is_equal(GuardianMoveClock.Phase.READY)
	assert_int(_clock.tick(STEP * 1.5)).is_equal(GuardianMoveClock.Phase.TELEGRAPH)
	assert_int(_clock.phase).is_equal(GuardianMoveClock.Phase.STRIKE)
	# No spill: the strike starts with its whole length.
	assert_float(_clock.elapsed()).is_equal(0.0)
	_clock.tick(STEP)
	assert_float(_clock.elapsed()).is_equal_approx(STEP, 0.0001)
	_clock.tick(STEP)
	assert_int(_clock.tick(STEP * 1.5)).is_equal(GuardianMoveClock.Phase.STRIKE)
	assert_int(_clock.phase).is_equal(GuardianMoveClock.Phase.STRIKE)

func test_start_is_refused_unless_ready() -> void:
	_clock.start(_move(0.2, 0.3))
	assert_bool(_clock.start(_move(0.2, 0.3))).is_false()

func test_a_zero_telegraph_strikes_at_once() -> void:
	_clock.start(_move(0.0, 0.3))
	assert_int(_clock.phase).is_equal(GuardianMoveClock.Phase.STRIKE)

func test_chain_goes_from_the_strike_to_the_next_telegraph_with_no_cooldown() -> void:
	_strike_out(_move(0.1, 0.2))
	var link := _move(0.15, 0.2)
	_clock.chain(link)
	assert_int(_clock.phase).is_equal(GuardianMoveClock.Phase.TELEGRAPH)
	assert_object(_clock.move).is_same(link)

func test_rest_recovers_then_cools_down_then_is_ready() -> void:
	_strike_out(_move(0.1, 0.2))
	_clock.rest(0.3, 0.25)
	assert_int(_clock.phase).is_equal(GuardianMoveClock.Phase.RECOVER)
	assert_bool(_clock.is_busy()).is_true()
	_clock.tick(0.31)
	assert_int(_clock.phase).is_equal(GuardianMoveClock.Phase.COOLDOWN)
	assert_object(_clock.move).is_null()
	_clock.cool(0.2)
	assert_int(_clock.phase).is_equal(GuardianMoveClock.Phase.COOLDOWN)
	_clock.cool(0.06)
	assert_int(_clock.phase).is_equal(GuardianMoveClock.Phase.READY)

func test_rest_with_no_recovery_or_cooldown_is_ready_at_once() -> void:
	_strike_out(_move(0.1, 0.2))
	_clock.rest(0.0, 0.0)
	assert_int(_clock.phase).is_equal(GuardianMoveClock.Phase.READY)

func test_provoke_drops_a_cooldown_but_never_a_recovery() -> void:
	_strike_out(_move(0.1, 0.2))
	_clock.rest(0.3, 1.0)
	_clock.provoke()
	assert_int(_clock.phase).is_equal(GuardianMoveClock.Phase.RECOVER)
	_clock.tick(0.31)
	_clock.provoke()
	assert_int(_clock.phase).is_equal(GuardianMoveClock.Phase.READY)

func test_cancel_clears_everything_with_no_cooldown() -> void:
	_strike_out(_move(0.1, 0.2))
	_clock.rest(0.3, 1.0)
	_clock.cancel()
	assert_int(_clock.phase).is_equal(GuardianMoveClock.Phase.READY)
	assert_object(_clock.move).is_null()

func test_the_cooldown_does_not_run_from_tick() -> void:
	_strike_out(_move(0.1, 0.2))
	_clock.rest(0.0, 0.5)
	_clock.tick(1.0)
	assert_int(_clock.phase).is_equal(GuardianMoveClock.Phase.COOLDOWN)

func _strike_out(move: GuardianAttack) -> void:
	_clock.start(move)
	while _clock.tick(STEP * 0.5) != GuardianMoveClock.Phase.STRIKE:
		pass

func _move(telegraph: float, duration: float) -> GuardianAttack:
	var move := GuardianAttack.new()
	move.telegraph = telegraph
	move.duration = duration
	return move
