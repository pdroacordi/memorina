class_name GrassSpringsTest extends GdUnitTestSuite

## A blade's spring settles on its push and, at rate 0, holds its exact state to resume from it (architecture/generated-grass).

var _profile := GrassProfile.new()


func _rates(count: int, rate: float) -> PackedFloat32Array:
	var rates := PackedFloat32Array()
	rates.resize(count)
	rates.fill(rate)
	return rates

func test_rest_stays_at_rest() -> void:
	var springs := GrassSprings.new(4)
	assert_bool(springs.step(0.1, _rates(4, 1.0), _profile)).is_true()
	assert_bool(springs.is_resting()).is_true()

func test_the_bend_settles_on_its_target() -> void:
	var springs := GrassSprings.new(1)
	springs.target[0] = 0.8
	for i: int in 300:
		springs.step(1.0 / 60.0, _rates(1, 1.0), _profile)
	assert_float(springs.bend[0]).is_equal_approx(0.8, 0.01)

func test_rate_zero_holds_the_state_exactly_then_resumes_from_it() -> void:
	var held := GrassSprings.new(1)
	var free := GrassSprings.new(1)
	for springs: GrassSprings in [held, free]:
		springs.target[0] = 0.8
		for i: int in 5:
			springs.step(1.0 / 60.0, _rates(1, 1.0), _profile)
	var bend := held.bend[0]
	var velocity := held.velocity[0]
	for i: int in 600:
		held.step(1.0 / 60.0, _rates(1, 0.0), _profile)
	assert_float(held.bend[0]).is_equal(bend)
	assert_float(held.velocity[0]).is_equal(velocity)
	held.step(1.0 / 60.0, _rates(1, 1.0), _profile)
	free.step(1.0 / 60.0, _rates(1, 1.0), _profile)
	assert_float(held.bend[0]).is_equal(free.bend[0])

func test_half_the_rate_is_half_the_time() -> void:
	var slow := GrassSprings.new(1)
	var fast := GrassSprings.new(1)
	slow.target[0] = 1.0
	fast.target[0] = 1.0
	slow.step(0.1, _rates(1, 0.5), _profile)
	fast.step(0.05, _rates(1, 1.0), _profile)
	assert_float(slow.bend[0]).is_equal_approx(fast.bend[0], 0.000001)

func test_a_large_delta_stays_stable() -> void:
	var springs := GrassSprings.new(1)
	springs.target[0] = 1.0
	springs.step(0.5, _rates(1, 1.0), _profile)
	assert_bool(absf(springs.bend[0]) < 2.0).is_true()
