class_name GuardianFight extends RefCounted

## Guardian encounter phases and timing rules; see docs/design/02_mecanicas.md sections 3–4.

signal phase_changed(from: Phase, to: Phase)

enum Phase { DORMANT, PRESSURE, LUCIDITY, RELAPSE, RESTORED }

## Failed answers shorten relapse duration by this factor.
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
## Initial window duration, used to calculate its remaining fraction.
var _window_total: float = 0.0
## Seconds left in the relapse before pressure resumes.
var _relapse_left: float = 0.0

func _init(stats: GuardianStats) -> void:
	_stats = stats

func phase() -> Phase:
	return _phase

## Starts the encounter.
func begin() -> void:
	if _phase == Phase.DORMANT:
		_transition(Phase.PRESSURE)

## Restores this guardian without playing the fight.
func restore_silently() -> void:
	if _phase == Phase.DORMANT:
		_cycles = _stats.cycles_to_restore
		_transition(Phase.RESTORED)

## Prevents the lucidity window from opening until the required skill is recalled.
func set_recall_pending(pending: bool) -> void:
	_recall_pending = pending

func recall_pending() -> bool:
	return _recall_pending

## Counts a pressure hit and returns true if it opens a lucidity window.
func register_hit() -> bool:
	if _phase != Phase.PRESSURE:
		return false
	_hits = mini(_hits + 1, hits_to_open())
	return _try_open()

## Clears the recall gate and returns true if that opens a lucidity window.
func skill_recalled() -> bool:
	_recall_pending = false
	if _phase != Phase.PRESSURE:
		return false
	return _try_open()

## Whether the hit threshold is met while recall is pending.
func is_saturated() -> bool:
	return _phase == Phase.PRESSURE and _recall_pending and _hits >= hits_to_open()

## Pressure progress, 0..1.
func pressure_progress() -> float:
	var needed := hits_to_open()
	if needed <= 0:
		return 1.0
	return clampf(float(_hits) / needed, 0.0, 1.0)

## Opens the answer window for `call_length` plus the configured slack, in seconds.
func open_window(call_length: float = 0.0) -> void:
	if _phase == Phase.LUCIDITY:
		_window_left = maxf(call_length, 0.0) + window_duration()
		_window_total = _window_left

func is_window_open() -> bool:
	return _phase == Phase.LUCIDITY and _window_left >= 0.0

func window_left() -> float:
	return maxf(_window_left, 0.0)

## Remaining window fraction, 0..1.
func window_fraction() -> float:
	if _window_total <= 0.0:
		return 0.0
	return clampf(_window_left / _window_total, 0.0, 1.0)

## Advances timers and returns true on the frame the answer window expires.
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

## Records a successful answer and restores the guardian after the final cycle.
func answer_succeeded() -> void:
	if _phase != Phase.LUCIDITY:
		return
	_window_left = -1.0
	_cycles += 1
	if _cycles >= _stats.cycles_to_restore:
		_transition(Phase.RESTORED)
	else:
		_relapse(false)

## Records a failed answer and increases aggression up to its configured cap.
func answer_failed() -> void:
	if _phase != Phase.LUCIDITY:
		return
	_window_left = -1.0
	_aggression = mini(_aggression + 1, _stats.max_aggression)
	_relapse(true)

## Whether the relapse under way follows a failed answer.
func relapse_failed() -> bool:
	return _relapse_failed

## Relapse progress, 0..1; returns 1 outside relapse.
func relapse_progress() -> float:
	if _phase != Phase.RELAPSE:
		return 1.0
	var total := relapse_duration()
	if total <= 0.0:
		return 1.0
	return clampf(1.0 - _relapse_left / total, 0.0, 1.0)

## Number of successful answers.
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

## Attack cooldown multiplier; 1.0 at zero aggression.
func cooldown_scale() -> float:
	return pow(_stats.cooldown_scale_per_failure, _aggression)

## Restoration progress, 0..1.
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
	# Zero-length relapse returns to pressure immediately.
	if _relapse_left <= 0.0:
		_transition(Phase.PRESSURE)

func _transition(to: Phase) -> void:
	if to == _phase:
		return
	var from := _phase
	_phase = to
	phase_changed.emit(from, to)
