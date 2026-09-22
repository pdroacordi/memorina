class_name GuardianFight extends RefCounted

## The structure of a guardian encounter (docs/design/02_mecanicas.md
## section 3) as pure logic: pressure until enough hits land, a lucidity
## window the player answers or loses, a relapse while the madness returns,
## and restoration after enough good answers. A plain RefCounted like
## CharacterStateMachine: the owning Guardian drives it explicitly, reads
## its phase, and does all the sounding, moving and saving itself.
##
## The recall (section 4) is a gate, not a chance: while a skill is still to
## be remembered, the hits saturate at the threshold and the window waits.
## The body remembering is then the blow that opens it.
##
## Every failed answer makes the guardian angrier - more hits to open the next
## window, a shorter window, faster attacks - up to a cap. That is the
## design's whole penalty: no game over, just a harder road back.

signal phase_changed(from: Phase, to: Phase)

enum Phase { DORMANT, PRESSURE, LUCIDITY, RELAPSE, RESTORED }

## A relapse after a failure is this much shorter: it comes back sooner.
const FAILED_RELAPSE_SCALE := 0.6

var _stats: GuardianStats
var _phase := Phase.DORMANT
var _hits: int = 0
var _cycles: int = 0
var _aggression: int = 0
var _recall_pending: bool = false
## Whether the relapse under way follows a failed answer.
var _relapse_failed: bool = false
## Seconds left to answer; negative while no window is counting.
var _window_left: float = -1.0
## What that window started at, so the fraction left can be reported without
## anyone else having to remember the number they were told at the start.
var _window_total: float = 0.0
## Seconds left in the relapse before pressure resumes.
var _relapse_left: float = 0.0

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

## The owner says whether a skill is still to be remembered in this fight.
## While it is, no window opens: the design's guarantee that the player does
## not leave the encounter without it.
func set_recall_pending(pending: bool) -> void:
	_recall_pending = pending

func recall_pending() -> bool:
	return _recall_pending

## A hit landed on the guardian. Counts only under pressure; true when it was
## the one that opened a lucidity window. With a recall pending the hits stop
## at the threshold and wait.
func register_hit() -> bool:
	if _phase != Phase.PRESSURE:
		return false
	_hits = mini(_hits + 1, hits_to_open())
	return _try_open()

## The body remembered. True when that was what the window was waiting for.
func skill_recalled() -> bool:
	_recall_pending = false
	if _phase != Phase.PRESSURE:
		return false
	return _try_open()

## The hits are in and only the recall stands between them and the window.
func is_saturated() -> bool:
	return _phase == Phase.PRESSURE and _recall_pending and _hits >= hits_to_open()

## How close the pressure is to opening the next window, 0..1.
func pressure_progress() -> float:
	var needed := hits_to_open()
	if needed <= 0:
		return 1.0
	return clampf(float(_hits) / needed, 0.0, 1.0)

## The call has been heard; the player's window starts now. `call_length` is
## how long the phrase itself took: the answer cannot be played any faster
## than the call was, so the window is that plus the stats' slack.
func open_window(call_length: float = 0.0) -> void:
	if _phase == Phase.LUCIDITY:
		_window_left = maxf(call_length, 0.0) + window_duration()
		_window_total = _window_left

func is_window_open() -> bool:
	return _phase == Phase.LUCIDITY and _window_left >= 0.0

func window_left() -> float:
	return maxf(_window_left, 0.0)

## How much of the window is left, 0..1 - the one number a meter needs, and
## the only clock there is. A HUD that counted its own down would be a second
## truth, agreeing with this one only by coincidence.
func window_fraction() -> float:
	if _window_total <= 0.0:
		return 0.0
	return clampf(_window_left / _window_total, 0.0, 1.0)

## Advances the window and the relapse. True on the frame the window runs
## out, which the owner treats exactly like a wrong note; the relapse ending
## is announced through phase_changed alone.
func tick(delta: float) -> bool:
	if _phase == Phase.RELAPSE:
		_relapse_left -= delta
		if _relapse_left <= 0.0:
			_transition(Phase.PRESSURE)
		return false
	if not is_window_open():
		return false
	_window_left -= delta
	if _window_left >= 0.0:
		return false
	_window_left = -1.0
	answer_failed()
	return true

## The phrase came back right and in time. Restores the guardian on the last
## needed cycle; otherwise the madness returns, a little less of it.
func answer_succeeded() -> void:
	if _phase != Phase.LUCIDITY:
		return
	_window_left = -1.0
	_cycles += 1
	if _cycles >= _stats.cycles_to_restore:
		_transition(Phase.RESTORED)
	else:
		_relapse(false)

## A wrong note, an interruption or an expired window: the madness returns
## sooner and angrier. Not a second kind of failure - the same one, however
## it happened.
func answer_failed() -> void:
	if _phase != Phase.LUCIDITY:
		return
	_window_left = -1.0
	_aggression = mini(_aggression + 1, _stats.max_aggression)
	_relapse(true)

## Whether the relapse under way follows a failed answer.
func relapse_failed() -> bool:
	return _relapse_failed

## How far the relapse under way has run, 0..1; 1 when none is.
func relapse_progress() -> float:
	if _phase != Phase.RELAPSE:
		return 1.0
	var total := relapse_duration()
	if total <= 0.0:
		return 1.0
	return clampf(1.0 - _relapse_left / total, 0.0, 1.0)

## Good answers given so far.
func cycles() -> int:
	return _cycles

func relapse_duration() -> float:
	return _stats.relapse_time * (FAILED_RELAPSE_SCALE if _relapse_failed else 1.0)

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

func _try_open() -> bool:
	if _recall_pending or _hits < hits_to_open():
		return false
	_hits = 0
	_transition(Phase.LUCIDITY)
	return true

func _relapse(failed: bool) -> void:
	_relapse_failed = failed
	_relapse_left = _stats.relapse_time * (FAILED_RELAPSE_SCALE if failed else 1.0)
	_transition(Phase.RELAPSE)
	# A relapse of no length is the old behaviour: straight back to pressure.
	if _relapse_left <= 0.0:
		_transition(Phase.PRESSURE)

func _transition(to: Phase) -> void:
	if to == _phase:
		return
	var from := _phase
	_phase = to
	phase_changed.emit(from, to)
