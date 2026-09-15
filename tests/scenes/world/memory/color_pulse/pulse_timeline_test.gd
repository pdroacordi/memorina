class_name PulseTimelineTest extends GdUnitTestSuite

## The pulse's shape in time. Pure logic, so the feel of a pulse can be tuned
## and checked without spawning one.

const MAX_RADIUS := 100.0
const ATTACK := 0.25
const SUSTAIN := 2.0
const CONTRACT := 1.0

func _stats() -> PulseStats:
	var stats := PulseStats.new()
	stats.max_radius = MAX_RADIUS
	stats.attack_time = ATTACK
	stats.sustain_time = SUSTAIN
	stats.contract_time = CONTRACT
	stats.contract_min_factor = 0.4
	return stats

func _timeline(local_memory: float = 1.0) -> PulseTimeline:
	return PulseTimeline.new(_stats(), local_memory)

func test_it_starts_in_the_attack_at_no_radius() -> void:
	var timeline := _timeline()
	assert_int(timeline.phase).is_equal(PulseTimeline.Phase.ATTACK)
	assert_float(timeline.radius()).is_equal_approx(0.0, 0.0001)

func test_the_attack_opens_to_the_full_radius() -> void:
	var timeline := _timeline()
	timeline.advance(ATTACK - 0.001)
	assert_int(timeline.phase).is_equal(PulseTimeline.Phase.ATTACK)
	assert_float(timeline.radius()).is_greater(MAX_RADIUS * 0.9)

## The front leaps and settles rather than creeping, so it is already past
## halfway at the halfway point.
func test_the_attack_eases_out() -> void:
	var timeline := _timeline()
	timeline.advance(ATTACK * 0.5)
	assert_float(timeline.radius()).is_greater(MAX_RADIUS * 0.5)

func test_the_sustain_holds_at_the_full_radius() -> void:
	var timeline := _timeline()
	timeline.advance(ATTACK + SUSTAIN * 0.5)
	assert_int(timeline.phase).is_equal(PulseTimeline.Phase.SUSTAIN)
	assert_float(timeline.radius()).is_equal_approx(MAX_RADIUS, 0.0001)

func test_the_contraction_pulls_the_radius_back_in() -> void:
	var timeline := _timeline()
	timeline.advance(ATTACK + SUSTAIN + CONTRACT * 0.5)
	assert_int(timeline.phase).is_equal(PulseTimeline.Phase.CONTRACT)
	assert_float(timeline.radius()).is_less(MAX_RADIUS)
	assert_float(timeline.radius()).is_greater(0.0)

## "Nao e um desvanecer educado; e reconquista" - the grey comes back faster
## the longer it has been coming, so the second half loses more than the first.
func test_the_contraction_accelerates() -> void:
	var timeline := _timeline()
	timeline.advance(ATTACK + SUSTAIN)
	var full := timeline.radius()
	timeline.advance(CONTRACT * 0.5)
	var half := timeline.radius()
	timeline.advance(CONTRACT * 0.49)
	var late := timeline.radius()
	assert_float(full - half).is_less(half - late)

func test_the_radius_never_grows_during_the_contraction() -> void:
	var timeline := _timeline()
	timeline.advance(ATTACK + SUSTAIN)
	var previous := timeline.radius()
	for i: int in 20:
		timeline.advance(CONTRACT / 21.0)
		if timeline.is_finished():
			break
		var current := timeline.radius()
		assert_float(current).is_less_equal(previous + 0.0001)
		previous = current

func test_it_finishes_after_all_three_phases() -> void:
	var timeline := _timeline()
	assert_bool(timeline.is_finished()).is_false()
	timeline.advance(timeline.total_time() + 0.01)
	assert_bool(timeline.is_finished()).is_true()
	assert_int(timeline.phase).is_equal(PulseTimeline.Phase.DONE)

## A pulse lit in a corroded place dies sooner - this is what makes the danger
## of a region readable in the light the player switched on.
func test_a_pulse_in_a_dead_place_dies_sooner() -> void:
	var alive := _timeline(1.0)
	var dying := _timeline(0.0)
	assert_float(dying.total_time()).is_less(alive.total_time())

func test_full_memory_gives_the_authored_contraction() -> void:
	assert_float(_timeline(1.0).total_time()).is_equal_approx(ATTACK + SUSTAIN + CONTRACT, 0.0001)

## The 0.0001 clamps exist so an un-tuned PulseStats cannot divide by zero.
func test_zero_length_phases_do_not_divide_by_zero() -> void:
	var stats := _stats()
	stats.attack_time = 0.0
	stats.contract_time = 0.0
	var timeline := PulseTimeline.new(stats, 1.0)
	assert_float(timeline.radius()).is_between(0.0, MAX_RADIUS)
	timeline.advance(SUSTAIN * 0.5)
	assert_float(timeline.radius()).is_between(0.0, MAX_RADIUS)
	timeline.advance(SUSTAIN)
	assert_bool(timeline.is_finished()).is_true()

func test_advancing_past_the_end_stays_finished() -> void:
	var timeline := _timeline()
	timeline.advance(timeline.total_time() * 5.0)
	timeline.advance(10.0)
	assert_bool(timeline.is_finished()).is_true()
	assert_float(timeline.radius()).is_equal_approx(0.0, 0.0001)
