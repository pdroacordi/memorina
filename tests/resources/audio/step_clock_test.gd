class_name StepClockTest extends GdUnitTestSuite

## A step clock counts the contacts a looping clip's position crossed, across the loop wrap; a new clip starts
## before its first contact; a small move back reports nothing.

const RUN := &"run"
const WALK := &"walk"
const LENGTH := 0.8
const CONTACTS := [0.0, 0.4]

var _clock: StepClock
var _contacts := PackedFloat32Array(CONTACTS)


func before_test() -> void:
	_clock = StepClock.new()

func test_a_new_clip_sounds_its_contact_at_zero() -> void:
	assert_int(_clock.advance(RUN, 0.0, LENGTH, _contacts)).is_equal(1)

func test_no_contact_between_two_reads_is_silent() -> void:
	_clock.advance(RUN, 0.05, LENGTH, _contacts)
	assert_int(_clock.advance(RUN, 0.2, LENGTH, _contacts)).is_equal(0)

func test_crossing_a_contact_counts_it_once() -> void:
	_clock.advance(RUN, 0.3, LENGTH, _contacts)
	assert_int(_clock.advance(RUN, 0.4, LENGTH, _contacts)).is_equal(1)
	assert_int(_clock.advance(RUN, 0.4, LENGTH, _contacts)).is_equal(0)
	assert_int(_clock.advance(RUN, 0.45, LENGTH, _contacts)).is_equal(0)

func test_the_loop_wrap_counts_the_contact_at_zero() -> void:
	_clock.advance(RUN, 0.75, LENGTH, _contacts)
	assert_int(_clock.advance(RUN, 0.01, LENGTH, _contacts)).is_equal(1)

func test_a_wrap_counts_contacts_on_both_sides() -> void:
	var late := PackedFloat32Array([0.0, 0.78])
	_clock.advance(RUN, 0.75, LENGTH, late)
	assert_int(_clock.advance(RUN, 0.02, LENGTH, late)).is_equal(2)

func test_a_small_move_back_reports_nothing() -> void:
	_clock.advance(RUN, 0.45, LENGTH, _contacts)
	assert_int(_clock.advance(RUN, 0.35, LENGTH, _contacts)).is_equal(0)
	assert_int(_clock.advance(RUN, 0.41, LENGTH, _contacts)).is_equal(1)

func test_a_clip_change_restarts_at_the_first_contact() -> void:
	_clock.advance(RUN, 0.3, LENGTH, _contacts)
	assert_int(_clock.advance(WALK, 0.0, LENGTH, _contacts)).is_equal(1)

func test_a_clip_with_no_contacts_is_silent() -> void:
	assert_int(_clock.advance(&"idle", 0.0, LENGTH, PackedFloat32Array())).is_equal(0)

func test_reset_starts_the_clip_again() -> void:
	_clock.advance(RUN, 0.2, LENGTH, _contacts)
	_clock.reset()
	assert_int(_clock.advance(RUN, 0.2, LENGTH, _contacts)).is_equal(1)
