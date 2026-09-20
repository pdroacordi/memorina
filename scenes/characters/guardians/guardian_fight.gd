class_name GuardianFight extends RefCounted

## The three-phase structure of a guardian encounter
## (docs/design/02_mecanicas.md section 3) as pure logic: pressure until
## enough hits land, a lucidity window the player answers or loses, and
## restoration after enough good answers. A plain RefCounted like
## CharacterStateMachine: the owning Guardian drives it explicitly, reads
## its phase, and does all the sounding, moving and saving itself.
##
## Every failed answer makes the guardian angrier - more hits to open the next
## window, a shorter window, faster attacks - up to a cap. That is the
## design's whole penalty: no game over, just a harder road back.

signal phase_changed(from: Phase, to: Phase)

enum Phase { DORMANT, PRESSURE, LUCIDITY, RESTORED }

var _stats: GuardianStats
var _phase := Phase.DORMANT
var _hits: int = 0
var _cycles: int = 0
var _aggression: int = 0
## Seconds left to answer; negative while no window is counting.
var _window_left: float = -1.0

func _init(stats: GuardianStats) -> void:
	_stats = stats

func phase() -> Phase:
	return _phase

## The fight starts: the player walked into the arena.
func begin() -> void:
	if _phase == Phase.DORMANT:
		_transition(Phase.PRESSURE)

## The save says this guardian was restored on an earlier visit; skip the fight.
func restore_silently() -> void:
	if _phase == Phase.DORMANT:
		_cycles = _stats.cycles_to_restore
		_transition(Phase.RESTORED)

## A hit landed on the guardian. Counts only under pressure; true when it was
## the one that opened a lucidity window.
func register_hit() -> bool:
	if _phase != Phase.PRESSURE:
		return false
	_hits += 1
	if _hits < hits_to_open():
		return false
	_hits = 0
	_transition(Phase.LUCIDITY)
	return true

## The call has been heard; the player's window starts now. `call_length` is
## how long the phrase itself took: the answer cannot be played any faster
## than the call was, so the window is that plus the stats' slack.
func open_window(call_length: float = 0.0) -> void:
	if _phase == Phase.LUCIDITY:
		_window_left = maxf(call_length, 0.0) + window_duration()

func is_window_open() -> bool:
	return _phase == Phase.LUCIDITY and _window_left >= 0.0

func window_left() -> float:
	return maxf(_window_left, 0.0)

## Advances the window. True on the frame it runs out, which the owner treats
## exactly like a wrong note.
func tick(delta: float) -> bool:
	if not is_window_open():
		return false
	_window_left -= delta
	if _window_left >= 0.0:
		return false
	_window_left = -1.0
	answer_failed()
	return true

## The phrase came back right and in time. Restores the guardian on the last
## needed cycle; otherwise the fight resumes, the guardian a little more lucid.
func answer_succeeded() -> void:
	if _phase != Phase.LUCIDITY:
		return
	_window_left = -1.0
	_cycles += 1
	_transition(Phase.RESTORED if _cycles >= _stats.cycles_to_restore else Phase.PRESSURE)

## A wrong note, an interruption or an expired window: back to pressure,
## angrier. Not a second kind of failure - the same one, however it happened.
func answer_failed() -> void:
	if _phase != Phase.LUCIDITY:
		return
	_window_left = -1.0
	_aggression = mini(_aggression + 1, _stats.max_aggression)
	_transition(Phase.PRESSURE)

func aggression() -> int:
	return _aggression

func hits_to_open() -> int:
	return _stats.hits_to_open + _aggression * _stats.extra_hits_per_failure

func window_duration() -> float:
	return _stats.window * pow(_stats.window_scale_per_failure, _aggression)

## Multiplier for the guardian's attack cooldowns: 1.0 when calm.
func cooldown_scale() -> float:
	return pow(_stats.cooldown_scale_per_failure, _aggression)

## How far the cure has come, 0..1. Drives how much colour the guardian holds.
func lucidity() -> float:
	if _stats.cycles_to_restore <= 0:
		return 1.0
	return clampf(float(_cycles) / _stats.cycles_to_restore, 0.0, 1.0)

func _transition(to: Phase) -> void:
	if to == _phase:
		return
	var from := _phase
	_phase = to
	phase_changed.emit(from, to)
