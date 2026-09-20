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
## its Health is inert and it takes no knockback.

signal restored(guardian: Guardian)

@export var stats: GuardianStats
@export var terminal_velocity: float = 500.0

var _fight: GuardianFight
var _player: Player
var _tremble_time: float = 0.0

@onready var _ai                : GuardianAI = $AI
@onready var _locomotion        : LocomotionComponent = $Locomotion
@onready var _call              : GuardianCall = $Call
@onready var _arena_trigger     : PlayerProximityTrigger = $ArenaTrigger
@onready var _shield            : GreyhushShield = $GreyhushShield
## A concrete view of Character's generic resolver, for the duration assert.
@onready var _guardian_resolver : GuardianAnimationResolver = $AnimationResolver


func _ready() -> void:
	super()
	assert(stats != null and stats.song != null, "%s has no GuardianStats with a song." % name)
	_fight = GuardianFight.new(stats)
	_ai.attacks = stats.attacks
	_ai.attack_started.connect(_on_attack_started)
	_call.note_sounded.connect(_on_call_note_sounded)
	_call.finished.connect(_on_call_finished)
	_arena_trigger.player_entered.connect(_on_player_entered)
	if SaveSystem.is_guardian_restored(stats.id):
		_fight.restore_silently()
	_assert_clip_durations()
	_update_shield(0.0)

func _process_motion(delta: float) -> void:
	if _fight.phase() == GuardianFight.Phase.PRESSURE:
		_ai.tick(delta)
		face_towards(_ai.direction)
		_locomotion.ground_update(delta, _ai.direction)
		var attack := _ai.current_attack
		if attack != null and attack.lunge_speed > 0.0:
			velocity.x = facing * attack.lunge_speed
	else:
		_locomotion.ground_update(delta, 0.0)
	if not is_on_floor():
		velocity.y = minf(velocity.y + base_gravity() * delta, terminal_velocity)

func _after_move(delta: float) -> void:
	# The window ran out: the same failure as a wrong note, closed the same way.
	if _fight.tick(delta):
		_close_call(false)
	_update_shield(delta)

## A room being left deactivates (or evicts) its contents, and a guardian
## stopped mid-call would otherwise leave its phrase on Ivo's instrument for
## good - known songs noise, the answer going to no one. Walking out of a
## lucidity window is the answer failing.
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
	_player.sequence_failed.connect(_on_player_sequence_failed)
	_fight.begin()
	_ai.active = true

## A hit destabilises rather than wounds: no damage, no knockback, just the
## flinch - and, once enough have landed, a lucidity window.
func _on_hit_received(_damage: int, _knockback: Vector2, _source: Node2D) -> void:
	if _fight.phase() != GuardianFight.Phase.PRESSURE:
		return
	_just_hit = true
	if _fight.register_hit():
		_open_lucidity()

## The unavoidable move: while the player lacks the skill it teaches, starting
## it opens the recall instead of simply landing.
func _on_attack_started(attack: GuardianAttack) -> void:
	if attack.recall == null or _player == null:
		return
	if SaveSystem.has_skill(attack.recall.skill):
		return
	_player.begin_recall(attack.recall)

func _open_lucidity() -> void:
	_ai.cancel_attack()
	_ai.active = false
	_tremble_time = 0.0
	_player.open_call(stats.song, stats.revealed_notes)
	_call.play(stats.song.notes)

func _on_call_note_sounded(index: int) -> void:
	_player.sound_call_note(index)

func _on_call_finished() -> void:
	_fight.open_window(_call.duration())

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
	if _fight == null or _player == null or _fight.phase() != GuardianFight.Phase.LUCIDITY:
		return
	_fight.answer_failed()
	_close_call(false)

## The sync: the guardian remembers itself, the region remembers its season,
## and the player learns the song through the same lesson a bench would give.
func _restore() -> void:
	_call.stop()
	_ai.active = false
	SaveSystem.restore_guardian(stats.id)
	var field := MemoryField.find_in(self)
	if field != null:
		field.baseline = 1.0
	if not _player.learn_song(stats.song):
		# The answer left Ivo still and the instrument out, so this should not
		# happen; if it does, the song is still learned on the next bench-less
		# visit because the save already remembers the guardian.
		push_warning("%s was restored but the lesson could not start." % name)
		_player.close_call(true)
	restored.emit(self)

## The colour the guardian holds is gameplay-driven, never keyed in a clip:
## corrupted while under pressure, climbing with each good answer, trembling
## to full while lucid, full for good once restored.
func _update_shield(delta: float) -> void:
	match _fight.phase():
		GuardianFight.Phase.RESTORED:
			_shield.amount = 1.0
		GuardianFight.Phase.LUCIDITY:
			_tremble_time += delta
			var on := fmod(_tremble_time * stats.tremble_hz, 1.0) < 0.5
			_shield.amount = 1.0 if on else stats.corrupted_shield_amount
		_:
			_shield.amount = lerpf(stats.corrupted_shield_amount, 1.0, _fight.lucidity())

func _assert_clip_durations() -> void:
	for attack: GuardianAttack in stats.attacks:
		_assert_clip_length(_guardian_resolver.attack_clip_for(attack.clip_index), attack.duration)
