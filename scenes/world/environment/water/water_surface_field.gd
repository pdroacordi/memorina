class_name WaterSurfaceField extends RefCounted

## Water spring simulation; see docs/design/03_mundo_e_ambiente.md section 4.
## Column rates are memory values in 0..1; a zero-rate column preserves its state.
## Heights are world px, positive up.

## Extra damping per second on a column fully held by ice.
const HOLD_DAMPING := 12.0

var _profile: WaterProfile
var _heights := PackedFloat32Array()
var _velocities := PackedFloat32Array()
var _holds := PackedFloat32Array()
# Per column: the height above the swell that ice holds it at, set when ice first takes it.
var _pinned := PackedFloat32Array()
var _swell_time := 0.0
# Scratch buffers, reused every sub-step rather than allocated in it.
var _targets := PackedFloat32Array()
var _accelerations := PackedFloat32Array()

func _init(column_count: int, profile: WaterProfile) -> void:
	assert(column_count > 0, "A water surface needs at least one column")
	_profile = profile
	# One by one: packed arrays are values, so resizing a loop variable over
	# them would resize a copy.
	_heights.resize(column_count)
	_velocities.resize(column_count)
	_holds.resize(column_count)
	_pinned.resize(column_count)
	_targets.resize(column_count)
	_accelerations.resize(column_count)

func column_count() -> int:
	return _heights.size()

func height(column: int) -> float:
	return _heights[column]

## How agitated a column is, 0..1: the foam on the waterline.
func energy(column: int) -> float:
	return clampf(absf(_velocities[column]) / maxf(_profile.splash_max_depth * 4.0, 0.001), 0.0, 1.0)

## Adds `displacement` world pixels (positive up) to a column, scaled by how
## little of it is held by ice. Writes position, not velocity, on purpose: a
## splash into water that is not moving must still leave its shape behind.
func disturb(column: int, displacement: float) -> void:
	if column < 0 or column >= _heights.size():
		return
	_heights[column] += displacement * (1.0 - _holds[column])

## How much of a column ice has taken, 0..1. At 1 the column is locked at its height above the swell when ice first took it.
func set_hold(column: int, hold: float) -> void:
	if _holds[column] <= 0.0 and hold > 0.0:
		_pinned[column] = _heights[column] - swell(column, _swell_time)
	_holds[column] = clampf(hold, 0.0, 1.0)
	if _holds[column] >= 1.0:
		_heights[column] = _pinned[column]
		_velocities[column] = 0.0

## The height ice holds a column at, world px above the rest line.
func pinned(column: int) -> float:
	return _pinned[column]

func hold(column: int) -> float:
	return _holds[column]

## Advances the surface. `rates[i]` is column i's clock rate (the memory over
## it); `swell_time` is the body's own clock, which the swell is a function of;
## `offsets[i]` (px, may be empty) raises a column's target, as a wind crest does.
func step(delta: float, rates: PackedFloat32Array, swell_time: float, offsets: PackedFloat32Array = PackedFloat32Array()) -> void:
	assert(rates.size() == _heights.size(), "One rate per column")
	_swell_time = swell_time
	if delta <= 0.0:
		return
	var substeps := maxi(1, ceili(delta / _profile.max_substep))
	var dt := delta / float(substeps)
	for i in substeps:
		_substep(dt, rates, swell_time, offsets)

## The ambient swell a column is pulled toward: three sines at irrational-ish
## ratios, so the pattern never visibly repeats.
func swell(column: int, time: float) -> float:
	if _profile.wave_amplitude == 0.0:
		return 0.0
	var x := float(column * _profile.column_width)
	var k := TAU / _profile.wave_length
	var w := k * _profile.wave_speed
	return _profile.wave_amplitude * (
		0.6 * sin(k * x - w * time)
		+ 0.3 * sin(1.618 * k * x + 0.73 * w * time + 1.7)
		+ 0.1 * sin(2.9 * k * x - 1.9 * w * time + 4.1)
	)

	# Couple displacement from the swell so neighbour coupling preserves its shape.
func _substep(dt: float, rates: PackedFloat32Array, swell_time: float, offsets: PackedFloat32Array) -> void:
	var count := _heights.size()
	for i in count:
		var free := swell(i, swell_time) + (offsets[i] if not offsets.is_empty() else 0.0)
		_targets[i] = lerpf(free, _pinned[i], _holds[i])
	for i in count:
		_accelerations[i] = 0.0
		if rates[i] <= 0.0 or _holds[i] >= 1.0:
			continue
		var left := maxi(i - 1, 0)
		var right := mini(i + 1, count - 1)
		var offset := _heights[i] - _targets[i]
		var damping := _profile.damping + HOLD_DAMPING * _holds[i]
		_accelerations[i] = (
			-_profile.stiffness * offset
			+ _profile.spread * ((_heights[left] - _targets[left]) + (_heights[right] - _targets[right]) - 2.0 * offset)
			+ _profile.viscosity * (_velocities[left] + _velocities[right] - 2.0 * _velocities[i])
			- damping * _velocities[i]
		)
	for i in count:
		if rates[i] <= 0.0 or _holds[i] >= 1.0:
			continue
		# Clamped: memory never exceeds 1, and a rate much above it would take
		# the stiff springs past the integrator's stability limit.
		var local_dt := dt * minf(rates[i], 1.0)
		_velocities[i] += _accelerations[i] * local_dt
		_heights[i] += _velocities[i] * local_dt
