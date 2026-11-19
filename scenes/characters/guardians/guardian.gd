class_name Guardian
extends Character
## Guardian encounters follow docs/design/02_mecanicas.md sections 3 and 4.

signal restored(guardian: Guardian)
## Emitted when the lucidity leap starts or lands; scenes can attach dust effects.
signal leapt(position: Vector2)
signal landed(position: Vector2, impact_speed: float)
## The leap landed and the call is staged: `cycle` answers are in, `after_failure` if the last one failed.
signal lucid_landed(cycle: int, after_failure: bool)
signal call_note_sung(index: int)
## The call closed: answered, failed, abandoned or restored.
signal call_ended
## The fight's phase moved; re-emitted from GuardianFight for listeners outside the guardian (GuardianMusic).
signal phase_changed(from: GuardianFight.Phase, to: GuardianFight.Phase)
## A hit landed in the pressure phase.
signal struck

## Guardians group used for encounter queries.
const GROUP := &"guardians"
const FAIL_BURST_TIME := 0.3
const FAIL_BURST_HZ := 12.0
## How much of the way to full the pressure's hits bring the colour.
const PRESSURE_CLIMB := 0.35
## The beat a good answer holds the guardian bright before it drains.
const RELAPSE_HOLD := 0.3
## Px a no-contact lunge must have run before a wall stop spares Ivo: one begun at the wall still hits an Ivo there.
const WALL_RUN := 32.0

@export var stats: GuardianStats
@export var terminal_velocity: float = 500.0
## Hit tint; the script restores it because Sprite2D.modulate has no RESET track.
@export var hit_flash_color: Color = Color(1.0, 0.55, 0.45)
@export var hit_flash_time: float = 0.12
## Tint used while an attack is telegraphed.
@export var telegraph_color: Color = Color(1.0, 0.85, 0.35)
@export var telegraph_pulse_time: float = 0.12
## Lucidity opening: a flash brighter than white.
@export var lucid_flash_color: Color = Color(1.6, 1.6, 1.6)
## Each note of the call swells the shield's radius by this factor and lifts
## the sprite by `note_bob` pixels, both easing back before the next note.
@export var note_swell: float = 1.5
@export var note_bob: float = 4.0

## Leap height and horizontal travel distance, in world pixels.
@export var lucidity_leap_height: float = 340.0
## Target separation from Ivo, in world pixels.
@export var lucidity_leap_distance: float = 440.0
## Real seconds before an unlanded leap ends.
@export var lucidity_leap_timeout: float = 3.0
## Delay before the leap, in seconds, so the guardian does not jump with a recalled move.
@export var lucidity_delay: float = 1.0
## Minimum landing distance from arena edges, in world pixels.
@export var lucidity_leap_margin: float = 96.0
## Arena path used to constrain the landing; NodePath resolves across scene instances.
@export var arena_path: NodePath
## How hard the landing hits the camera.
@export var lucidity_leap_shake: float = 6.0
## The shape of the guardian's pulse during the lesson: slow and wide, so the
## colour spreads from it for as long as the track plays.
@export var lesson_pulse: PulseStats
## The id a cutscene places, faces and frames it by; empty keeps it out of cutscenes (systems/cutscenes).
@export var cutscene_id: StringName = &""

var _fight: GuardianFight
var _player: Player
var _tremble_time: float = 0.0
var _telegraph_tween: Tween
var _breath_tween: Tween
var _bob_tween: Tween
## 1.0 on the note, easing to 0.0 before the next: the call's breathing.
var _breath: float = 0.0
## Hits taken since the guardian last made a move; the counter reads it.
var _hits_since_move: int = 0
## Notes of the answer landed right so far.
var _answered_notes: int = 0
## Shield amount as the relapse began, to drain from.
var _relapse_from: float = 0.0
## The camera holds this guardian with Ivo, from take-off.
var _framed: bool = false
## The lights and the call are on this guardian, from the landing.
var _staged: bool = false
## Counting down the beat between the opening blow and the leap.
var _lucidity_wait: float = 0.0
## In the air on the way to lucidity: the AI is off and physics owns it.
var _leaping: bool = false
var _leap_left: float = 0.0
## The floor it left: everything ABOVE that line is passed through on the way up.
var _leap_floor_y: float = 0.0
## The mask it collides with when nothing passes it through the world.
var _solid_mask: int = 0
## The floor it last stood on, for spawns placed on the floor.
var _floor_y: float = 0.0
## One life note per string: the move box, the contact box and the spawns refuse a link's hit on a target the string
## already hurt.
var _string_gate := HitGate.new()
## Ivo died: no clock of the fight advances, the AI stays off and nothing is staged on him until the world is rebuilt.
var _player_dead: bool = false
## The body spares an Ivo a no-contact move carried it onto (GuardianBodyContact).
var _body_contact := GuardianBodyContact.new()
## The string under way has a move whose own box is its only hit.
var _string_spares_body: bool = false
## Where the strike under way began: a wall stop spares Ivo only after a run of WALL_RUN px to it.
var _strike_start_x: float = 0.0
var _shield_rest_radius: float = 0.0
var _sprite_rest: Vector2 = Vector2.ZERO
## Seconds of the flinch left: the facing it took on the hit is held until the hurt clip ends.
var _flinch_left: float = 0.0
## The recall move under way whose recall waits for its `recall_lead`; null otherwise.
var _recall_due: GuardianAttack = null
## From restoration to the end of the lesson it starts.
var _teaching: bool = false
## The lesson ended and the stage holds until `perform_end` has played.
var _bowing: bool = false

@onready var _ai                : GuardianAI = $AI
@onready var _mover             : GuardianMover = $Mover
@onready var _spawner           : GuardianSpawner = $Spawner
@onready var _locomotion        : LocomotionComponent = $Locomotion
@onready var _call              : PhraseCall = $Call
## The final battle's strategy; null on every guardian but the mentor (GRD-06).
@onready var _finale            : GuardianFinale = get_node_or_null(^"Finale") as GuardianFinale
@onready var _arena_trigger     : PlayerProximityTrigger = $ArenaTrigger
@onready var _shield            : GreyhushShield = $GreyhushShield
@onready var _hitbox            : Hitbox = $Hitbox
@onready var _contact           : Hitbox = $ContactHitbox
@onready var _pulse_emitter     : PulseEmitter = $PulseEmitter
@onready var _arena             : Arena = get_node_or_null(arena_path) as Arena
@onready var _sight             : EnemySight = $EnemySight
@onready var _body_sounds       : BodySounds = $BodySounds
@onready var _animation_tree    : AnimationTree = %AnimationTree


## Whether any guardian's fight is on at `point`.
static func fight_at(tree: SceneTree, point: Vector2) -> bool:
	for node: Node in tree.get_nodes_in_group(GROUP):
		var guardian := node as Guardian
		if guardian != null and guardian.is_fighting_at(point):
			return true
	return false

## The sight radius, px, that covers `arena` from any point in it; never below `current`.
static func sight_radius_for(current: float, arena: Rect2) -> float:
	return maxf(current, arena.size.length())

func _enter_tree() -> void:
	add_to_group(GROUP)
	if cutscene_id != &"":
		add_to_group(CutsceneCast.BODY_GROUP)

func _ready() -> void:
	super()
	assert(stats != null and stats.song != null, "%s has no GuardianStats with a song." % name)
	_fight = GuardianFight.new(stats)
	_fight.phase_changed.connect(_on_phase_changed)
	_fight.opening_ended.connect(_on_opening_ended)
	_fight.set_recall_pending(_recall_still_needed())
	_ai.recall_owned = not _recall_still_needed()
	_ai.attacks = stats.attacks
	_ai.recall_after_attacks = stats.recall_after_attacks
	_ai.recent_strings = stats.recent_strings
	_ai.far_walks_in = stats.far_walks_in
	_ai.comfort_distance = stats.comfort_distance
	_ai.give_ground_distance = stats.give_ground_distance
	_ai.pace_time = stats.pace_time
	_ai.pace_speed = stats.pace_speed
	_ai.step_out_speed = stats.step_out_speed
	_body_sounds.sounds = stats.sounds
	struck.connect(_body_sounds.on_struck)
	_ai.attack_telegraphed.connect(_on_attack_telegraphed)
	_ai.attack_started.connect(_on_attack_started)
	_ai.attack_finished.connect(_on_attack_finished)
	_call.note_sounded.connect(_on_call_note_sounded)
	_call.finished.connect(_on_call_finished)
	_arena_trigger.stays_open = true
	_arena_trigger.player_entered.connect(_on_player_entered)
	_shield_rest_radius = _shield.radius
	_sprite_rest = _sprite.position
	_solid_mask = collision_mask
	_fit_sight_to_arena()
	_floor_y = global_position.y
	_hitbox.gate = _string_gate
	_contact.gate = _string_gate
	_spawner.gate = _string_gate
	_push_tuning()
	assert((stats.finale != null) == (_finale != null), "%s: FinaleStats and a Finale child go together" % name)
	if (_finale.is_restored() if _finale != null else SaveSystem.is_guardian_restored(stats.id)):
		_fight.restore_silently()
	_assert_clip_durations()
	_update_shield(0.0)

func _process_motion(delta: float) -> void:
	if _leaping:
		# Ballistic: the horizontal speed set at take-off carries it across.
		velocity.y = minf(velocity.y + base_gravity() * delta, terminal_velocity)
		# An arena has a ceiling, and this arc is meant to leave the frame through it.
		_pass_through_above(_leap_floor_y)
		return
	_flinch_left = maxf(_flinch_left - delta, 0.0)
	if _fight.phase() == GuardianFight.Phase.PRESSURE and _player_in_arena():
		_ai.blocked_ahead = _mover.against_wall(arena_bounds())
		_ai.floor_burning = _spawner.floor_burning()
		_ai.tick(delta)
		# Where it LOOKS, not where it walks: a guardian backing out from under
		# a player keeps watching him, and an x sitting on its own never makes
		# it turn on the spot. A flinch keeps the side it was hit from.
		if _flinch_left <= 0.0 or _ai.is_attacking():
			face_towards(_ai.facing_intent())
		_locomotion.ground_update(delta, _ai.direction)
		if _ai.is_recovering() and is_instance_valid(_player) and GuardianBodyContact.skid_stops(
				_player.global_position.x - global_position.x, velocity.x, _ai.overhead_band):
			velocity.x = 0.0
		if _ai.is_swinging():
			_mover.drive(delta, _ai.swing_elapsed())
			_open_due_recall()
			_spare_against_wall()
	else:
		_locomotion.ground_update(delta, 0.0)
		if _fight.phase() == GuardianFight.Phase.RESTORED:
			_face_seen_player()
	if _mover.passes_through():
		_pass_through_above(_mover.take_off_y())
	elif collision_mask != _solid_mask:
		collision_mask = _solid_mask
	if not is_on_floor() and not _mover.owns_vertical():
		velocity.y = minf(velocity.y + base_gravity() * delta, terminal_velocity)

func _after_move(delta: float) -> void:
	_mover.after_move()
	if is_on_floor():
		_floor_y = global_position.y
	if _fight.phase() == GuardianFight.Phase.PRESSURE:
		_spawner.tick(delta, _mover.just_landed())
	_end_string_after_recovery()
	_body_contact.tick(delta, _player_inside_body())
	if is_instance_valid(_player) and not _player_in_arena():
		_abandon_call()
	if _bowing and not _still_bowing():
		_bowing = false
		_unstage()
	if _lucidity_wait > 0.0 and not _player_dead:
		_lucidity_wait = maxf(_lucidity_wait - delta, 0.0)
		if is_zero_approx(_lucidity_wait):
			_lucidity_wait = 0.0
			_begin_lucidity_leap()
	if _leaping:
		_leap_left -= delta
		# velocity.y >= 0 keeps the take-off frame, where the feet have not
		# left the floor yet, from reading as an arrival.
		if (is_on_floor() and velocity.y >= 0.0) or _leap_left <= 0.0:
			_finish_lucidity_leap()
	# The window ran out: the same failure as a wrong note, closed the same way. A dead Ivo stops every clock.
	if not _player_dead and _fight.tick(delta):
		_close_call(false)
	elif not _player_dead and _fight.is_window_open():
		# The one clock, read where it is ticked. Nothing downstream keeps a
		# copy of it, so the cadence is nobody's business but the meter's.
		_player.update_call_window(_fight.window_fraction())
	# Dangerous to touch only while it fights; a lucid or restored guardian can
	# be walked up to. Not RESET-owned, so this write is the script's.
	_contact.monitoring = _fight.phase() == GuardianFight.Phase.PRESSURE and body_hurts() and not _player_dead
	_update_shield(delta)

## Leaving a room during a call must stop the phrase and release its camera state.
func _notification(what: int) -> void:
	if what == NOTIFICATION_DISABLED or what == NOTIFICATION_EXIT_TREE:
		_abandon_call()

#############################################
##  S T A T E   Q U E R I E S              ##
#############################################
## Read by GuardianAnimationResolver; no animation logic here.

func phase() -> GuardianFight.Phase:
	return _fight.phase()

## True when this guardian is active and `point` is inside its arena.
func is_fighting_at(point: Vector2) -> bool:
	if _fight == null or phase() in [GuardianFight.Phase.DORMANT, GuardianFight.Phase.RESTORED]:
		return false
	return _arena == null or _arena.bounds().has_point(point)

## How tall the body standing there is, in world pixels: the stage asks, so
## a sheet hung above the pair is never hung on a golem's head.
func body_height() -> float:
	return body_rect().size.y

func is_attacking() -> bool:
	return _ai.is_attacking()

## The body hurts on touch, unless the move under way leaves its own box as its only hit (GuardianAttack.body_contact)
## or a blink has taken it out of the world.
func body_hurts() -> bool:
	if _mover.is_intangible() or _body_contact.holds():
		return false
	return _ai.current_attack == null or _ai.current_attack.body_contact

## The wind-up before a swing: still, announced, not yet dangerous.
func is_telegraphing() -> bool:
	return _ai.is_telegraphing()

func is_swinging() -> bool:
	return _ai.is_swinging()

## Standing after a string's last link: the punish window.
func is_recovering() -> bool:
	return _ai.is_recovering()

func current_attack() -> GuardianAttack:
	return _ai.current_attack

## The Ivo this fight began against; null before it begins.
func fought_player() -> Player:
	return _player if is_instance_valid(_player) else null

## Where the ground runs out; an empty rect when no arena is assigned.
func arena_bounds() -> Rect2:
	return _arena.bounds() if _arena != null else Rect2()

## Where a spawn fires from and aims at now: the feet, the facing, Ivo's feet, the arena and the floor.
func spawn_context() -> SpawnContext:
	var target := _player.global_position if is_instance_valid(_player) else global_position + Vector2(facing, 0.0)
	var ctx := SpawnContext.make(global_position, facing, target, arena_bounds(), _floor_y)
	ctx.landing = _mover.landing(global_position)
	return ctx

## Hits counted toward the next lucidity window, 0..1.
func pressure_progress() -> float:
	return _fight.pressure_progress()

func wants_to_move() -> bool:
	return not is_zero_approx(_ai.direction)

## In the lucidity leap's ballistic arc, from take-off to touchdown.
func is_leaping() -> bool:
	return _leaping

## Seconds until the lucidity leap takes off; INF when none is pending.
func seconds_to_leap() -> float:
	return _lucidity_wait if _lucidity_wait > 0.0 else INF

## The call is sounding, from its first note to its last.
func is_sounding() -> bool:
	return _call.is_calling()

## The lesson its restoration started is in its lead-in or playing its track; the mentor, while his restoration scene
## plays.
func is_teaching() -> bool:
	if _finale != null:
		return _finale.is_performing()
	return _teaching and is_instance_valid(_player) and _player.is_in_lesson()

## The fight's phase logic, for the Finale (GRD-06).
func fight() -> GuardianFight:
	return _fight

## Sings `song`'s phrase after the lead-in; an open window is held until the phrase ends, when the call reopens it.
func call_phrase(song: Song) -> void:
	_call.play(song.notes, stats.call_lead_in)
	if _fight.is_window_open():
		_fight.open_window(stats.call_lead_in + _call.duration())

## A lucidity that ends with no answer, cycle or relapse: back to pressure where the bodies stand (the revelation).
func end_lucidity_without_answer() -> void:
	_fight.dismiss()
	_close_call(true)
	_unstage()

func freeze_frame(seconds: float) -> void:
	if is_instance_valid(_player):
		_player.request_freeze_frame(seconds)

#############################################
##  T H E   F I G H T                      ##
#############################################

func _on_player_entered() -> void:
	if _fight.phase() != GuardianFight.Phase.DORMANT:
		return
	_player = get_tree().get_first_node_in_group(Player.GROUP) as Player
	if _player == null:
		return
	# A swordless Ivo stays free to walk out: no fight, so no FightWall closes, and the trigger stays open for his
	# return (STORY-33).
	if not _player.is_armed():
		_player = null
		return
	_arena_trigger.close()
	_player.call_answered.connect(_on_call_answered)
	if _finale != null:
		_player.call_mixed.connect(_on_call_mixed)
	_player.call_progress.connect(_on_call_progress)
	_player.sequence_failed.connect(_on_player_sequence_failed)
	_player.skill_recalled.connect(_on_skill_recalled)
	_player.died.connect(_on_player_died)
	_ai.overhead_band = GuardianAI.overhead_band_for(body_rect().size.x, _player.body_rect().size.x)
	_fight.begin()
	_ai.active = not _fight.is_opening()
	# The mentor has no Enums.Guardian id: the hatch's gate counts the four (architecture/grd-06-final-battle).
	if _finale == null:
		SaveSystem.meet_guardian(stats.id)

## Hazards do not affect guardians; hits destabilise them without damage.
func receive_hazard(_hazard: HazardZone) -> void:
	pass

func _on_hit_received(_damage: int, _knockback: Vector2, _source: Node2D) -> void:
	if _fight.phase() != GuardianFight.Phase.PRESSURE or _mover.is_intangible():
		return
	_just_hit = true
	_flash(hit_flash_color)
	struck.emit()
	_flinch_from(_source)
	if _fight.register_hit():
		_open_lucidity()
		return
	if _fight.is_saturated():
		_ai.request_recall()
	_hits_since_move += 1
	if stats.counter_after_hits > 0 and _hits_since_move >= stats.counter_after_hits \
			and not _ai.is_attacking():
		_hits_since_move = 0
		_ai.provoke()

func _flash(color: Color) -> void:
	flash(color, hit_flash_time)

## Outside a move the hit plays the hurt clip: it turns to what hit it and keeps that side until the clip ends.
func _flinch_from(source: Node2D) -> void:
	if _ai.is_attacking():
		return
	var from := source if is_instance_valid(source) else _player
	if from != null:
		var dx := from.global_position.x - global_position.x
		if absf(dx) > GuardianAI.TURN_BAND:
			face_towards(dx)
	_flinch_left = _animation_driver.clip_length(GuardianAnimationResolver.HURT)

## A restored guardian watches Ivo while he is in sight, outside the dead band under it.
func _face_seen_player() -> void:
	if _sight.player == null:
		return
	var dx := _sight.player.global_position.x - global_position.x
	if absf(dx) > GuardianAI.TURN_BAND:
		face_towards(dx)

## A move winds up: the guardian squares up to Ivo (a charge thrown the way
## it happened to be facing goes into a wall), or turns from the wall a bounce
## is thrown against, and the sprite pulses until the swing begins.
func _on_attack_telegraphed(_attack: GuardianAttack) -> void:
	_hits_since_move = 0
	if _ai.link_index() == 0:
		_string_gate.begin_string()
		_string_spares_body = false
		# A new string's own body_contact rules from its wind-up; the last one's grace does not run into it.
		_body_contact.clear()
	else:
		# A link starts where the last one ended: a lunge's speed does not carry it on through the wind-up.
		velocity.x = 0.0
	if _ai.turns_from_wall():
		face_towards(-facing)
	elif _player != null:
		face_towards(signf(_player.global_position.x - global_position.x))
	_stop_telegraph()
	_telegraph_tween = create_tween().set_loops()
	_telegraph_tween.tween_property(_sprite, "modulate", telegraph_color, telegraph_pulse_time)
	_telegraph_tween.tween_property(_sprite, "modulate", Color.WHITE, telegraph_pulse_time)

## The swing begins: the hitbox takes the move's numbers (its exports are not RESET-owned) and a recall move opens
## the recall while the player still lacks its skill.
func _on_attack_started(attack: GuardianAttack) -> void:
	_stop_telegraph()
	_string_spares_body = _string_spares_body or not attack.body_contact
	_hitbox.damage = attack.damage_for(_ai.recall_owned)
	_hitbox.knockback_strength = attack.knockback_strength
	_hitbox.knockback_lift = attack.knockback_lift
	_mover.begin(attack, _motion_context(attack))
	_spawner.begin(attack)
	_strike_start_x = global_position.x
	# A repeated link keeps its clip's name; without the replay its Hitbox keys would not run again.
	_animation_driver.request_replay()
	if attack.recall == null or _player == null:
		return
	if SaveSystem.has_skill(attack.recall.skill):
		return
	# Nothing stray lands inside the recall's window.
	_spawner.clear()
	if attack.recall_lead > 0.0:
		_recall_due = attack
		return
	_player.begin_recall(attack.recall, attack.duration, self, _hitbox)

func _on_attack_finished(_attack: GuardianAttack) -> void:
	_recall_due = null
	_hitbox.spared = null
	_stop_telegraph()
	_mover.end()

## The string's recovery is over: its targets may be hurt again, and a body its move carried onto Ivo spares him
## until he is out of it.
func _end_string_after_recovery() -> void:
	if not _string_gate.is_active() or _ai.is_attacking():
		return
	_string_gate.end_string()
	if _string_spares_body:
		_string_spares_body = false
		_body_contact.begin()

func _player_inside_body() -> bool:
	return is_instance_valid(_player) and body_rect().intersects(_player.body_rect())

## A recall move's recall opens `recall_lead` s before its lunge reaches Ivo, timed here instead of by the recall's
## distance cue (bugs/a-prompt-roll-on-a-frost-charge-thrown-from-170-220-px-runs-out-of-grace-before-the-fists-arrive).
func _open_due_recall() -> void:
	if _recall_due == null or _ai.current_attack != _recall_due or not is_instance_valid(_player):
		return
	var elapsed := _ai.swing_elapsed()
	var distance := absf(_player.global_position.x - global_position.x)
	if _recall_due.seconds_to_blow(elapsed, distance) > _recall_due.recall_lead:
		return
	var attack := _recall_due
	_recall_due = null
	if not SaveSystem.has_skill(attack.recall.skill):
		_player.open_recall(attack.recall, self, _hitbox)

## A move whose box is its only hit, stopped by the wall ahead, has no run left: its box spares Ivo for the rest of the
## strike, so a pinned Ivo who jumped it is not hit landing into it (playtests/2026-11-19-grd16-sun-fight).
func _spare_against_wall() -> void:
	if (_ai.blocked_ahead and absf(global_position.x - _strike_start_x) >= WALL_RUN
			and not _ai.current_attack.body_contact and is_instance_valid(_player)):
		_hitbox.spared = _player.hurtbox

## What a move's motion plans against; null for a move with none.
func _motion_context(attack: GuardianAttack) -> MotionContext:
	if attack.motion == null:
		return null
	var ctx := MotionContext.new()
	ctx.feet = global_position
	ctx.facing = facing
	ctx.target = _player.global_position if is_instance_valid(_player) else global_position
	ctx.arena = arena_bounds()
	ctx.margin = lucidity_leap_margin
	ctx.gravity = base_gravity()
	ctx.body_height = body_height()
	ctx.duration = attack.duration
	return ctx

func _stop_telegraph() -> void:
	if _telegraph_tween != null:
		_telegraph_tween.kill()
		_telegraph_tween = null
		_sprite.modulate = Color.WHITE

## The body remembered. If the hits were already in, that is the blow that
## opens the window: the guardian is shaken by what it forced.
func _on_skill_recalled(_skill: Enums.PlayerSkill) -> void:
	_ai.recall_owned = not _recall_still_needed()
	# An answered recall is never punished by the move that asked for it, however early it came
	# (bugs/a-prompt-answer-to-the-leaf-gust-recall-slides-ivo-back-into-its-floor-blow).
	var attack := _ai.current_attack
	if attack != null and attack.recall != null and _ai.is_swinging():
		_hitbox.spared = _player.hurtbox
	if _fight.skill_recalled():
		_open_lucidity()

## Ivo died: the fight stops where it stands while the world fades and is rebuilt
## (bugs/a-guardian-stopped-by-ivos-death-outside-the-pressure-fights-again-in-the-death-fade).
func _on_player_died() -> void:
	_player_dead = true
	# Any motion cut here stops where it is, rather than sliding on in the idle pose.
	velocity.x = 0.0
	_ai.cancel_attack()
	_ai.active = false
	_stop_telegraph()
	_spawner.clear()
	_lucidity_wait = 0.0
	_call.stop()

func _open_lucidity() -> void:
	_ai.cancel_attack()
	_ai.active = false
	_stop_telegraph()
	_flash(lucid_flash_color)
	_tremble_time = 0.0
	_answered_notes = 0
	_breath = 0.0
	_lucidity_wait = lucidity_delay

## It breaks off and throws itself clear: up over the top of the frame and
## down at the far side, away from Ivo. The call waits for the landing.
func _begin_lucidity_leap() -> void:
	var gravity := base_gravity()
	var speed := sqrt(2.0 * gravity * lucidity_leap_height)
	var flight := 2.0 * speed / gravity
	var target := _leap_target_x()
	velocity = Vector2((target - global_position.x) / flight, -speed)
	face_towards(_player.global_position.x - global_position.x)
	_leap_floor_y = global_position.y
	_leaping = true
	_leap_left = lucidity_leap_timeout
	# The frame pairs at take-off so the landing is in view; only the landing stages the call
	# (bugs/the-lucidity-leap-lands-outside-the-frame-so-its-land-clip-is-not-seen).
	_frame()
	leapt.emit(global_position)

## The far side, worked out rather than assumed. Each direction is measured
## for the room the ARENA actually gives it, and the one that ends up further
## from Ivo wins - so a guardian backed into a corner goes over his head
## instead of shuffling a few pixels deeper into it. A tie (the usual case,
## with space both ways) goes to the side it already stands on: no crossing
## for its own sake.
func _leap_target_x() -> float:
	var here := _player.global_position.x
	var walls := _arena_bounds()
	var low := here - lucidity_leap_distance
	var high := here + lucidity_leap_distance
	if walls.size.x > 0.0:
		var edge_low := walls.position.x + lucidity_leap_margin
		var edge_high := walls.end.x - lucidity_leap_margin
		if edge_low > edge_high:
			return walls.get_center().x
		low = clampf(low, edge_low, edge_high)
		high = clampf(high, edge_low, edge_high)
	if is_equal_approx(here - low, high - here):
		return low if global_position.x <= here else high
	return low if here - low > high - here else high

## Where the ground runs out. A guardian with no arena assigned answers an
## empty rect and the leap simply takes its full distance - wrong, but it
## still lands, so it says so rather than stalling the fight.
func _arena_bounds() -> Rect2:
	if _arena == null:
		push_warning("%s has no arena: its lucidity leap cannot see the walls." % name)
	return arena_bounds()

## Above the floor it left, the body passes through the world, and takes it back on the way down so it lands on real
## ground. Shared by the lucidity leap and a move's leap; the two never run at once.
func _pass_through_above(floor_y: float) -> void:
	collision_mask = 0 if global_position.y < floor_y - 8.0 else _solid_mask

## Presentation, not gameplay: a landing this heavy is felt through whatever
## camera is showing it. The engine's own accessor for the active camera, and
## nothing is read back out of it - where the guardian LANDS comes from the
## arena above.
func _shake_camera(strength: float) -> void:
	var camera := get_viewport().get_camera_2d() as GameCamera
	if camera != null:
		camera.shake(strength)

func _finish_lucidity_leap() -> void:
	_leaping = false
	collision_mask = _solid_mask
	var impact := velocity.y
	velocity = Vector2.ZERO
	landed.emit(global_position, impact)
	_shake_camera(lucidity_leap_shake)
	if _player_dead:
		return
	face_towards(_player.global_position.x - global_position.x)
	_stage()
	# Emitted before the call plays, so a zero lead-in still closes the bark at the first note.
	if _finale != null:
		lucid_landed.emit(_fight.cycles(), _fight.relapse_failed())
		_finale.open_call(_player)
		return
	_player.open_call(stats.song, stats.revealed_notes, _fight.cycles(), stats.cycles_to_restore)
	lucid_landed.emit(_fight.cycles(), _fight.relapse_failed())
	_call.play(stats.song.notes, stats.call_lead_in)

## A note of the call: the colour comes with it.
func _on_call_note_sounded(index: int) -> void:
	_player.sound_call_note(index)
	_breathe()
	call_note_sung.emit(index)

func _breathe() -> void:
	if _breath_tween != null:
		_breath_tween.kill()
	_breath = 1.0
	_breath_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_breath_tween.tween_property(self, "_breath", 0.0, _call.note_interval)
	if _bob_tween != null:
		_bob_tween.kill()
	_sprite.position = _sprite_rest + Vector2(0.0, -note_bob)
	_bob_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_bob_tween.tween_property(_sprite, "position", _sprite_rest, _call.note_interval * 0.6)

func _on_call_finished() -> void:
	if _finale == null or _finale.counts_window():
		_fight.open_window(_call.duration())
	_player.open_call_window()

## `count` notes of the answer are right so far: the cure shows note by note.
func _on_call_progress(count: int) -> void:
	if _fight.phase() == GuardianFight.Phase.LUCIDITY:
		_answered_notes = count

func _on_call_answered(song: Song) -> void:
	if _fight.phase() != GuardianFight.Phase.LUCIDITY:
		return
	if _finale != null and _finale.answered(song, _player):
		return
	if song != stats.song and _finale == null:
		return
	_fight.answer_succeeded()
	if _fight.phase() == GuardianFight.Phase.RESTORED:
		_restore()
	else:
		_close_call(true)

## Any failure the instrument reports while the guardian is lucid - a wrong
## note, a hit, a step - is the answer failing. Also fires as a consequence of
## _close_call(false) itself, harmlessly: the fight has already moved on.
func _on_player_sequence_failed() -> void:
	if _fight.phase() != GuardianFight.Phase.LUCIDITY:
		return
	_fight.answer_failed()
	_close_call(false)

func _close_call(success: bool) -> void:
	_call.stop()
	_player.update_call_window(0.0)
	_player.close_call(success)
	_push_tuning()
	_ai.active = _fight.phase() == GuardianFight.Phase.PRESSURE and not _player_dead
	call_ended.emit()

func _abandon_call() -> void:
	if _fight == null or _player == null:
		return
	_lucidity_wait = 0.0
	if _leaping:
		_leaping = false
		collision_mask = _solid_mask
	if _fight.phase() == GuardianFight.Phase.LUCIDITY:
		_fight.answer_failed()
		_close_call(false)
	_unstage()

func _on_opening_ended() -> void:
	_ai.active = _fight.phase() == GuardianFight.Phase.PRESSURE and not _player_dead

## The fight's stage tuning, into the AI: the cooldown (aggression x stage), the link chances and the string length.
func _push_tuning() -> void:
	if _finale != null:
		_fight.set_extra_stages(_finale.extra_stages())
	_ai.cooldown_scale = _fight.cooldown_scale()
	_ai.stage = _fight.stage()
	_ai.chain_scale = _fight.chain_scale()
	_ai.max_links = _fight.max_links()
	_ai.walk_scale = _fight.walk_scale()
	_ai.recovery_scale = _fight.recovery_scale()

## The fight's own transitions, as opposed to the ones this node drives: the
## relapse begins at an answer and ends on its own clock.
func _on_phase_changed(from: GuardianFight.Phase, to: GuardianFight.Phase) -> void:
	phase_changed.emit(from, to)
	# Spawned attacks belong to the pressure.
	if to != GuardianFight.Phase.PRESSURE:
		_spawner.clear()
	match to:
		GuardianFight.Phase.RELAPSE:
			_begin_relapse()
		GuardianFight.Phase.PRESSURE:
			if from == GuardianFight.Phase.RELAPSE:
				_hits_since_move = 0
				_push_tuning()
				_ai.active = not _player_dead
				_unstage()

## The madness returns: the guardian staggers, groans in its own voice, and
## its colour goes - snapped away with the hit's tint after a failure, drained
## slowly after a good answer that was not the last.
func _begin_relapse() -> void:
	_tremble_time = 0.0
	_relapse_from = _shield.amount
	if _fight.relapse_failed():
		_flash(hit_flash_color)
	# Deferred: the call is stopped right after this by _close_call, and the
	# groan must come after that stop, not under it.
	_call.groan.call_deferred()

func _on_call_mixed(_note: Enums.Note) -> void:
	if _fight.phase() == GuardianFight.Phase.LUCIDITY:
		_finale.mixed(_player)

## Restoration updates the save, region memory, weather, song lesson and camera together.
func _restore() -> void:
	_call.stop()
	_ai.active = false
	call_ended.emit()
	if _finale != null:
		# The mentor teaches nothing: the world is restored and saved at once (GRD-06).
		_player.close_call(true)
		_unstage()
		_finale.restored()
		restored.emit(self)
		return
	SaveSystem.restore_guardian(stats.id)
	# The guardian's colour: born at the first note, slow and wide, then the
	# usual pulse answers the finished lesson from where it stands.
	_player.note_cue_reached.connect(_on_lesson_cue)
	_player.song_played.connect(_on_lesson_song_played, CONNECT_ONE_SHOT)
	_player.performance_started.connect(_on_lesson_started, CONNECT_ONE_SHOT)
	_player.performance_finished.connect(_on_lesson_finished, CONNECT_ONE_SHOT)
	_teaching = true
	if not _player.learn_song(stats.song):
		# The answer left Ivo still and the instrument out, so this should not
		# happen; if it does, the song is still learned on the next bench-less
		# visit because the save already remembers the guardian.
		push_warning("%s was restored but the lesson could not start." % name)
		_player.note_cue_reached.disconnect(_on_lesson_cue)
		_player.performance_started.disconnect(_on_lesson_started)
		_player.performance_finished.disconnect(_on_lesson_finished)
		_teaching = false
		_player.close_call(true)
		_unstage()
	restored.emit(self)

## The lesson's freeze pauses the tree: the tree plays `perform` through it (systems/songs-and-the-memorina, pause-mode map).
func _on_lesson_started() -> void:
	_animation_tree.process_mode = Node.PROCESS_MODE_ALWAYS

func _on_lesson_finished() -> void:
	_animation_tree.process_mode = Node.PROCESS_MODE_INHERIT
	_teaching = false
	_bowing = true

# Read before this frame's resolve: `perform` is still current on the frame the lesson ends.
func _still_bowing() -> bool:
	return _animation_driver.current == GuardianAnimationResolver.PERFORM 			or _animation_driver.holding(GuardianAnimationResolver.PERFORM_END)

func _on_lesson_cue(index: int) -> void:
	if index != 0:
		return
	_player.note_cue_reached.disconnect(_on_lesson_cue)
	_pulse_emitter.spawn_pulse(stats.song, global_position, lesson_pulse)

func _on_lesson_song_played(song: Song, _position: Vector2) -> void:
	_pulse_emitter.spawn_pulse(song, global_position)

func _frame() -> void:
	if _framed or _player_dead:
		return
	_framed = true
	_player.frame_call(self)

func _stage() -> void:
	if _staged or _player_dead:
		return
	_staged = true
	_framed = true
	_player.stage_call(self, body_height())

# A walk across a seam leaves the arena running as a neighbour room, so leaving it must end the call
# (bugs/walking-out-of-a-guardian-room-no-longer-abandons-its-call).
func _player_in_arena() -> bool:
	return is_instance_valid(_player) and (_arena == null or _arena.bounds().has_point(_player.global_position))

func _unstage() -> void:
	if not _staged and not _framed:
		return
	_staged = false
	_framed = false
	if is_instance_valid(_player):
		_player.unstage_call()

## Sight reaches every point of its arena from anywhere in it, so no move can carry Ivo out of it
## (bugs/the-leaf-gust-blows-ivo-out-of-the-guardians-sight-and-the-fight-stops).
func _fit_sight_to_arena() -> void:
	var node := _sight.get_node(^"CollisionShape2D") as CollisionShape2D
	var circle := node.shape as CircleShape2D
	if circle == null:
		return
	var radius := sight_radius_for(circle.radius, arena_bounds())
	if radius > circle.radius:
		circle = circle.duplicate() as CircleShape2D
		circle.radius = radius
		node.shape = circle

## True while any of this guardian's moves still has a skill to teach.
func _recall_still_needed() -> bool:
	for attack: GuardianAttack in stats.attacks:
		if attack.recall != null and not SaveSystem.has_skill(attack.recall.skill):
			return true
	return false

#############################################
##  T H E   C O L O U R                    ##
#############################################
## Gameplay-driven, never keyed in a clip (the tree would fight it every frame).

func _update_shield(delta: float) -> void:
	_tremble_time += delta
	var rest := _rest_amount()
	match _fight.phase():
		GuardianFight.Phase.RESTORED:
			_shield.amount = 1.0
			_shield.radius = _shield_rest_radius
		GuardianFight.Phase.LUCIDITY:
			_shield.amount = _lucid_amount(rest)
			_shield.radius = _shield_rest_radius * lerpf(1.0, note_swell, _breath)
		GuardianFight.Phase.RELAPSE:
			_shield.amount = _relapse_amount(rest)
			_shield.radius = _shield_rest_radius
		_:
			_shield.amount = lerpf(rest, rest + PRESSURE_CLIMB * (1.0 - rest), _fight.pressure_progress())
			_shield.radius = _shield_rest_radius

## What the guardian keeps between windows: the cure so far.
func _rest_amount() -> float:
	return lerpf(stats.corrupted_shield_amount, 1.0, _fight.lucidity())

## Breathing to full with each note of the call; once the window is open, a
## slow tremble above a floor that climbs with every note answered.
func _lucid_amount(rest: float) -> float:
	if not _fight.is_window_open():
		return lerpf(rest, 1.0, _breath)
	var notes := maxi(stats.song.notes.size(), 1)
	var floor_amount := lerpf(rest, 1.0, float(_answered_notes) / notes)
	var tremble := 0.5 + 0.5 * sin(TAU * stats.tremble_hz * _tremble_time)
	return lerpf(floor_amount, 1.0, tremble)

## After a failure the colour is already gone, shaking hard for a moment;
## after a good answer it holds bright for a beat and drains to the new rest.
func _relapse_amount(rest: float) -> float:
	var t := _fight.relapse_progress() * _fight.relapse_duration()
	if _fight.relapse_failed():
		if t >= FAIL_BURST_TIME:
			return rest
		var burst := 0.5 + 0.5 * sin(TAU * FAIL_BURST_HZ * t)
		return lerpf(rest, _relapse_from, burst)
	var drain := clampf((t - RELAPSE_HOLD) / maxf(_fight.relapse_duration() - RELAPSE_HOLD, 0.001), 0.0, 1.0)
	return lerpf(maxf(_relapse_from, rest), rest, drain)

## Every move the graph can throw: the strike is its duration, a wind-up fits the telegraph, a recovery the recovery.
func _assert_clip_durations() -> void:
	for attack: GuardianAttack in GuardianMoveGraph.moves(stats):
		_assert_clip_length(GuardianAnimationResolver.attack_clip_for(attack.clip_index), attack.duration)
		var windup := GuardianAnimationResolver.windup_clip_for(attack.windup_index)
		if windup != &"":
			assert(_animation_driver.clip_length(windup) <= attack.telegraph + 0.001,
				"%s: '%s' outlasts its %.4fs telegraph" % [name, windup, attack.telegraph])
		var recover := GuardianAnimationResolver.recover_clip_for(attack.recovery_index)
		if recover != &"":
			assert(_animation_driver.clip_length(recover) <= attack.recovery + 0.001,
				"%s: '%s' outlasts its %.4fs recovery" % [name, recover, attack.recovery])
	var enter := _animation_driver.clip_length(GuardianAnimationResolver.LUCID_ENTER)
	var before_crouch := lucidity_delay - _animation_driver.clip_length(GuardianAnimationResolver.LEAP_CROUCH)
	assert(enter <= before_crouch + 0.001,
		"%s: 'lucid_enter' is %.4fs, the delay before the crouch %.4fs" % [name, enter, before_crouch])
	var relapse := _animation_driver.clip_length(GuardianAnimationResolver.RELAPSE)
	var shortest := stats.relapse_time * GuardianFight.FAILED_RELAPSE_SCALE
	assert(relapse <= shortest + 0.001,
		"%s: 'relapse' is %.4fs, the shortest relapse %.4fs" % [name, relapse, shortest])
