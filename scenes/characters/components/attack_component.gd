class_name AttackComponent
extends Node
## Runs an AttackStats phase sequence from discrete attack-input calls.

signal phase_started(phase_index: int, phase_data: AttackPhaseData)
signal attack_finished

@export var enabled: bool = true
@export var attack_buffer_max: float = 0.12

var current_phase_index: int = -1

var _phase_timer: float = 0.0
var _buffer_timer: float = 0.0
var _buffered_next: bool = false
var _active_stats: AttackStats


func is_attacking() -> bool:
	return current_phase_index >= 0

func current_phase() -> AttackPhaseData:
	return _active_stats.phases[current_phase_index] if is_attacking() else null

func buffer_attack() -> void:
	_buffer_timer = attack_buffer_max

func has_buffered_attack() -> bool:
	return _buffer_timer > 0.0

func try_attack(stats: AttackStats) -> bool:
	if not enabled or stats == null or stats.phases.is_empty():
		return false

	_buffer_timer = 0.0

	if not is_attacking():
		_start_phase(stats, 0)
		return true

	var phase: AttackPhaseData = current_phase()
	if _phase_timer <= phase.combo_window:
		_buffered_next = true
	return false

func tick_timers(delta: float) -> void:
	_buffer_timer = maxf(_buffer_timer - delta, 0.0)

	if not is_attacking():
		return

	_phase_timer -= delta
	if _phase_timer > 0.0:
		return

	var next_index: int = current_phase_index + 1
	if _buffered_next and next_index < _active_stats.phases.size():
		_start_phase(_active_stats, next_index)
	else:
		_finish()

## Drops the sequence mid-phase; a phase timer left running desyncs the hitbox from the next clip.
func cancel() -> void:
	# Interruptions must stop the phase timer so resumed clips keep hitbox timing aligned.
	if is_attacking():
		_finish()

func _start_phase(stats: AttackStats, index: int) -> void:
	_active_stats = stats
	current_phase_index = index
	_buffered_next = false

	var phase: AttackPhaseData = stats.phases[index]
	_phase_timer = phase.duration
	phase_started.emit(index, phase)

func _finish() -> void:
	current_phase_index = -1
	_active_stats = null
	_buffered_next = false
	attack_finished.emit()
