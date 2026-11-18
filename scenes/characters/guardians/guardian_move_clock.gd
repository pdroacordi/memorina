class_name GuardianMoveClock
extends RefCounted
## Times a guardian string through telegraph, strike, recovery and cooldown; pure, ticked by GuardianAI.
## Each phase starts with its full length on the frame it is entered: no time spills over (guardian_ai_timeline_test).

enum Phase { READY, TELEGRAPH, STRIKE, RECOVER, COOLDOWN }

var phase: Phase = Phase.READY
## The move being thrown or recovered from; null in READY and COOLDOWN.
var move: GuardianAttack = null

## Seconds left in the current phase.
var _left: float = 0.0
## Cooldown that follows the recovery under way.
var _cooldown_after: float = 0.0


## Starts `next`'s telegraph from READY; refused in any other phase. A zero telegraph enters STRIKE at once.
func start(next: GuardianAttack) -> bool:
	if phase != Phase.READY or next == null:
		return false
	_telegraph(next)
	return true

## Advances TELEGRAPH, STRIKE or RECOVER by `delta` s. Returns the phase that ran out, or READY if none did:
## TELEGRAPH moves on to STRIKE, RECOVER to COOLDOWN, and STRIKE waits at its end for `chain` or `rest`.
func tick(delta: float) -> Phase:
	if not is_busy():
		return Phase.READY
	_left -= delta
	if _left > 0.0:
		return Phase.READY
	match phase:
		Phase.TELEGRAPH:
			_strike()
			return Phase.TELEGRAPH
		Phase.STRIKE:
			_left = 0.0
			return Phase.STRIKE
		Phase.RECOVER:
			_cool(_cooldown_after)
			return Phase.RECOVER
	return Phase.READY

## Advances COOLDOWN by `delta` s; READY once it runs out.
func cool(delta: float) -> void:
	if phase != Phase.COOLDOWN:
		return
	_left -= delta
	if _left <= 0.0:
		_ready_up()

## From the end of a strike, the next link's telegraph with no recovery or cooldown between.
func chain(next: GuardianAttack) -> void:
	if phase == Phase.STRIKE and next != null:
		_telegraph(next)

## From the end of a strike, ends the string: `recovery` s standing, then `cooldown` s.
func rest(recovery: float, cooldown: float) -> void:
	if phase != Phase.STRIKE:
		return
	if recovery > 0.0:
		phase = Phase.RECOVER
		_left = recovery
		_cooldown_after = cooldown
		return
	_cool(cooldown)

## Drops the cooldown so the next move may start; a recovery is never cut short.
func provoke() -> void:
	if phase == Phase.COOLDOWN:
		_ready_up()

## Clears everything with no cooldown: lucidity interrupts, it does not rest.
func cancel() -> void:
	_ready_up()

## TELEGRAPH, STRIKE or RECOVER: the string holds the guardian.
func is_busy() -> bool:
	return phase == Phase.TELEGRAPH or phase == Phase.STRIKE or phase == Phase.RECOVER

## Scaled s since the strike began; 0 outside one.
func elapsed() -> float:
	return move.duration - _left if phase == Phase.STRIKE else 0.0

func _telegraph(next: GuardianAttack) -> void:
	move = next
	phase = Phase.TELEGRAPH
	_left = next.telegraph
	if next.telegraph <= 0.0:
		_strike()

func _strike() -> void:
	phase = Phase.STRIKE
	_left = move.duration

func _cool(seconds: float) -> void:
	move = null
	if seconds <= 0.0:
		_ready_up()
		return
	phase = Phase.COOLDOWN
	_left = seconds

func _ready_up() -> void:
	move = null
	phase = Phase.READY
	_left = 0.0
	_cooldown_after = 0.0
