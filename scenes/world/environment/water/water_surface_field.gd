class_name WaterSurfaceField extends RefCounted

## The surface of a body of water, as a row of springs. Pure logic: it knows
## nothing about the memory field, the scene or the GPU, so every rule the
## design sets for water motion is tested here.
##
## THE GREY IS STOPPED TIME, PER COLUMN. Each column integrates with its own
## `rate` (the memory field over it, 0..1, no threshold): a column at 0.1 moves
## at a tenth of the speed, and one at exactly 0 does not move at all - not
## "barely", not "calmly": its height and velocity are left bit-for-bit as they
## were. A crest raised in water nobody remembers stays exactly where it rose.
##
## WHY A FIELD AND NOT ANALYTIC WAVES. A pulse can cover half a pool. Analytic
## waves on per-column time would leave the half that ran ahead permanently out
## of phase with the half that did not - a scar that never heals. Springs chase
## the swell instead of being it, so once everything is alive again the surface
## settles back into one continuous wave. A frozen column is simply a column
## that does not move: its live neighbours still feel it, so ripples reflect off
## it like a wall.
##
## Heights are in world pixels, positive UP. The shader rounds them, which is
## what makes the waterline step a whole pixel at a time.

## Extra damping on a column fully held by ice, per second. The surface stops
## answering well before the ice looks solid.
const HOLD_DAMPING := 12.0

var _profile: WaterProfile
var _heights := PackedFloat32Array()
var _velocities := PackedFloat32Array()
var _holds := PackedFloat32Array()

func _init(column_count: int, profile: WaterProfile) -> void:
	assert(column_count > 0, "A water surface needs at least one column")
	_profile = profile
	_heights.resize(column_count)
	_velocities.resize(column_count)
	_holds.resize(column_count)

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

## How much of a column ice has taken, 0..1. At 1 the column is locked flat.
func set_hold(column: int, hold: float) -> void:
	_holds[column] = clampf(hold, 0.0, 1.0)
	if _holds[column] >= 1.0:
		_heights[column] = 0.0
		_velocities[column] = 0.0

func hold(column: int) -> float:
	return _holds[column]

## Advances the surface. `rates[i]` is column i's clock rate (the memory over
## it); `swell_time` is the body's own clock, which the swell is a function of.
func step(delta: float, rates: PackedFloat32Array, swell_time: float) -> void:
	assert(rates.size() == _heights.size(), "One rate per column")
	if delta <= 0.0:
		return
	var substeps := maxi(1, ceili(delta / _profile.max_substep))
	var dt := delta / float(substeps)
	for i in substeps:
		_substep(dt, rates, swell_time)

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

func _substep(dt: float, rates: PackedFloat32Array, swell_time: float) -> void:
	var count := _heights.size()
	var accelerations := PackedFloat32Array()
	accelerations.resize(count)
	for i in count:
		if rates[i] <= 0.0 or _holds[i] >= 1.0:
			continue
		var left := _heights[maxi(i - 1, 0)]
		var right := _heights[mini(i + 1, count - 1)]
		var target := swell(i, swell_time) * (1.0 - _holds[i])
		var damping := _profile.damping + HOLD_DAMPING * _holds[i]
		accelerations[i] = (
			_profile.stiffness * (target - _heights[i])
			+ _profile.spread * (left + right - 2.0 * _heights[i])
			- damping * _velocities[i]
		)
	for i in count:
		if rates[i] <= 0.0 or _holds[i] >= 1.0:
			continue
		var local_dt := dt * rates[i]
		_velocities[i] += accelerations[i] * local_dt
		_heights[i] += _velocities[i] * local_dt
