class_name MoveClockTest extends GdUnitTestSuite

## A move runs telegraph, active, recovery and cooldown in order, for exactly their durations.

const STEP := 1.0 / 60.0

var _clock: MoveClock
var _move: EnemyMove


func before_test() -> void:
	_clock = MoveClock.new()
	_move = EnemyMove.new()
	_move.telegraph = 0.5
	_move.active = 0.2
	_move.recovery = 0.4
	_move.cooldown = 1.0

func test_phases_follow_in_order_for_their_durations() -> void:
	assert_bool(_clock.start(_move)).is_true()
	assert_int(_clock.phase).is_equal(MoveClock.Phase.TELEGRAPH)
	_clock.tick(0.49)
	assert_int(_clock.phase).is_equal(MoveClock.Phase.TELEGRAPH)
	_clock.tick(0.02)
	assert_int(_clock.phase).is_equal(MoveClock.Phase.ACTIVE)
	_clock.tick(0.2)
	assert_int(_clock.phase).is_equal(MoveClock.Phase.RECOVER)
	_clock.tick(0.4)
	assert_int(_clock.phase).is_equal(MoveClock.Phase.COOLDOWN)
	_clock.tick(1.0)
	assert_int(_clock.phase).is_equal(MoveClock.Phase.READY)
	assert_object(_clock.move).is_null()

func test_a_long_tick_spills_into_the_next_phases() -> void:
	_clock.start(_move)
	_clock.tick(0.75)
	assert_int(_clock.phase).is_equal(MoveClock.Phase.RECOVER)

func test_every_entered_phase_is_reported() -> void:
	var entered: Array[int] = []
	_clock.phase_entered.connect(func(phase: MoveClock.Phase) -> void: entered.append(phase))
	_clock.start(_move)
	_clock.tick(5.0)
	assert_array(entered).contains_exactly([MoveClock.Phase.TELEGRAPH, MoveClock.Phase.ACTIVE,
		MoveClock.Phase.RECOVER, MoveClock.Phase.COOLDOWN, MoveClock.Phase.READY])

func test_end_active_goes_to_recover() -> void:
	_clock.start(_move)
	_clock.tick(0.55)
	_clock.end_active()
	assert_int(_clock.phase).is_equal(MoveClock.Phase.RECOVER)
	_clock.tick(0.39)
	assert_int(_clock.phase).is_equal(MoveClock.Phase.RECOVER)

func test_end_active_outside_active_does_nothing() -> void:
	_clock.start(_move)
	_clock.end_active()
	assert_int(_clock.phase).is_equal(MoveClock.Phase.TELEGRAPH)

func test_cancel_keeps_the_cooldown() -> void:
	_clock.start(_move)
	_clock.tick(0.1)
	_clock.cancel()
	assert_int(_clock.phase).is_equal(MoveClock.Phase.COOLDOWN)
	_clock.tick(0.99)
	assert_int(_clock.phase).is_equal(MoveClock.Phase.COOLDOWN)
	_clock.tick(STEP)
	assert_int(_clock.phase).is_equal(MoveClock.Phase.READY)

func test_no_start_before_ready() -> void:
	_clock.start(_move)
	assert_bool(_clock.start(_move)).is_false()
	_clock.cancel()
	assert_bool(_clock.start(_move)).is_false()
	_clock.tick(1.0)
	assert_bool(_clock.start(_move)).is_true()

func test_busy_only_while_the_move_holds_the_creature() -> void:
	assert_bool(_clock.is_busy()).is_false()
	_clock.start(_move)
	assert_bool(_clock.is_busy()).is_true()
	_clock.tick(1.1)
	assert_int(_clock.phase).is_equal(MoveClock.Phase.COOLDOWN)
	assert_bool(_clock.is_busy()).is_false()
