class_name PulseTimeline extends RefCounted

## The radius of a colour pulse over its life, and nothing else. Pure logic, so
## the curve can be tuned and tested without spawning anything.
##
## Phase meanings live on PulseStats, which is where they are authored.
##
## A plain match rather than a CharacterStateMachine: three phases in a fixed
## line, never re-entered, no per-phase behaviour beyond a number.

enum Phase { ATTACK, SUSTAIN, CONTRACT, DONE }

## How far into SUSTAIN the leading ring takes to fade out, as a fraction of
## the sustain time. The front has arrived; the ring lingers a moment, then the
## pulse is just light.
const RING_FADE := 0.25

var phase: Phase = Phase.ATTACK

var _max_radius: float
var _attack_time: float
var _sustain_time: float
var _contract_time: float
var _elapsed: float = 0.0

## `local_memory` is how alive the ground under the pulse already was. A pulse
## lit in a badly corroded place dies sooner, so the danger of a region is
## legible in the very light the player switched on.
func _init(stats: PulseStats, local_memory: float) -> void:
	_max_radius = stats.max_radius
	_attack_time = maxf(stats.attack_time, 0.0001)
	_sustain_time = maxf(stats.sustain_time, 0.0)
	_contract_time = maxf(stats.contract_time * lerpf(stats.contract_min_factor, 1.0, clampf(local_memory, 0.0, 1.0)), 0.0001)

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

func radius() -> float:
	match phase:
		Phase.ATTACK:
			# Ease-out: the front leaps away and settles, rather than creeping.
			var t := _elapsed / _attack_time
			return _max_radius * (1.0 - (1.0 - t) * (1.0 - t))
		Phase.SUSTAIN:
			return _max_radius
		Phase.CONTRACT:
			# Squared, so the grey comes back faster the longer it has been coming.
			var t := (_elapsed - _attack_time - _sustain_time) / _contract_time
			return _max_radius * (1.0 - t * t)
		_:
			return 0.0

## Brightness of the leading ring, 0..1: full while the front is moving out,
## fading once it stops, gone for the rest of the pulse's life.
func ring() -> float:
	match phase:
		Phase.ATTACK:
			return 1.0
		Phase.SUSTAIN:
			var fade_time := _sustain_time * RING_FADE
			if fade_time <= 0.0:
				return 0.0
			var t := (_elapsed - _attack_time) / fade_time
			return clampf(1.0 - t, 0.0, 1.0)
		_:
			return 0.0

func total_time() -> float:
	return _attack_time + _sustain_time + _contract_time

func is_finished() -> bool:
	return phase == Phase.DONE
