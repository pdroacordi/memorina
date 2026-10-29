class_name MoveClock
extends RefCounted
## Times one EnemyMove through telegraph, active, recovery and cooldown; pure, ticked by EnemyAI.

signal phase_entered(phase: Phase)

enum Phase { READY, TELEGRAPH, ACTIVE, RECOVER, COOLDOWN }

var phase: Phase = Phase.READY
## The move being timed; null once READY again.
var move: EnemyMove = null

## Seconds left in the current phase.
var _left: float = 0.0


## Starts `next` from READY; refused in any other phase.
func start(next: EnemyMove) -> bool:
	if phase != Phase.READY or next == null:
		return false
	move = next
	_enter(Phase.TELEGRAPH, move.telegraph)
	return true

## Advances by `delta` s; time left over from a phase carries into the next.
func tick(delta: float) -> void:
	if phase == Phase.READY:
		return
	_left -= delta
	while phase != Phase.READY and _left <= 0.0:
		var spill := -_left
		_advance()
		_left -= spill

## A wall or a ledge cut the hit window short.
func end_active() -> void:
	if phase == Phase.ACTIVE:
		_enter(Phase.RECOVER, move.recovery)

## Drops the move but keeps its cooldown, so a flinch cannot be answered at once.
func cancel() -> void:
	if is_busy():
		_enter(Phase.COOLDOWN, move.cooldown)

## TELEGRAPH, ACTIVE or RECOVER: the move holds the creature.
func is_busy() -> bool:
	return phase == Phase.TELEGRAPH or phase == Phase.ACTIVE or phase == Phase.RECOVER

func _advance() -> void:
	match phase:
		Phase.TELEGRAPH:
			_enter(Phase.ACTIVE, move.active)
		Phase.ACTIVE:
			_enter(Phase.RECOVER, move.recovery)
		Phase.RECOVER:
			_enter(Phase.COOLDOWN, move.cooldown)
		Phase.COOLDOWN:
			move = null
			_enter(Phase.READY, 0.0)

func _enter(next: Phase, seconds: float) -> void:
	phase = next
	_left = seconds
	phase_entered.emit(next)
