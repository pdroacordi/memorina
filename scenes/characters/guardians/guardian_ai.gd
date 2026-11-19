class_name GuardianAI
extends AIController
## Chooses attacks and movement during the pressure phase; the guardian sets `active` and attack data.
## A string's links are timed by GuardianMoveClock and chosen by GuardianRepertoire; the signals fire per link.

signal attack_telegraphed(attack: GuardianAttack)
signal attack_started(attack: GuardianAttack)
## A link's strike ended or was cancelled; a recovery may follow the string's last.
signal attack_finished(attack: GuardianAttack)

## Horizontal dead band, in px, for movement and facing.
const TURN_BAND := 10.0
## Horizontal exit band, in px, for escaping an overhead player; the entry band is `overhead_band`.
const ESCAPED_BAND := 150.0
## Lunge and minimum escape durations, in seconds.
const STEP_OUT_TIME := 0.55
const ESCAPE_MIN_TIME := 0.9
## Seconds the player must remain within reach before escape ends.
const ESCAPE_RELEASE_TIME := 0.3
## Fraction of the tallest attack height used as the reach release threshold.
const REACH_RELEASE := 0.8
## Comfort-distance multiplier for entering close mode.
const COMFORT_FAR := 1.3
## Seconds a player out of reach overhead may keep it from moving before it throws where he will come down
## ("O pogo é a brecha", user, 2026-10-29; bugs/a-pogo-on-the-frost-golems-head-stops-it-attacking).
const OVERHEAD_PATIENCE := 1.5

## What it is doing about the spacing while a cooldown runs.
const PACE := 0
const GIVE_GROUND := 1
const CLOSE := 2

const APPROACH := 0
const TELEGRAPH := 1
const ATTACK := 2
const HOLD := 3
const RECOVER := 4

## The repertoire, pushed in from GuardianStats by the guardian.
var attacks: Array[GuardianAttack] = []
## Ordinary moves between two scheduled recall moves; 0 disables the schedule.
var recall_after_attacks: int = 0
## False outside the pressure phase: the guardian stands where it is.
var active: bool = false
## Multiplier on every cooldown; the guardian lowers it as the fight's
## aggression rises and its stage advances.
var cooldown_scale: float = 1.0
## The cure stage, pushed in from GuardianFight: moves and links join at their `from_stage`.
var stage: int = 0
## The player owns the recall move's skill, pushed in by the guardian: a move with owned numbers leaves the cadence.
var recall_owned: bool = false
## Multiplier on every link's chance, pushed in from GuardianFight.
var chain_scale: float = 1.0
## Moves in one string, the first included, pushed in from GuardianFight.
var max_links: int = GuardianStage.DEFAULT_MAX_LINKS
## The body stands against a wall or the arena's edge ahead; pushed in each frame by the guardian.
var blocked_ahead: bool = false
## Spacing and pacing, pushed in from GuardianStats by the guardian.
var comfort_distance: float = 140.0
var give_ground_distance: float = 98.0
var pace_time: float = 0.9
var pace_speed: float = 0.5
var step_out_speed: float = 1.7
## Horizontal distance, in px, inside which the player is on top of it: set by the guardian from both bodies' widths.
var overhead_band: float = 0.0
## The move in progress (telegraph, swing or recovery), or null.
var current_attack: GuardianAttack:
	get = _get_current_attack

var _next: GuardianAttack = null
var _clock := GuardianMoveClock.new()
## Moves thrown in the string under way, the first included; 0 between strings.
var _links_done: int = 0
## Ordinary moves made since the last scheduled recall move.
var _since_recall: int = 0
## Which way the guardian is looking when it is not walking.
var _look_direction: float = 1.0
## The escape from under a player: which way, how much lunge is left, how long
## it has run, and how long the player has been back within reach.
var _escaping: bool = false
var _escape_direction: float = 0.0
var _escape_lunge_left: float = 0.0
var _escape_time: float = 0.0
var _escape_release: float = 0.0
## Whether the player is out of reach overhead, held sticky: see _update_reach.
var _above_reach: bool = false
var _above_release: float = 0.0
## Seconds the player has been out of reach overhead with no move thrown.
var _overhead_wait: float = 0.0
## Which way it is pacing while it waits out a cooldown, and for how long.
var _spacing: int = PACE
var _pace_direction: float = 1.0
var _pace_left: float = 0.0
## The guardian asked for the recall move next, cadence or not.
var _recall_requested: bool = false
## The far opinion: rolled once by weight when the player is first far, kept while it reaches; null otherwise.
var _far_pick: GuardianAttack = null
## The last move of the last string; a move that does not repeat is not chosen right after it.
var _last_end: GuardianAttack = null
## `recall_owned` as the strike under way began: a press landing mid-strike does not let a teaching strike chain.
var _owned_at_strike: bool = false

@onready var _body: Node2D = get_parent()
@onready var _sight: EnemySight = get_parent().get_node("EnemySight") as EnemySight


func _ready() -> void:
	_states.add_state(APPROACH, _approach_tick)
	_states.add_state(TELEGRAPH, _telegraph_tick)
	_states.add_state(ATTACK, _attack_tick)
	_states.add_state(HOLD, _hold_tick)
	_states.add_state(RECOVER, _recover_tick)
	_states.transition_to(HOLD)

## Half of both bodies side by side, in px: closer than this the player's feet are over the guardian's body.
static func overhead_band_for(body_width: float, player_width: float) -> float:
	return (body_width + player_width) * 0.5

## The cooldown decays every tick regardless of state, so it is up to date
## before _select_state reads it this same frame (see EnemyAI.tick).
func tick(delta: float) -> void:
	_clock.cool(delta)
	if not _above_reach:
		_overhead_wait = 0.0
	elif not is_attacking():
		_overhead_wait += delta
	_update_look()
	super.tick(delta)

## The side to face: where it walks, else where the player is, so it watches a player it backed away from.
## 0 during a swing and a recovery, so a lunge or leap keeps its side and carries past a player who crosses under it.
func facing_intent() -> float:
	if is_swinging() or is_recovering():
		return 0.0
	if not is_zero_approx(_current_direction):
		return _current_direction
	return _look_direction

## True from a string's first telegraph to the end of its recovery.
func is_attacking() -> bool:
	return _clock.is_busy()

func is_telegraphing() -> bool:
	return _clock.phase == GuardianMoveClock.Phase.TELEGRAPH

func is_swinging() -> bool:
	return _clock.phase == GuardianMoveClock.Phase.STRIKE

## Standing after the string's last link: the punish window.
func is_recovering() -> bool:
	return _clock.phase == GuardianMoveClock.Phase.RECOVER

## Seconds since the swing started; 0 outside one.
func swing_elapsed() -> float:
	return _clock.elapsed()

## The link under way in its string, 0 for the first move.
func link_index() -> int:
	return maxi(_links_done - 1, 0)

## Getting out from under a player standing on it.
func is_escaping() -> bool:
	return _escaping

## The next move is the recall move, whatever the cadence says: the player
## has done their part and is not kept waiting for it. A string under way takes no more links.
func request_recall() -> void:
	if _recall_move() == null:
		return
	_recall_requested = true
	if not is_attacking():
		_pick_next()

## A counter: the cooldown is dropped so the next move starts as soon as it is
## in range. Nothing while a move or its recovery is under way.
func provoke() -> void:
	if is_attacking():
		return
	_clock.provoke()

## Drops the string without a cooldown: lucidity interrupts, it does not rest.
func cancel_attack() -> void:
	if not _clock.is_busy():
		return
	var attack := _clock.move
	var striking := not is_recovering()
	_clock.cancel()
	_links_done = 0
	if striking:
		attack_finished.emit(attack)

func _select_state() -> int:
	if not active or _sight.player == null or attacks.is_empty():
		_escaping = false
		return HOLD
	if is_attacking():
		return _busy_state()
	_refresh_next()
	if not _escaping and _clock.phase == GuardianMoveClock.Phase.READY and _in_range(_next):
		_start_telegraph(_next)
		return _busy_state()
	return APPROACH


## Everything the guardian does between swings.
func _approach_tick(delta: float) -> void:
	var to_player := _sight.player.global_position - _body.global_position
	_update_reach(to_player, delta)
	if _update_escape(to_player, delta):
		return
	if _clock.phase == GuardianMoveClock.Phase.COOLDOWN:
		_hold_spacing(to_player, delta)
		return
	if _in_range(_next):
		_current_direction = 0.0
		return
	# Avoid moving beneath an overhead player the current attacks cannot reach, until patience runs out.
	if _above_reach and not _impatient():
		_hold_spacing(to_player, delta)
		return
	_close_in(to_player)

## Is the player out of reach overhead? Held with hysteresis in BOTH axes: it
## becomes true the moment they rise past the tallest move, and false only
## once they have been clearly back inside it (REACH_RELEASE of the height,
## for ESCAPE_RELEASE_TIME seconds). A pogo crosses that line three times a
## second, and an answer taken from the raw height each frame is the whole of
## the dithering this AI is written to avoid.
func _update_reach(to_player: Vector2, delta: float) -> void:
	var above := -to_player.y
	var tallest := _tallest_reach()
	if above > tallest:
		_above_reach = true
		_above_release = 0.0
		return
	if not _above_reach:
		return
	if above > tallest * REACH_RELEASE:
		_above_release = 0.0
		return
	_above_release += delta
	if _above_release >= ESCAPE_RELEASE_TIME:
		_above_reach = false
		_above_release = 0.0

## The escape from under a player standing on the guardian: entered inside
## `overhead_band`, left only once it is ESCAPED_BAND clear or the player has
## been back within reach for ESCAPE_RELEASE_TIME, and never before
## ESCAPE_MIN_TIME. True while it owns the movement.
func _update_escape(to_player: Vector2, delta: float) -> bool:
	var on_top := absf(to_player.x) <= overhead_band and _above_reach
	if not _escaping:
		if not on_top:
			return false
		_escaping = true
		_escape_direction = -signf(to_player.x) if absf(to_player.x) > 1.0 else _look_direction
		_escape_lunge_left = STEP_OUT_TIME
		_escape_time = 0.0
		_escape_release = 0.0

	_escape_time += delta
	# Out of patience: once stepped out from under him, it goes back to its moves.
	if _impatient() and _escape_lunge_left <= 0.0 and absf(to_player.x) > overhead_band:
		_escaping = false
		return false
	# Require a continuous landing interval to end the escape.
	_escape_release = 0.0 if _above_reach else _escape_release + delta
	if _escape_time >= ESCAPE_MIN_TIME:
		var clear := absf(to_player.x) >= ESCAPED_BAND
		var landed := _escape_release >= ESCAPE_RELEASE_TIME
		if clear or landed:
			_escaping = false
			if landed:
				# Allow an attack immediately after the player lands.
				_clock.provoke()
			return false

	if _escape_lunge_left > 0.0:
		_escape_lunge_left -= delta
		_current_direction = _escape_direction * step_out_speed
	else:
		_hold_spacing(to_player, delta)
	return true

## Walks toward the player, keeping the last side inside the dead band:
## sign() of an x that sits on the guardian's own is the flip-flop this avoids.
func _close_in(to_player: Vector2) -> void:
	if absf(to_player.x) > TURN_BAND:
		_current_direction = signf(to_player.x)

## Holds spacing during cooldown with hysteresis at the comfort-distance thresholds.
func _hold_spacing(to_player: Vector2, delta: float) -> void:
	if comfort_distance <= 0.0:
		_current_direction = 0.0
		return
	var distance := absf(to_player.x)
	var toward := signf(to_player.x) if distance > TURN_BAND else _look_direction
	_update_spacing_mode(distance)
	match _spacing:
		GIVE_GROUND:
			_current_direction = -toward * pace_speed
		CLOSE:
			_current_direction = toward * pace_speed
		_:
			_pace_left -= delta
			if _pace_left <= 0.0:
				_pace_left = pace_time
				_pace_direction = -_pace_direction
			_current_direction = _pace_direction * pace_speed

func _update_spacing_mode(distance: float) -> void:
	match _spacing:
		GIVE_GROUND:
			if distance >= comfort_distance:
				_spacing = PACE
		CLOSE:
			if distance <= comfort_distance:
				_spacing = PACE
		_:
			if distance < give_ground_distance:
				_spacing = GIVE_GROUND
			elif distance > comfort_distance * COMFORT_FAR:
				_spacing = CLOSE

func _telegraph_tick(delta: float) -> void:
	_current_direction = 0.0
	if _clock.tick(delta) == GuardianMoveClock.Phase.TELEGRAPH:
		_owned_at_strike = recall_owned
		attack_started.emit(_clock.move)

func _attack_tick(delta: float) -> void:
	_current_direction = 0.0
	if _clock.tick(delta) == GuardianMoveClock.Phase.STRIKE:
		_end_strike()

func _recover_tick(delta: float) -> void:
	_current_direction = 0.0
	_clock.tick(delta)

func _hold_tick(_delta: float) -> void:
	_current_direction = 0.0

func _update_look() -> void:
	if _sight.player == null:
		return
	var dx := _sight.player.global_position.x - _body.global_position.x
	if absf(dx) > TURN_BAND:
		_look_direction = signf(dx)


func _get_current_attack() -> GuardianAttack:
	return _clock.move if _clock.is_busy() else null

func _busy_state() -> int:
	match _clock.phase:
		GuardianMoveClock.Phase.TELEGRAPH:
			return TELEGRAPH
		GuardianMoveClock.Phase.STRIKE:
			return ATTACK
	return RECOVER

func _start_telegraph(attack: GuardianAttack) -> void:
	_overhead_wait = 0.0
	_far_pick = null
	_current_direction = 0.0
	_links_done = 1
	_clock.start(attack)
	_announce(attack)

## The telegraph's signal, and the strike's at once for a move with no telegraph.
func _announce(attack: GuardianAttack) -> void:
	attack_telegraphed.emit(attack)
	if is_swinging():
		_owned_at_strike = recall_owned
		attack_started.emit(attack)

## A strike ran out: the next link of the string, or the string's end.
func _end_strike() -> void:
	var attack := _clock.move
	var link := GuardianRepertoire.next_link(attack, stage, chain_scale, _links_done, max_links, _in_range,
			blocked_ahead, _recall_requested, _roll, _owned_at_strike)
	if link == null:
		_finish_string(attack)
		return
	_links_done += 1
	_clock.chain(link)
	attack_finished.emit(attack)
	_announce(link)

## The string's last strike ended: its recovery, then its cooldown. The recall cadence counts the string once.
func _finish_string(attack: GuardianAttack) -> void:
	_clock.rest(attack.recovery, attack.cooldown * cooldown_scale)
	_links_done = 0
	if attack.recall != null:
		_since_recall = 0
		_recall_requested = false
	else:
		_since_recall += 1
	_last_end = attack
	_pick_next()
	attack_finished.emit(attack)

## A move reaches inside a box, not a radius: `attack_range` to the side and
## `attack_height` up or down from its own feet.
func _in_range(attack: GuardianAttack) -> bool:
	if attack == null:
		return false
	var to_player := _sight.player.global_position - _body.global_position
	if absf(to_player.x) > attack.attack_range:
		return false
	if absf(to_player.y) <= attack.attack_height:
		return true
	# Out of patience, it throws where he will come down, never from under him.
	return _impatient() and absf(to_player.x) > overhead_band

func _roll() -> float:
	return randf()

func _impatient() -> bool:
	return _overhead_wait >= OVERHEAD_PATIENCE

func _tallest_reach() -> float:
	var tallest := 0.0
	for attack: GuardianAttack in _available():
		tallest = maxf(tallest, attack.attack_height)
	return tallest

## The moves that have joined the set at this stage.
func _available() -> Array[GuardianAttack]:
	return GuardianRepertoire.available(attacks, stage)

## The available moves a pick may choose: all but a last string's end that does not repeat.
func _choosable() -> Array[GuardianAttack]:
	var pool := _available()
	if _last_end != null and not _last_end.repeats and pool.size() > 1:
		pool.erase(_last_end)
	return pool

## A move's pick weight; a recall move whose skill is owned uses its owned weight when it has one.
func _weight_of(attack: GuardianAttack) -> float:
	return attack.weight_for(recall_owned)

## The lowest reach up among the moves a pick may choose: no move is preferred for its height below it.
func _lowest_reach() -> float:
	var lowest := INF
	for attack: GuardianAttack in _choosable():
		if _weight_of(attack) > 0.0:
			lowest = minf(lowest, attack.attack_height)
	return lowest

## Selects a due recall, a situational move, or a weighted move; weight 0 only permits scheduling.
func _pick_next() -> void:
	var recall_move := _recall_move()
	var due := recall_after_attacks > 0 and _since_recall >= recall_after_attacks
	if recall_move != null and (due or _recall_requested):
		_next = recall_move
		return
	var situational := _situational_pick()
	_next = situational if situational != null else _weighted_pick()

## Keeps the selected move until a situational condition changes.
func _refresh_next() -> void:
	if _next == null:
		_pick_next()
		return
	var recall_move := _recall_move()
	var due := recall_after_attacks > 0 and _since_recall >= recall_after_attacks
	if recall_move != null and (due or _recall_requested):
		_next = recall_move
		return
	var opinion := _situational_pick()
	if opinion != null:
		_next = opinion

## Returns an attack suited to an overhead or distant player, or null when neither applies.
func _situational_pick() -> GuardianAttack:
	var to_player := _sight.player.global_position - _body.global_position
	var above := -to_player.y
	var distance := absf(to_player.x)
	# Only above the lowest reach, where height can rule a move out; level feet differ by float noise (bugs/the-sun-guardians-roar-never-fires).
	if above > _lowest_reach():
		var reaches_up: GuardianAttack = null
		for attack: GuardianAttack in _choosable():
			if _weight_of(attack) <= 0.0 or attack.attack_height < above:
				continue
			if distance > attack.attack_range:
				continue
			if reaches_up == null or attack.attack_height > reaches_up.attack_height:
				reaches_up = attack
		if reaches_up != null:
			return reaches_up
	# Only past the comfort band; closer in the weighted roll decides.
	if comfort_distance > 0.0 and distance > comfort_distance * COMFORT_FAR:
		return _far_opinion(distance)
	_far_pick = null
	return null

## A move that reaches a far player, chosen by weight once and kept while it still reaches and is available.
func _far_opinion(distance: float) -> GuardianAttack:
	var reaching: Array[GuardianAttack] = []
	for attack: GuardianAttack in _choosable():
		if _weight_of(attack) > 0.0 and attack.attack_range >= distance:
			reaching.append(attack)
	if _far_pick != null and reaching.has(_far_pick):
		return _far_pick
	# A single reaching move needs no roll, so the random stream is spent only on a choice.
	_far_pick = reaching[0] if reaching.size() == 1 else _weighted_from(reaching)
	return _far_pick

func _weighted_pick() -> GuardianAttack:
	var pool := _choosable()
	# guardian_move_graph_test: every guardian has a move from the first stage.
	assert(not pool.is_empty(), "%s: no move has joined at stage %d" % [_body.name, stage])
	return _weighted_from(pool)

## One of `pool` by weight.
func _weighted_from(pool: Array[GuardianAttack]) -> GuardianAttack:
	if pool.is_empty():
		return null
	var total := 0.0
	for attack: GuardianAttack in pool:
		total += maxf(_weight_of(attack), 0.0)
	if total <= 0.0:
		return pool[0]
	var roll := randf() * total
	for attack: GuardianAttack in pool:
		roll -= maxf(_weight_of(attack), 0.0)
		if _weight_of(attack) > 0.0 and roll <= 0.0:
			return attack
	return pool[pool.size() - 1]

## The move on the recall cadence; one whose skill is owned and that has owned numbers is an ordinary move instead.
func _recall_move() -> GuardianAttack:
	for attack: GuardianAttack in _available():
		if attack.recall != null and not (recall_owned and attack.leaves_cadence_when_owned()):
			return attack
	return null
