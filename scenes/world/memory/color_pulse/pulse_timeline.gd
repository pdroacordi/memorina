class_name PulseTimeline extends RefCounted

## Computes a color pulse's radius and ring brightness over its phases; phase parameters are authored in PulseStats.

enum Phase { ATTACK, SUSTAIN, CONTRACT, DONE }

## Fraction of sustain time used to fade the leading ring.
const RING_FADE := 0.25
## Seconds a stretched pulse takes to grow to its new reach.
const GROW_TIME := 1.0

var phase: Phase = Phase.ATTACK

var _max_radius: float
var _attack_time: float
var _sustain_time: float
var _contract_time: float
var _elapsed: float = 0.0
# Radius and elapsed time at which stretching began.
var _stretched := false
var _grow_from := -1.0
var _grow_start := 0.0
# Fixed at initialization so extending sustain cannot relight a faded ring.
var _ring_fade_time := 0.0

## `local_memory` scales contract duration: pulses in less remembered ground contract sooner.
func _init(stats: PulseStats, local_memory: float) -> void:
	_max_radius = stats.max_radius
	_attack_time = maxf(stats.attack_time, 0.0001)
	_sustain_time = maxf(stats.sustain_time, 0.0)
	_contract_time = maxf(stats.contract_time * lerpf(stats.contract_min_factor, 1.0, clampf(local_memory, 0.0, 1.0)), 0.0001)
	_ring_fade_time = _sustain_time * RING_FADE

func advance(delta: float) -> void:
	if phase == Phase.DONE:
		return
	_elapsed += delta
	if _elapsed < _attack_time:
		phase = Phase.ATTACK
	elif _elapsed < _attack_time + _sustain_time:
		phase = Phase.SUSTAIN
	elif _elapsed < total_time():
		phase = Phase.CONTRACT
	else:
		phase = Phase.DONE

## Applies the Solstice stretch from docs/design/02_mecanicas.md section 7.1 once, while opening or sustaining; reach grows over GROW_TIME.
func stretch(reach: float, duration: float) -> bool:
	if _stretched or phase == Phase.CONTRACT or phase == Phase.DONE:
		return false
	_stretched = true
	_grow_from = radius()
	_grow_start = _elapsed
	_max_radius *= reach
	_sustain_time *= duration
	return true

func is_stretched() -> bool:
	return _stretched

## Maximum reach after any stretch.
func max_radius() -> float:
	return _max_radius

func radius() -> float:
	var natural := _natural_radius()
	if _grow_from < 0.0 or phase == Phase.CONTRACT or phase == Phase.DONE:
		return natural
	var t := clampf((_elapsed - _grow_start) / GROW_TIME, 0.0, 1.0)
	return lerpf(minf(_grow_from, natural), natural, smoothstep(0.0, 1.0, t))

func _natural_radius() -> float:
	match phase:
		Phase.ATTACK:
			# Ease-out makes the front move quickly at first and then settle.
			var t := _elapsed / _attack_time
			return _max_radius * (1.0 - (1.0 - t) * (1.0 - t))
		Phase.SUSTAIN:
			return _max_radius
		Phase.CONTRACT:
			# Squared contraction accelerates as the pulse fades.
			var t := (_elapsed - _attack_time - _sustain_time) / _contract_time
			return _max_radius * (1.0 - t * t)
		_:
			return 0.0

## Leading-ring brightness in 0..1; it fades during sustain and is zero afterward.
func ring() -> float:
	match phase:
		Phase.ATTACK:
			return 1.0
		Phase.SUSTAIN:
			if _ring_fade_time <= 0.0:
				return 0.0
			var t := (_elapsed - _attack_time) / _ring_fade_time
			return clampf(1.0 - t, 0.0, 1.0)
		_:
			return 0.0

func total_time() -> float:
	return _attack_time + _sustain_time + _contract_time

func is_finished() -> bool:
	return phase == Phase.DONE
