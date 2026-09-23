class_name WaterSurfaceFieldTest extends GdUnitTestSuite

## The water's motion rules (design 03 §2 and §6.2): time runs at the rate the
## place is remembered, stops only at exactly zero, and heals once alive.

const COLUMNS := 48
const FRAME := 1.0 / 60.0

func _profile(swell: float = 0.0) -> WaterProfile:
	var profile := WaterProfile.new()
	profile.wave_amplitude = swell
	return profile

func _field(swell: float = 0.0) -> WaterSurfaceField:
	return WaterSurfaceField.new(COLUMNS, _profile(swell))

func _rates(value: float) -> PackedFloat32Array:
	var rates := PackedFloat32Array()
	rates.resize(COLUMNS)
	rates.fill(value)
	return rates

func _run(field: WaterSurfaceField, rates: PackedFloat32Array, seconds: float) -> void:
	for frame in roundi(seconds / FRAME):
		field.step(FRAME, rates, frame * FRAME)

func _heights(field: WaterSurfaceField) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	for i in field.column_count():
		out.append(field.height(i))
	return out

func _max_abs(field: WaterSurfaceField, from: int = 0, to: int = COLUMNS) -> float:
	var worst := 0.0
	for i in range(from, to):
		worst = maxf(worst, absf(field.height(i)))
	return worst

func test_a_crest_in_forgotten_water_is_bit_identical_forever() -> void:
	var field := _field(1.0)
	field.disturb(20, -4.0)
	field.disturb(19, 2.0)
	field.disturb(21, 2.0)
	var before := _heights(field)
	for i in 10000:
		field.step(FRAME, _rates(0.0), i * FRAME)
	assert_array(_heights(field)).is_equal(before)

func test_a_live_crest_relaxes() -> void:
	var field := _field()
	field.disturb(20, 4.0)
	_run(field, _rates(1.0), 6.0)
	assert_float(_max_abs(field)).is_less(0.1)

## Soft springs, so the two runs' different step sizes (a tenth of the rate is
## a tenth of the step) cannot hide the rule behind integration error.
func test_grey_water_moves_in_proportion_to_its_memory() -> void:
	var soft := _profile()
	soft.spread = 200.0
	var slow := WaterSurfaceField.new(COLUMNS, soft)
	var fast := WaterSurfaceField.new(COLUMNS, soft)
	slow.disturb(20, 4.0)
	fast.disturb(20, 4.0)
	_run(slow, _rates(0.1), 2.0)
	_run(fast, _rates(1.0), 0.2)
	# Same shape to within 5% of the 4 px crest: what is left is step-size
	# error, not a different motion.
	for i in COLUMNS:
		assert_float(slow.height(i)).is_equal_approx(fast.height(i), 0.2)

func test_grey_water_is_never_fully_still_above_zero() -> void:
	var field := _field()
	field.disturb(20, 4.0)
	_run(field, _rates(0.05), 1.0)
	assert_float(field.height(20)).is_not_equal(4.0)

func test_a_ripple_propagates_to_its_neighbours() -> void:
	var field := _field()
	field.disturb(20, 4.0)
	_run(field, _rates(1.0), 0.1)
	assert_float(absf(field.height(24))).is_greater(0.01)

func test_a_frozen_column_is_a_wall() -> void:
	var field := _field()
	var rates := _rates(1.0)
	rates[24] = 0.0
	field.disturb(18, 4.0)
	_run(field, rates, 3.0)
	assert_float(_max_abs(field, 25, COLUMNS)).is_equal(0.0)
	assert_float(field.height(24)).is_equal(0.0)

func test_the_swell_does_nothing_where_nothing_is_remembered() -> void:
	var field := _field(2.0)
	_run(field, _rates(0.0), 3.0)
	assert_float(_max_abs(field)).is_equal(0.0)

func test_the_swell_moves_living_water() -> void:
	var field := _field(2.0)
	_run(field, _rates(1.0), 3.0)
	assert_float(_max_abs(field)).is_greater(0.3)

## Half the pool ran inside a pulse and half did not. Once all of it is alive
## again the scar must heal - analytic per-column waves never would.
func test_a_scar_heals_once_everything_is_alive() -> void:
	var field := _field()
	for i in COLUMNS:
		field.disturb(i, 3.0 if i % 2 == 0 else 0.0)
	_run(field, _rates(1.0), 20.0)
	assert_float(_max_abs(field)).is_less(0.05)

func test_a_held_column_ignores_a_splash() -> void:
	var field := _field()
	field.set_hold(10, 1.0)
	field.disturb(10, 4.0)
	assert_float(field.height(10)).is_equal(0.0)

func test_full_hold_locks_a_column_flat() -> void:
	var field := _field()
	field.disturb(10, 3.0)
	field.set_hold(10, 1.0)
	_run(field, _rates(1.0), 1.0)
	assert_float(field.height(10)).is_equal(0.0)

func test_a_partial_hold_settles_the_surface_sooner() -> void:
	var free := _field()
	var held := _field()
	free.disturb(20, 4.0)
	held.disturb(20, 4.0)
	for i in COLUMNS:
		held.set_hold(i, 0.6)
	_run(free, _rates(1.0), 0.6)
	_run(held, _rates(1.0), 0.6)
	assert_float(_max_abs(held)).is_less(_max_abs(free))
