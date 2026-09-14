class_name AttackComponent
extends Node
## Generic N-phase combo engine: walks an index into an AttackStats' phases
## array, driven by discrete attack-input calls rather than polling. Knows
## nothing about who owns it - no items, no save data, no idle/run context -
## so it mounts on Ivo exactly the same way it would on a boss.

signal phase_started(phase_index: int, phase_data: AttackPhaseData)
signal attack_finished

## The gate is pushed onto this component at the moment an attack is
## attempted, so it never learns why it might be disabled - matching every
## other gated component in this codebase.
@export var enabled: bool = true
## How long a press survives while the owner's other gates (rolling,
## recovering, knockback) block the attempt - matching RollComponent's/
## JumpComponent's own input-buffer window, so a press near the end of a
## roll still fires the moment control returns instead of being dropped.
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

## Lets the owner skip the whole attempt - including querying its own gates -
## on the frames where no attack was asked for, which is most of them.
func has_buffered_attack() -> bool:
	return _buffer_timer > 0.0

## Called once the owner's gates have cleared for a buffered press. Starts a
## fresh sequence if none is running; otherwise, only registers as a
## combo-continue when the press lands inside the current phase's trailing
## combo_window - an early mash does not queue up the next hit.
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

## Drops the sequence mid-phase (e.g. the owner got hit): otherwise the phase
## timer keeps running through the interruption and the swing's hitbox timing
## ends up out of step with whatever clip resumes afterwards.
func cancel() -> void:
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
