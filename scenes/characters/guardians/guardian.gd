class_name Guardian
extends Character
## The substrate every guardian is built on (docs/design/02_mecanicas.md
## sections 3 and 4). A concrete guardian is a scene and a GuardianStats;
## this script needs no subclass unless a guardian does something no
## resource can describe.
##
## Composition root of the encounter: GuardianFight holds the phase logic,
## GuardianAI the pressure-phase moves, GuardianCall the phrase, and Ivo's
## own instrument the answer. This node is the only one that talks to the
## player, the save and the memory field - so like Player, and unlike any
## component, it may read SaveSystem.
##
## A guardian is never killed. Hits do not hurt it, they destabilise it;
## its Health is inert and it takes no knockback. Its bulk hurts to touch
## while it fights (ContactHitbox, phase-owned, never keyed in a clip).
##
## The colour it holds is the fight made visible: corrupted under pressure,
## a little more with every blow, breathing to full with every note it
## sings, climbing with every note answered, and draining away again as it
## relapses - until it is restored and keeps it all.

signal restored(guardian: Guardian)

## The failure's tremble: hard and brief, then the colour is gone.
const FAIL_BURST_TIME := 0.3
const FAIL_BURST_HZ := 12.0
## How much of the way to full the pressure's hits bring the colour.
const PRESSURE_CLIMB := 0.35
## The beat a good answer holds the guardian bright before it drains.
const RELAPSE_HOLD := 0.3

@export var stats: GuardianStats
@export var terminal_velocity: float = 500.0
## The hit flash: the sprite is tinted to this and eased back, so a hit reads
## even mid-swing, when the flinch clip yields to the attack. Sprite2D:modulate
## has no RESET track, so this write is the script's to make.
@export var hit_flash_color: Color = Color(1.0, 0.55, 0.45)
@export var hit_flash_time: float = 0.12
## The telegraph: while a move winds up the sprite pulses to this tint, so the
## swing that follows was announced. Read it, and the fight is fair.
@export var telegraph_color: Color = Color(1.0, 0.85, 0.35)
@export var telegraph_pulse_time: float = 0.12
## Lucidity opening: a flash brighter than white.
@export var lucid_flash_color: Color = Color(1.6, 1.6, 1.6)
## Each note of the call swells the shield's radius by this factor and lifts
## the sprite by `note_bob` pixels, both easing back before the next note.
@export var note_swell: float = 1.5
@export var note_bob: float = 4.0
## Seconds the well of forgetting takes to fill in and the region's memory to
## climb to 1.0 once the guardian is restored - the first act of the lesson.
@export var corruption_lift_time: float = 6.0
## The shape of the guardian's pulse during the lesson: slow and wide, so the
## colour spreads from it for as long as the track plays.
@export var lesson_pulse: PulseStats

var _fight: GuardianFight
var _player: Player
var _tremble_time: float = 0.0
var _flash_tween: Tween
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
## The camera and the lights are on this guardian.
var _staged: bool = false
var _shield_rest_radius: float = 0.0
var _sprite_rest: Vector2 = Vector2.ZERO

@onready var _ai                : GuardianAI = $AI
@onready var _locomotion        : LocomotionComponent = $Locomotion
@onready var _call              : GuardianCall = $Call
@onready var _arena_trigger     : PlayerProximityTrigger = $ArenaTrigger
@onready var _shield            : GreyhushShield = $GreyhushShield
@onready var _hitbox            : Hitbox = $Hitbox
@onready var _contact           : Hitbox = $ContactHitbox
@onready var _pulse_emitter     : PulseEmitter = $PulseEmitter
## The well of forgetting around the guardian: an authored negative
## MemorySource, top_level so it stays where the fight is while the guardian
## paces. Gone once the guardian is restored.
@onready var _corruption        : MemorySource = $Corruption
## A concrete view of Character's generic resolver, for the duration assert.
@onready var _guardian_resolver : GuardianAnimationResolver = $AnimationResolver


func _ready() -> void:
	super()
	assert(stats != null and stats.song != null, "%s has no GuardianStats with a song." % name)
	_fight = GuardianFight.new(stats)
	_fight.phase_changed.connect(_on_phase_changed)
	_fight.set_recall_pending(_recall_still_needed())
	_ai.attacks = stats.attacks
	_ai.recall_after_attacks = stats.recall_after_attacks
	_ai.comfort_distance = stats.comfort_distance
	_ai.pace_time = stats.pace_time
	_ai.pace_speed = stats.pace_speed
	_ai.step_out_speed = stats.step_out_speed
	_ai.attack_telegraphed.connect(_on_attack_telegraphed)
	_ai.attack_started.connect(_on_attack_started)
	_ai.attack_finished.connect(_on_attack_finished)
	_call.note_sounded.connect(_on_call_note_sounded)
	_call.finished.connect(_on_call_finished)
	_arena_trigger.player_entered.connect(_on_player_entered)
	_shield_rest_radius = _shield.radius
	_sprite_rest = _sprite.position
	_corruption.global_position = global_position
	if SaveSystem.is_guardian_restored(stats.id):
		_fight.restore_silently()
		_corruption.hide()
	_assert_clip_durations()
	_update_shield(0.0)

func _process_motion(delta: float) -> void:
	if _fight.phase() == GuardianFight.Phase.PRESSURE:
		_ai.tick(delta)
		# Where it LOOKS, not where it walks: a guardian backing out from under
		# a player keeps watching him, and an x sitting on its own never makes
		# it turn on the spot.
		face_towards(_ai.facing_intent())
		_locomotion.ground_update(delta, _ai.direction)
		var attack := _ai.current_attack
		if attack != null and _ai.is_swinging() and attack.lunge_speed > 0.0:
			velocity.x = facing * attack.lunge_speed
	else:
		_locomotion.ground_update(delta, 0.0)
	if not is_on_floor():
		velocity.y = minf(velocity.y + base_gravity() * delta, terminal_velocity)

func _after_move(delta: float) -> void:
	# The window ran out: the same failure as a wrong note, closed the same way.
	if _fight.tick(delta):
		_close_call(false)
	# Dangerous to touch only while it fights; a lucid or restored guardian can
	# be walked up to. Not RESET-owned, so this write is the script's.
	_contact.monitoring = _fight.phase() == GuardianFight.Phase.PRESSURE
	_update_shield(delta)

## A room being left deactivates (or evicts) its contents, and a guardian
## stopped mid-call would otherwise leave its phrase on Ivo's instrument for
## good - known songs noise, the answer going to no one - and the camera on
## a guardian that is no longer there. Walking out of a lucidity window is
## the answer failing.
func _notification(what: int) -> void:
	if what == NOTIFICATION_DISABLED or what == NOTIFICATION_EXIT_TREE:
		_abandon_call()

#############################################
##  S T A T E   Q U E R I E S              ##
#############################################
## Read by GuardianAnimationResolver; no animation logic here.

func phase() -> GuardianFight.Phase:
	return _fight.phase()

func is_attacking() -> bool:
	return _ai.is_attacking()

## The wind-up before a swing: still, announced, not yet dangerous.
func is_telegraphing() -> bool:
	return _ai.is_telegraphing()

func is_swinging() -> bool:
	return _ai.is_swinging()

func current_attack() -> GuardianAttack:
	return _ai.current_attack

func wants_to_move() -> bool:
	return not is_zero_approx(_ai.direction)

#############################################
##  T H E   F I G H T                      ##
#############################################

func _on_player_entered() -> void:
	if _fight.phase() != GuardianFight.Phase.DORMANT:
		return
	_player = get_tree().get_first_node_in_group(Player.GROUP) as Player
	if _player == null:
		return
	_player.call_answered.connect(_on_call_answered)
	_player.call_progress.connect(_on_call_progress)
	_player.sequence_failed.connect(_on_player_sequence_failed)
	_player.skill_recalled.connect(_on_skill_recalled)
	_fight.begin()
	_ai.active = true

## A hit destabilises rather than wounds: no damage, no knockback, just the
## flinch - and, once enough have landed, a lucidity window. While a skill is
## still to be remembered the hits wait on the recall move, which is asked
## for at once; and a guardian hit too many times between moves answers with
## one.
func _on_hit_received(_damage: int, _knockback: Vector2, _source: Node2D) -> void:
	if _fight.phase() != GuardianFight.Phase.PRESSURE:
		return
	_just_hit = true
	_flash(hit_flash_color)
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
	if _flash_tween != null:
		_flash_tween.kill()
	_sprite.modulate = color
	_flash_tween = create_tween()
	_flash_tween.tween_property(_sprite, "modulate", Color.WHITE, hit_flash_time)

## A move winds up: the guardian squares up to Ivo (a charge thrown the way
## it happened to be facing goes into a wall) and the sprite pulses until the
## swing begins.
func _on_attack_telegraphed(_attack: GuardianAttack) -> void:
	_hits_since_move = 0
	if _player != null:
		face_towards(signf(_player.global_position.x - global_position.x))
	_stop_telegraph()
	_telegraph_tween = create_tween().set_loops()
	_telegraph_tween.tween_property(_sprite, "modulate", telegraph_color, telegraph_pulse_time)
	_telegraph_tween.tween_property(_sprite, "modulate", Color.WHITE, telegraph_pulse_time)

## The swing begins: the hitbox takes the move's numbers (Hitbox exports are
## not RESET-owned, so this write sticks), and the unavoidable move opens the
## recall while the player still lacks the skill it teaches.
func _on_attack_started(attack: GuardianAttack) -> void:
	_stop_telegraph()
	_hitbox.damage = attack.damage
	_hitbox.knockback_strength = attack.knockback_strength
	_hitbox.knockback_lift = attack.knockback_lift
	# A leap: the swing carries it over the player (lunge_speed does the
	# horizontal half). Gravity brings it down inside the same clip.
	if attack.leap_impulse > 0.0 and is_on_floor():
		velocity.y = -attack.leap_impulse
	if attack.recall == null or _player == null:
		return
	if SaveSystem.has_skill(attack.recall.skill):
		return
	_player.begin_recall(attack.recall, attack.duration, self)

func _on_attack_finished(_attack: GuardianAttack) -> void:
	_stop_telegraph()

func _stop_telegraph() -> void:
	if _telegraph_tween != null:
		_telegraph_tween.kill()
		_telegraph_tween = null
		_sprite.modulate = Color.WHITE

## The body remembered. If the hits were already in, that is the blow that
## opens the window: the guardian is shaken by what it forced.
func _on_skill_recalled(_skill: Enums.PlayerSkill) -> void:
	if _fight.skill_recalled():
		_open_lucidity()

func _open_lucidity() -> void:
	_ai.cancel_attack()
	_ai.active = false
	_stop_telegraph()
	_flash(lucid_flash_color)
	_tremble_time = 0.0
	_answered_notes = 0
	_breath = 0.0
	_stage()
	_player.open_call(stats.song, stats.revealed_notes, _fight.cycles(), stats.cycles_to_restore)
	_call.play(stats.song.notes, stats.call_lead_in)

## A note of the call: the colour comes with it.
func _on_call_note_sounded(index: int) -> void:
	_player.sound_call_note(index)
	_breathe()

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
	_fight.open_window(_call.duration())
	_player.open_call_window(_fight.window_left())

## `count` notes of the answer are right so far: the cure shows note by note.
func _on_call_progress(count: int) -> void:
	if _fight.phase() == GuardianFight.Phase.LUCIDITY:
		_answered_notes = count

func _on_call_answered(song: Song) -> void:
	if song != stats.song or _fight.phase() != GuardianFight.Phase.LUCIDITY:
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
	_player.close_call(success)
	_ai.cooldown_scale = _fight.cooldown_scale()
	_ai.active = _fight.phase() == GuardianFight.Phase.PRESSURE

func _abandon_call() -> void:
	if _fight == null or _player == null:
		return
	if _fight.phase() == GuardianFight.Phase.LUCIDITY:
		_fight.answer_failed()
		_close_call(false)
	_unstage()

## The fight's own transitions, as opposed to the ones this node drives: the
## relapse begins at an answer and ends on its own clock.
func _on_phase_changed(from: GuardianFight.Phase, to: GuardianFight.Phase) -> void:
	match to:
		GuardianFight.Phase.RELAPSE:
			_begin_relapse()
		GuardianFight.Phase.PRESSURE:
			if from == GuardianFight.Phase.RELAPSE:
				_hits_since_move = 0
				_ai.active = true
				_unstage()

## The madness returns: the guardian staggers, groans in its own voice, and
## its colour goes - snapped away with the hit's tint after a failure, drained
## slowly after a good answer that was not the last.
func _begin_relapse() -> void:
	_just_hit = true
	_tremble_time = 0.0
	_relapse_from = _shield.amount
	if _fight.relapse_failed():
		_flash(hit_flash_color)
	# Deferred: the call is stopped right after this by _close_call, and the
	# groan must come after that stop, not under it.
	_call.groan.call_deferred()

## The sync: the guardian remembers itself, the region remembers its season,
## and the player learns the song through the same lesson a bench would give.
## The lesson is a scene: time is frozen for the track, memory is not. The
## well of forgetting fills in and the region's memory climbs to 1.0 across
## `corruption_lift_time`, the guardian's own colour is born at the first
## note and spreads slowly (lesson_pulse), the weather wakes with the
## baseline, and the camera holds the pair until the track ends.
func _restore() -> void:
	_call.stop()
	_ai.active = false
	SaveSystem.restore_guardian(stats.id)
	_lift_region()
	# The guardian's colour: born at the first note, slow and wide, then the
	# usual pulse answers the finished lesson from where it stands.
	_player.note_cue_reached.connect(_on_lesson_cue)
	_player.song_played.connect(_on_lesson_song_played, CONNECT_ONE_SHOT)
	_player.performance_finished.connect(_unstage, CONNECT_ONE_SHOT)
	if not _player.learn_song(stats.song):
		# The answer left Ivo still and the instrument out, so this should not
		# happen; if it does, the song is still learned on the next bench-less
		# visit because the save already remembers the guardian.
		push_warning("%s was restored but the lesson could not start." % name)
		_player.note_cue_reached.disconnect(_on_lesson_cue)
		_player.close_call(true)
		_unstage()
	restored.emit(self)

func _on_lesson_cue(index: int) -> void:
	if index != 0:
		return
	_player.note_cue_reached.disconnect(_on_lesson_cue)
	_pulse_emitter.spawn_pulse(stats.song, global_position, lesson_pulse)

func _on_lesson_song_played(song: Song, _position: Vector2) -> void:
	_pulse_emitter.spawn_pulse(song, global_position)

## The place remembers with the guardian: the well fills back in and the
## region's memory climbs to 1.0 (Region.current_baseline() answers 1.0 on
## every later visit), both across the lesson.
func _lift_region() -> void:
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel(true)
	tween.tween_property(_corruption, "strength", 0.0, corruption_lift_time)
	var field := MemoryField.find_in(self)
	if field != null:
		tween.tween_property(field, "baseline", 1.0, corruption_lift_time)
	tween.chain().tween_callback(_corruption.hide)

func _stage() -> void:
	if _staged:
		return
	_staged = true
	_player.stage_call(self)

func _unstage() -> void:
	if not _staged:
		return
	_staged = false
	if is_instance_valid(_player):
		_player.unstage_call()

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

func _assert_clip_durations() -> void:
	for attack: GuardianAttack in stats.attacks:
		_assert_clip_length(_guardian_resolver.attack_clip_for(attack.clip_index), attack.duration)
