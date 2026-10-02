class_name Player
extends Character

## Coordinates Ivo's movement, combat, songs, and recall behavior.

signal jumped(position: Vector2)
signal double_jumped(position: Vector2)
signal hard_landed(position: Vector2, impact_speed: float)
## The sheet uses `facing` to choose the side with open space.
signal memorina_drawn(known_songs: Array[Song], facing: int)
signal memorina_sheathed
## A note sounded with its input glyph set.
signal note_played(note: Enums.Note, glyph_set: Enums.GlyphSet)
## A rejected note with its input glyph set; it never sounded.
signal note_rejected(note: Enums.Note, glyph_set: Enums.GlyphSet)
signal sequence_failed
## The mistake finished sounding and the sequence can reset.
signal sequence_reset
## The world holds still during the performance, until `performance_finished`.
signal performance_started
signal performance_finished
## Performance playback reached the cue for note `index`.
signal note_cue_reached(index: int)
## A song was learned and its full track is about to play.
signal lesson_started(song: Song, glyph_set: Enums.GlyphSet)
signal song_played(song: Song, position: Vector2)
## The camera and lights stage `caller` and Ivo until `call_unstaged`.
signal call_staged(caller: Node2D)
signal call_unstaged
## Opens a guardian call with its song, reveal count, cure progress, glyphs, side (-1 or 1), and height.
signal call_opened(song: Song, revealed: int, glyph_set: Enums.GlyphSet, cure_done: int, cure_total: int, side: int, caller_height: float)
## The guardian's call sounded note `index`.
signal call_note_sounded(index: int)
## The call was heard and the answer window opened.
signal call_window_opened()
## Remaining answer-window fraction, 0..1; the fight owns the clock.
signal call_window_progress(fraction: float)
## The answer has `count` correct notes so far.
signal call_progress(count: int)
signal call_closed
## The full phrase was answered in time.
signal call_answered(song: Song)
## Recall opened for `action`; the world slows.
signal recall_started(action: StringName, seconds: float, steps: int)
## A recall step landed and more steps remain.
signal recall_step_taken(remaining: int, seconds: float)
signal recall_ended
signal skill_recalled(skill: Enums.PlayerSkill)
signal skill_recall_missed(skill: Enums.PlayerSkill)
## The sword hit a target.
signal hit_landed
## Ivo was hit.
signal hurt
## Water took Ivo; the composition root fades out and calls `respawn()`.
signal fell_into_hazard
## Health changed; emitted once at startup and on each change.
signal health_changed(current: int, max_hp: int)
## The death clip finished; the composition root waits before fading out.
signal death_shown
## Ivo sat down voluntarily; not emitted when `sit()` places him on a bench.
signal sat_down(seat: Seat)

const GROUP := "player"

## Attack tuning is chosen once per sequence and held across its clips.
const CTX_IDLE := &"idle"
const CTX_RUN := &"run"
const CTX_JUMP := &"jump"
const CTX_FALL := &"fall"
const CTX_POGO := &"pogo"
const ATTACK_CONTEXTS: Array[StringName] = [CTX_IDLE, CTX_RUN, CTX_JUMP, CTX_FALL, CTX_POGO]
const AIR_ATTACK_CONTEXTS: Array[StringName] = [CTX_JUMP, CTX_FALL, CTX_POGO]

## Horizontal speed below this threshold counts as standing still.
const STILL_SPEED_EPSILON := 1.0
## Seconds after recall when a directionless dodge moves away from its source.
const RECALL_ESCAPE_TIME := 0.6

enum MotionState { KNOCKBACK, ROLL, GROUND, AIR, CLIMB, SIT }


@onready var _input           : PlayerInput = $PlayerInput
@onready var _locomotion      : LocomotionComponent = $Locomotion
@onready var _jump            : JumpComponent = $Jump
@onready var _landing         : LandingComponent = $Landing
@onready var _double_jump     : DoubleJumpComponent = $DoubleJump
@onready var _wall_mobility   : WallMobilityComponent = $WallMobility
@onready var _roll            : RollComponent = $Roll
@onready var _climb           : ClimbComponent = $Climb
@onready var _sit             : SitComponent = $Sit
@onready var _attack          : AttackComponent = $Attack
@onready var _pogo            : PogoComponent = $Pogo
@onready var _memorina        : MemorinaComponent = $Memorina
@onready var _voice           : MemorinaVoice = $MemorinaVoice
@onready var _performance     : SongPerformance = $SongPerformance
@onready var _recall          : AbilityRecallComponent = $AbilityRecall
## Shield amount rises to full during recall.
@onready var _shield          : GreyhushShield = $GreyhushShield
@onready var _hitbox          : Hitbox = $Hitbox
@onready var _safe_ground     : SafeGroundTracker = $SafeGroundTracker
@onready var _airflow_body    : AirflowBody = $AirflowBody
## Player resolver used by the clip-duration assertion.
@onready var _player_resolver : PlayerAnimationResolver = $AnimationResolver

## Attack tuning selected by the sequence's movement context.
@export var attack_stats_idle : AttackStats
@export var attack_stats_run  : AttackStats
@export var attack_stats_jump : AttackStats
@export var attack_stats_fall : AttackStats
@export var attack_stats_pogo : AttackStats

## Songs available for filtering by saved player progress.
@export var song_catalog      : SongCatalog
## Seconds between drawing the instrument for a lesson and starting its track; the clip must advance before playback freezes the world.
@export var lesson_lead_in    : float = 0.5
## Seconds for the shield amount to reach its recall value.
@export var recall_glow_time  : float = 0.2

@export_category("Hazards")
## Sink speed in px/s; sink drag in px/s².
@export var sink_speed        : float = 40.0
@export var sink_drag         : float = 2400.0
## Invulnerability duration in seconds after respawning from a hazard.
@export var hazard_grace      : float = 1.0

@export_category("Wind")
## Wind exposure fraction while the instrument is out (design 03, section 5.4).
@export_range(0.0, 1.0) var memorina_shelter: float = 0.5
## Wind speed in px/s required to enter the brace pose.
@export var brace_wind        : float = 60.0

var _states: CharacterStateMachine
## Attack context selected at sequence start; empty while not attacking.
var _attack_context: StringName = &""
## Active combat-disabled zones; overlapping zones increment this counter.
var _combat_disable_count: int = 0
## A double jump has no lasting gameplay state of its own — afterwards Ivo is
## simply rising — so the event is exposed as a one-frame pulse. It fires
## inside `_process_motion`, so it is cleared at the top of the next one.
var _just_double_jumped: bool = false
## The buttons the last note was pressed on. MemorinaComponent never sees
## glyphs; this rides beside its `note_played` when Ivo relays it, and a lesson
## draws its sheet with it.
var _last_glyph_set: Enums.GlyphSet = Enums.GlyphSet.KEYBOARD_ARROWS
## Correct notes in the current guardian-call answer.
var _call_progress: int = 0
## Staged caller height in world pixels, used to place the sheet.
var _staged_height: float = 0.0
## Guardian currently staged for a call.
var _staged_caller: Node2D
## True while the guardian's phrase plays and the answer window is not open.
var _call_listening: bool = false
## Matched or taught song waiting to be performed; started by `_tick_pending_performance`.
var _pending_performance: Song = null
## True when the pending performance is a lesson (the whole track, not the excerpt).
var _pending_lesson: bool = false
## Seconds of lesson lead-in left before the pending track may start.
var _lead_in_left: float = 0.0
## True when an answered call should sheath after the note finishes.
var _pending_sheathe: bool = false
## Authored shield amount restored when recall ends.
var _resting_shield_amount: float = 0.0
var _glow_tween: Tween
## Direction away from the recall source and remaining escape time in seconds.
var _recall_escape_axis: float = 0.0
var _recall_escape_left: float = 0.0
## Recall waiting for its cue, plus remaining cue time in seconds.
var _pending_recall: AbilityRecallStats = null
var _pending_recall_left: float = 0.0
## Source body used by a pending distance-triggered recall.
var _pending_recall_source: Node2D
## True while sinking without player control.
var _sinking: bool = false
## True after `death_shown` emits for this death.
var _death_shown: bool = false
## Pending down press, handled on the next physics frame.
var _sit_requested: bool = false
## Pending press to stand without triggering its action.
var _stand_requested: bool = false

func _enter_tree() -> void:
	add_to_group(GROUP)
	# What creatures take for the hero: him, and any shadow he burns.
	add_to_group(EnemySight.PRESENCE)

func _ready() -> void:
	super()

	# Seated, a press only gets him up: routed through _unless_seated, it never
	# reaches the component's buffer, so it cannot also jump or swing. With the
	# instrument out, a face button is a note (the gamepad's double duty), so
	# _as_move drops the move it also means instead of buffering it.
	_input.jump_pressed.connect(_as_move.bind(_jump.buffer_jump))
	_input.jump_canceled.connect(_jump.cut_jump)
	# Components emit these, but ivo.tscn wires its DustEmitter to Player's own
	# signals with from=".". Re-emitting keeps those scene connections working
	# untouched, so moving logic into a component never costs a scene edit.
	_jump.jumped.connect(jumped.emit)
	_landing.hard_landed.connect(hard_landed.emit)
	_double_jump.double_jumped.connect(_on_double_jumped)
	_input.roll_pressed.connect(_as_move.bind(_roll.buffer_roll))
	# The recall hears the same presses the abilities buffer, and unlocks the
	# skill in the same frame, before _try_roll/_try_jump run - so the press
	# that remembers the roll is also the roll that dodges the attack.
	_input.roll_pressed.connect(_notify_recall.bind(&"roll"))
	_input.jump_pressed.connect(_notify_recall.bind(&"jump"))
	_recall.recalled.connect(_on_skill_recalled)
	_recall.step_taken.connect(recall_step_taken.emit)
	_recall.missed.connect(_on_skill_recall_missed)
	_input.attack_pressed.connect(_as_move.bind(_attack.buffer_attack))
	_input.draw_memorina_pressed.connect(_unless_seated.bind(_memorina.buffer_toggle))
	_input.look_down_pressed.connect(func() -> void: _sit_requested = true)
	_input.note_pressed.connect(_on_note_pressed)
	_input.debug_learn_song_pressed.connect(_on_debug_learn_song_pressed)
	_memorina.drawn.connect(_on_memorina_drawn)
	_memorina.sheathed.connect(_on_memorina_sheathed)
	_memorina.note_played.connect(_on_note_played)
	_memorina.note_rejected.connect(_on_note_rejected)
	_memorina.sequence_failed.connect(_on_sequence_failed)
	_memorina.song_matched.connect(_on_song_matched)
	_memorina.song_played.connect(_on_song_played)
	_memorina.call_answered.connect(call_answered.emit)
	_voice.mistake_finished.connect(sequence_reset.emit)
	_performance.started.connect(performance_started.emit)
	_performance.cue_reached.connect(note_cue_reached.emit)
	_performance.finished.connect(_on_performance_finished)
	_attack.phase_started.connect(_on_attack_phase_started)
	_hitbox.connected.connect(_on_hitbox_connected)
	health.damaged.connect(_relay_health.unbind(2))
	health.healed.connect(_relay_health.unbind(2))
	# Deferred: whoever listens is wired by the scene and may not be ready yet.
	_relay_health.call_deferred()
	# facing_changed only fires on a CHANGE, so without this the hitbox would
	# sit at its authored (facing-right) offset until the first turn, wrong
	# whenever Ivo starts a scene already facing left.
	_hitbox._on_character_facing_changed(facing)

	_double_jump.jump = _jump
	_wall_mobility.jump = _jump
	_wall_mobility.double_jump = _double_jump

	_states = CharacterStateMachine.new()
	_states.add_state(MotionState.KNOCKBACK, _knockback_motion)
	_states.add_state(MotionState.ROLL, _roll_motion)
	_states.add_state(MotionState.GROUND, _ground_motion)
	_states.add_state(MotionState.AIR, _air_physics)
	_states.add_state(MotionState.CLIMB, _climb_motion)
	_states.add_state(MotionState.SIT, _sit_motion)
	_resting_shield_amount = _shield.amount

	_assert_clip_durations()
	if OS.is_debug_build() and song_catalog:
		song_catalog.validate()

func _process_motion(delta: float) -> void:
	_just_double_jumped = false
	if is_dead():
		# A corpse still falls and stops sliding; nothing else.
		_knockback_motion(delta)
		if not _death_shown and _player_resolver.is_death_finished():
			_death_shown = true
			death_shown.emit()
		return
	var on_floor := is_on_floor()
	# Ticked while sinking too: a press made under water must expire there,
	# not fire on the first frame back on the bank.
	_tick_input_timers(delta, on_floor)
	if _sinking:
		# A down press under water must not sit him on whatever bench the
		# respawn puts him beside.
		_sit_requested = false
		_sink_motion(delta)
		return
	_try_sit(on_floor)
	if _sit.is_sitting():
		if _wants_to_stand():
			_stand_up()
		else:
			_states.transition_to(MotionState.SIT)
			_states.update(delta)
			return

	face_towards(move_axis())
	# The recall's window is real seconds: the world is slowed while it is open,
	# and `delta` is game time.
	_recall.tick(delta / maxf(Engine.time_scale, 0.001))
	_tick_pending_recall(delta)
	_recall_escape_left = maxf(_recall_escape_left - delta, 0.0)
	# Checked every frame rather than hooked to one event, because everything
	# that ends a performance - stepping off a ledge, being knocked back, ice
	# melting underfoot - is simply "no longer standing still".
	if _memorina.is_drawn() and not is_still():
		_memorina.interrupt()
	# After the interrupt, so a performance never starts in the frame that ends it.
	_tick_pending_performance(delta)
	_pogo.enabled = _can_use_sword()
	# The body's judgement, pushed into the component like `enabled`: the air
	# reaching Ivo is his own business, sampled next frame.
	_airflow_body.exposure = memorina_shelter if _memorina.is_drawn() else 1.0
	if on_floor:
		_double_jump.refresh()
	_landing.tick_timer(delta, on_floor)
	_try_climb()

	_states.transition_to(_select_motion_state(on_floor))
	_states.update(delta)

	_try_memorina()
	_try_jump(on_floor)
	_try_roll(on_floor)
	_try_attack()

func _after_move(_delta: float) -> void:
	var on_floor := is_on_floor()
	_landing.check_landing(on_floor)
	if on_floor:
		_wall_mobility.stop()

#############################################
##  S T A T E   Q U E R I E S              ##
#############################################
## Read by PlayerAnimationResolver (and the camera); no animation logic here.

func _assert_clip_durations() -> void:
	_assert_clip_length(PlayerAnimationResolver.ROLL, _roll.stats.roll_time + _roll.stats.roll_recovery_time)
	for context in ATTACK_CONTEXTS:
		var stats := _attack_stats_for(context)
		for i in stats.phases.size():
			_assert_clip_length(_player_resolver.attack_clip_for(context, i), stats.phases[i].duration)

func move_axis() -> float:
	if is_recovering() or is_rolling() or is_in_knockback():
		return 0.0
	# The arrows are note keys while the instrument is out, so they must not
	# also walk. This is what keeps the double duty of the keys unambiguous.
	if is_memorina_drawn():
		return 0.0
	if is_attacking() and _attack_context == CTX_IDLE:
		return 0.0
	return _input.direction

func wants_to_move() -> bool:
	return not is_zero_approx(move_axis())

func is_jumping() -> bool:
	return _jump.is_jumping

func is_rising() -> bool:
	return velocity.y < 0.0

func is_recovering() -> bool:
	return _landing.is_recovering()

func is_wall_sliding() -> bool:
	return _wall_mobility.is_sliding

## On something Enraizar grew (a root web or a pillar).
func is_climbing() -> bool:
	return _climb.is_climbing()

func climb_grip() -> Climbable.Grip:
	return _climb.grip()

func is_rolling() -> bool:
	return _roll.is_rolling()

func is_attacking() -> bool:
	return _attack.is_attacking()

func attack_phase_index() -> int:
	return _attack.current_phase_index

func attack_context() -> StringName:
	return _attack_context

func just_landed() -> bool:
	return _landing.just_landed()

func just_double_jumped() -> bool:
	return _just_double_jumped

func is_memorina_drawn() -> bool:
	return _memorina.is_drawn()

## Walking into a wind hard enough to lean into (the resolver's brace pose).
func is_bracing() -> bool:
	var axis := move_axis()
	return is_on_floor() and not is_zero_approx(axis) and signf(carry().x) == -signf(axis) and absf(carry().x) >= brace_wind

## The song precondition is firm ground and near-zero horizontal speed (design 02, section 6.2).
func is_still() -> bool:
	if not is_on_floor() or is_dead():
		return false
	if is_rolling() or is_attacking() or is_recovering() or is_in_knockback() or is_wall_sliding():
		return false
	if wants_to_move():
		return false
	return absf(velocity.x) < STILL_SPEED_EPSILON

#############################################
##  C A M E R A   I N T E N T              ##
#############################################
## Consumed by the camera; no animation binds to these. The two axes are
## mutually exclusive by construction — one requires standing, the other
## requires being airborne — so a camera may simply add them.

## Deliberate peek in [-1, 1] — negative up, positive down (screen space).
## Only a character standing still can peek, so this returns 0.0 while airborne,
## moving or recovering.
func look_axis() -> float:
	if not is_on_floor() or wants_to_move() or is_recovering():
		return 0.0
	# Down is what sat him; the camera must not peek along with it.
	if is_sitting():
		return 0.0
	# Up and Down are notes while playing; the camera must not peek along.
	if is_memorina_drawn():
		return 0.0
	return _input.look_direction

func air_axis() -> float:
	if is_on_floor():
		return 0.0
	return clampf(velocity.y / _jump.terminal_velocity(), -1.0, 1.0)

#############################################
##  L O C O M O T I O N                    ##
#############################################

func _select_motion_state(on_floor: bool) -> MotionState:
	if is_in_knockback():
		return MotionState.KNOCKBACK
	if is_rolling():
		return MotionState.ROLL
	if _climb.is_climbing():
		return MotionState.CLIMB
	return MotionState.GROUND if on_floor else MotionState.AIR

func _tick_input_timers(delta: float, on_floor: bool) -> void:
	_jump.tick_timers(delta, on_floor)
	_roll.tick_timers(delta, on_floor)
	_attack.tick_timers(delta)
	_memorina.tick_timers(delta)
	_climb.tick(delta)

# Sample sinking velocity to avoid classifying a water plunge as a hard landing.
func _sink_motion(delta: float) -> void:
	apply_knockback_decay(delta)
	velocity.y = move_toward(velocity.y, sink_speed, sink_drag * delta)
	_landing.sample_fall_speed(velocity.y)

func _knockback_motion(delta: float) -> void:
	_jump.apply_gravity(delta)
	apply_knockback_decay(delta)

func _roll_motion(delta: float) -> void:
	_jump.apply_gravity(delta)
	_roll.update(delta)

func _ground_motion(delta: float) -> void:
	_locomotion.ground_update(delta, move_axis(), carry().x)

# Up grabs a climbable surface only when Ivo is not rolling, hurt, or playing.
func _try_climb() -> void:
	if _climb.is_climbing() or is_rolling() or is_in_knockback() or is_memorina_drawn():
		return
	# A swing or a landing's recovery finishes first: the resolver would show
	# the attack while the body climbed.
	if is_attacking() or is_recovering():
		return
	if _input.look_direction < -0.5 and _climb.can_grab():
		_climb.grab()
		_wall_mobility.stop()

# Benches block gravity and wind while Ivo is seated.
func _sit_motion(_delta: float) -> void:
	velocity = Vector2.ZERO

# Down pressed sits him on a bench in reach - the body's judgement, like every
# other gate: on the floor with no direction held, and only when nothing else
# has him (a roll, a swing, a flinch, a climb, the instrument) and no fight is
# on - a guardian's fight around him, its call, or a recall it forced. A rest
# is never taken in the middle of a fight.
func _try_sit(on_floor: bool) -> void:
	if not _sit_requested:
		return
	_sit_requested = false
	if _sit.is_sitting() or not on_floor or wants_to_move():
		return
	if is_rolling() or is_attacking() or is_in_knockback() or is_climbing() or is_memorina_drawn():
		return
	if _staged_caller != null or _memorina.call_song != null:
		return
	if _recall.is_armed() or _pending_recall != null:
		return
	if Guardian.fight_at(get_tree(), global_position):
		return
	var seat := _sit.reachable()
	if seat == null:
		return
	sit(seat)
	sat_down.emit(seat)

# Movement, up, or any action press stands Ivo up.
func _wants_to_stand() -> bool:
	return _stand_requested or wants_to_move() or _input.look_direction < -0.5

func _stand_up() -> void:
	_stand_requested = false
	_sit.stand()

func _unless_seated(action: Callable) -> void:
	if _sit.is_sitting():
		_stand_requested = true
		return
	action.call()

# Do not buffer actions pressed while the instrument is out; those inputs are notes.
func _as_move(action: Callable) -> void:
	if is_memorina_drawn():
		return
	_unless_seated(action)

# Climbing suppresses gravity and wind; leaving over the top triggers a hop.
func _climb_motion(delta: float) -> void:
	match _climb.update(delta, Vector2(move_axis(), _input.look_direction)):
		ClimbComponent.Exit.OVER_THE_TOP:
			_jump.launch(_climb.top_hop_height)
		ClimbComponent.Exit.LET_GO:
			_jump.apply_gravity(delta)

func _air_physics(delta: float) -> void:
	_wall_mobility.enabled = _has_unlocked(Enums.PlayerSkill.WALL_CLIMB)
	if not _wall_mobility.update(delta, move_axis()):
		_jump.apply_gravity(delta)
	_locomotion.air_update(delta, move_axis(), carry().x)
	_locomotion.lift_update(delta, carry().y)
	_landing.sample_fall_speed(velocity.y)

#############################################
##  M E M O R I N A                        ##
#############################################

func _try_memorina() -> void:
	if not _memorina.has_buffered_toggle():
		return
	# The guardian is still singing: the press is dropped, not kept for later.
	if _call_listening:
		_memorina.sheathe()
		return
	if _memorina.is_drawn():
		_memorina.sheathe()
		return
	if is_attacking() or is_rolling() or is_recovering() or is_in_knockback():
		return
	_memorina.enabled = _has_item(Enums.PlayerItem.MEMORINA)
	_memorina.try_draw(is_still(), _known_songs())

## Whether a note may sound yet is the voice's verdict (never over the mistake,
## never inside the gap after the last note), pushed in here the same way
## is_still() gates the draw. The glyph is remembered so the relayed
## note_played can carry it.
func _on_note_pressed(note: Enums.Note, glyph_set: Enums.GlyphSet) -> void:
	if not _voice.can_play_note():
		return
	_last_glyph_set = glyph_set
	_memorina.receive_note(note)

func _on_note_played(note: Enums.Note) -> void:
	_voice.play_note(note)
	note_played.emit(note, _last_glyph_set)
	if _memorina.call_song != null:
		_call_progress += 1
		call_progress.emit(_call_progress)

func _on_note_rejected(note: Enums.Note) -> void:
	note_rejected.emit(note, _last_glyph_set)

## One failure, one sound. A wrong note never sounded, so the mistake plays at
## once; an interruption lets the note that was ringing finish first.
func _on_sequence_failed() -> void:
	_call_progress = 0
	_voice.play_mistake_after_note()
	sequence_failed.emit()

## Playback waits for the ringing note to end (`_tick_pending_performance`).
func _on_song_matched(song: Song) -> void:
	_pending_performance = song
	_pending_lesson = false
	_lead_in_left = 0.0

## Starts what waited for the last note on Ivo's pausable clock, never from the ALWAYS voice,
## which would start it under a menu (docs/knowledge/architecture/pause-menu-worldfreeze-reuse.md).
func _tick_pending_performance(delta: float) -> void:
	if _pending_sheathe and not _voice.is_busy():
		_pending_sheathe = false
		_memorina.sheathe()
	if _pending_performance == null:
		return
	_lead_in_left = maxf(_lead_in_left - delta, 0.0)
	if _lead_in_left > 0.0 or _voice.is_busy():
		return
	var song := _pending_performance
	var lesson := _pending_lesson
	_pending_performance = null
	_pending_lesson = false
	# Anything that sheathed or re-drew the instrument meanwhile cleared the way.
	if _memorina.performing_song() != song:
		return
	if lesson:
		_performance.play(song.track, song.cues())
	else:
		_performance.play(song.performance_stream(), song.cues(), song.excerpt_duration, song.excerpt_fade)

## Thaw before the song is played, so the pulse is born into a moving world.
func _on_performance_finished() -> void:
	performance_finished.emit()
	_memorina.finish_performance()

func _on_memorina_drawn(known_songs: Array[Song]) -> void:
	_call_progress = 0
	memorina_drawn.emit(known_songs, facing)

## Sheathing during playback or lesson lead-in must thaw the world.
func _on_memorina_sheathed() -> void:
	_pending_performance = null
	_pending_lesson = false
	_pending_sheathe = false
	if _performance.is_playing():
		_performance.stop()
		performance_finished.emit()
	memorina_sheathed.emit()

## The component reports WHAT was played; Ivo adds WHERE, because a pulse is
## born at the instrument. Same shape as jumped(position), and for the same
## reason: ivo.tscn wires its emitters to Player with from=".".
func _on_song_played(song: Song) -> void:
	song_played.emit(song, global_position)

## The lesson: the song is learned and its whole track performed, the sheet
## carrying the banner. A restored guardian calls this; F9 stands in for the
## guardians that do not exist yet. Refused unless Ivo OWNS the instrument
## and could draw it right now, and it is not saying no, so a lesson never
## starts without a Memorina, seated, mid-air, mid-run, mid-performance or over a
## mistake that would then clear its sheet - and the save is only touched
## once it will really start. A note still
## ringing (the last of a guardian's answer) is let finish before the track.
func learn_song(song: Song) -> bool:
	if song == null or _memorina.is_performing() or _voice.is_faulting() or not is_still() or is_sitting():
		return false
	# No instrument, no lesson. Handing one over is the WORLD's to do - a
	# pickup, the mentor - and a body that granted itself an item on the way
	# into a cutscene would skip that scene entirely.
	if not _has_item(Enums.PlayerItem.MEMORINA):
		return false
	SaveSystem.learn_song(song.id)
	# A call that was still open has been answered for good.
	if _memorina.call_song != null:
		_memorina.call_song = null
		call_closed.emit()
	if not _memorina.is_drawn():
		_memorina.enabled = true
		_memorina.try_draw(true, _known_songs())
	_memorina.start_performance(song)
	lesson_started.emit(song, _last_glyph_set)
	_pending_performance = song
	_pending_lesson = true
	_lead_in_left = lesson_lead_in
	return true

func _on_debug_learn_song_pressed() -> void:
	learn_song(_next_unknown_song())

#############################################
##  A   G U A R D I A N ' S   C A L L      ##
#############################################
## The guardian drives these directly; Ivo relays them as signals so the HUD
## keeps listening to one node.

## The guardian went lucid: the stage is set around it until unstage_call().
## `caller_height` is how tall the body on stage is, in world pixels; the
## sheet needs it to know whether it can hang above the pair.
func stage_call(caller: Node2D, caller_height: float = 0.0) -> void:
	# A call is answered standing: a first draw press must not only get him up.
	_stand_up()
	_staged_caller = caller
	_staged_height = caller_height
	call_staged.emit(caller)

func unstage_call() -> void:
	_staged_caller = null
	call_unstaged.emit()

## A lucidity window opened: from now until close_call(), the instrument
## listens for `song` alone - and stays in until the phrase has been heard.
func open_call(song: Song, revealed: int, cure_done: int, cure_total: int) -> void:
	_stand_up()
	if _memorina.is_drawn():
		_memorina.sheathe()
	_memorina.call_song = song
	_call_progress = 0
	_call_listening = true
	var side := facing
	if is_instance_valid(_staged_caller):
		side = 1 if _staged_caller.global_position.x >= global_position.x else -1
	call_opened.emit(song, revealed, _last_glyph_set, cure_done, cure_total, side, _staged_height)

func sound_call_note(index: int) -> void:
	call_note_sounded.emit(index)

## The call has been heard out: the turn passes to Ivo. How LONG he has is
## not carried here - the fight owns that clock and reports it every frame
## through call_window_progress, so nothing downstream runs a second one.
func open_call_window() -> void:
	_call_listening = false
	call_window_opened.emit()

## The guardian's clock, passed straight through. Ivo keeps no copy of it.
func update_call_window(fraction: float) -> void:
	call_window_progress.emit(fraction)

## The window is over. A good answer ends the gesture quietly, the way a
## finished performance does - once its last note has rung out, so the whole
## phrase is seen; anything else is the interruption the player already knows,
## the sheet flashing and the instrument going away. The instrument is
## interrupted BEFORE the call is cleared: clearing it resets the matcher, and
## an interruption only reports what was still in the buffer.
func close_call(success: bool) -> void:
	if _memorina.call_song == null:
		return
	_call_listening = false
	if success:
		if _voice.is_busy():
			_pending_sheathe = true
		else:
			_memorina.sheathe()
	else:
		_memorina.interrupt()
		# A window that ran out with nothing played has nothing to flash; the
		# mistake still sounds, so every failure is heard the same way.
		if not _voice.is_faulting():
			_voice.play_mistake_after_note()
	_memorina.call_song = null
	call_closed.emit()

#############################################
##  A B I L I T Y   R E C A L L            ##
#############################################

## The guardian's unavoidable attack has begun and the body has a moment to
## remember. The moment waits for its cue, for at most `attack_duration`: a
## recall with a `trigger_distance` waits for `source` (the body throwing the
## move) to come that close, so the world slows when the blow is about to land
## and not while it is still far off.
## If the cue never comes, the moment does not come. Nothing happens if a
## recall is already open.
func begin_recall(stats: AbilityRecallStats, attack_duration: float = 0.0, source: Node2D = null) -> void:
	if _recall.is_armed() or _pending_recall != null:
		return
	# A blow is coming: he is on his feet for it, so the press that remembers
	# the skill also performs it instead of only standing him up.
	_stand_up()
	_pending_recall = stats
	_pending_recall_source = source
	_pending_recall_left = maxf(attack_duration, 0.1)
	_tick_pending_recall(0.0)

func _tick_pending_recall(delta: float) -> void:
	if _pending_recall == null:
		return
	_pending_recall_left -= delta
	if _recall_cue_met(_pending_recall) and not is_dead():
		var stats := _pending_recall
		_pending_recall = null
		_pending_recall_source = null
		_open_recall(stats)
	elif _pending_recall_left <= 0.0:
		_pending_recall = null
		_pending_recall_source = null

## Every cue the stats ask for, met.
func _recall_cue_met(stats: AbilityRecallStats) -> bool:
	if stats.trigger_distance > 0.0:
		if not is_instance_valid(_pending_recall_source):
			return false
		if global_position.distance_to(_pending_recall_source.global_position) > stats.trigger_distance:
			return false
	return true

## How many presses the memory asks for is settled here, by where the body
## is standing at the instant the moment opens: a double jump caught with the
## feet planted is jump and then jump again.
func _open_recall(stats: AbilityRecallStats) -> void:
	var source := _pending_recall_source
	if not _recall.arm(stats, is_on_floor()):
		return
	_remember_escape(source)
	_glow_shield(1.0)
	recall_started.emit(stats.action, stats.window, _recall.steps_left())

## The recall hears the presses the abilities buffer, and is told where the
## body was when they came: the last press of a double jump only counts off
## the ground, and one given standing is left to the jump that gets him there.
func _notify_recall(action: StringName) -> void:
	_recall.notify(action, not is_on_floor())

## The body remembered: the skill is Ivo's for good, and the attack that
## forced it does not land while he finishes the move.
func _on_skill_recalled(stats: AbilityRecallStats) -> void:
	SaveSystem.unlock_skill(stats.skill)
	hurtbox.grant_invulnerability(stats.grace_time)
	# The blow that forced the memory must not also swallow the move it
	# bought. A knockback or a landing recovery still running would block
	# _try_jump / _try_roll on the very frame the press is meant to perform,
	# and the whole contract is that the press which remembers also acts.
	clear_knockback()
	_landing.cancel_recovery()
	_end_recall()
	skill_recalled.emit(stats.skill)

## The window closed on nothing: the design's tactical cost, then the fight
## goes on and the same attack will come again.
func _on_skill_recall_missed(stats: AbilityRecallStats) -> void:
	_end_recall()
	# Straight to health, not through the hurtbox: the launch that set the moment
	# up may have left i-frames running, and the cost must not hide behind them.
	if stats.miss_damage > 0 and not is_dead():
		health.take_damage(stats.miss_damage)
		_just_hit = health.is_alive()
	skill_recall_missed.emit(stats.skill)

func _end_recall() -> void:
	_glow_shield(_resting_shield_amount)
	recall_ended.emit()

func _relay_health() -> void:
	health_changed.emit(health.current_hp, health.max_hp)

## Death does not tick the recall, so an open window would leave the world
## slowed forever; it is dropped here, without a miss - there is no one left
## to miss.
func _on_health_died() -> void:
	super()
	_drop_recall()

## An open recall window would leave the world slowed forever if nothing ticks
## it (death, a hazard): dropped without a miss.
func _drop_recall() -> void:
	_pending_recall = null
	if _recall.cancel():
		_end_recall()

func _glow_shield(amount: float) -> void:
	if _glow_tween:
		_glow_tween.kill()
	_glow_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_glow_tween.tween_property(_shield, "amount", amount, recall_glow_time)

func _next_unknown_song() -> Song:
	if song_catalog == null:
		return null
	for song: Song in song_catalog.songs:
		if not SaveSystem.has_song(song.id):
			return song
	return null

## Only what the player has actually learned is a candidate - an unlearned
## sequence has to read as noise, not as a locked door.
func _known_songs() -> Array[Song]:
	var known: Array[Song] = []
	if song_catalog == null:
		return known
	for song: Song in song_catalog.songs:
		if SaveSystem.has_song(song.id):
			known.append(song)
	return known

#############################################
##  J U M P I N G                          ##
#############################################

func _try_jump(on_floor: bool) -> void:
	if is_recovering() or is_rolling() or not _jump.has_buffered_jump() or is_attacking():
		return
	if is_memorina_drawn():
		return

	_double_jump.enabled = _has_unlocked(Enums.PlayerSkill.DOUBLE_JUMP)

	# A jump from what he climbs is a jump from firm ground.
	if _climb.is_climbing():
		_climb.release()
		_jump.try_ground_jump(true)
		return
	if _jump.try_ground_jump(on_floor):
		_wall_mobility.stop()
	elif _double_jump.try_jump():
		_wall_mobility.stop()

## Where a roll goes when nothing is held: normally the way Ivo faces (the
## component's own fallback, from a zero axis), but for the moment after a
## recall, AWAY from the thing that forced it - he is facing the charge, and
## a dodge into it is not a dodge.
func _dodge_axis() -> float:
	var axis := move_axis()
	if not is_zero_approx(axis) or _recall_escape_left <= 0.0:
		return axis
	return _recall_escape_axis

## `source` is the body throwing the move, remembered as a DIRECTION so the
## dodge still knows which way to go once the source has moved on.
func _remember_escape(source: Node2D) -> void:
	_recall_escape_axis = 0.0
	_recall_escape_left = 0.0
	if not is_instance_valid(source):
		return
	var away := signf(global_position.x - source.global_position.x)
	if is_zero_approx(away):
		return
	_recall_escape_axis = away
	_recall_escape_left = RECALL_ESCAPE_TIME

func _on_double_jumped(jump_position: Vector2) -> void:
	_just_double_jumped = true
	double_jumped.emit(jump_position)

func _try_roll(on_floor: bool) -> void:
	if is_attacking() or not _roll.has_buffered_roll() or is_memorina_drawn():
		return

	_roll.enabled = _has_unlocked(Enums.PlayerSkill.ROLL)
	_roll.try_roll(on_floor, _dodge_axis(), facing)

#############################################
##  A T T A C K I N G                      ##
#############################################

func _try_attack() -> void:
	if not _attack.has_buffered_attack():
		return
	if is_recovering() or is_rolling() or is_in_knockback() or is_memorina_drawn():
		return

	_attack.enabled = _can_use_sword()

	var context: StringName = _current_attack_context()
	if _attack.try_attack(_attack_stats_for(context)):
		_attack_context = context

func _on_hit_received(damage: int, knockback: Vector2, source: Node2D) -> void:
	super(damage, knockback, source)
	_react_to_hurt()

## Ivo does not swim: water costs him health and, if he survives it, he sinks
## out of control until the composition root has faded out and respawn()ed
## him. A fall that kills him is the ordinary death, sinking as a corpse.
## Whether the water has him (from the fall until the respawn).
func is_sinking() -> bool:
	return _sinking

## Whether the death clip has played out (death_shown has fired).
func is_death_shown() -> bool:
	return _death_shown

func is_sitting() -> bool:
	return _sit.is_sitting()

## Puts him on `seat`, sitting, without the rest that sitting down himself
## asks for: arrival at the bench after a death or a load.
func sit(seat: Seat) -> void:
	_climb.release()
	_wall_mobility.stop()
	clear_knockback()
	_landing.cancel_recovery()
	_sit.sit(seat)

## A bench's rest, for his body: whole again.
func rest() -> void:
	health.reset()

func receive_hazard(hazard: HazardZone) -> void:
	if is_dead() or _sinking:
		return
	super(hazard)
	_react_to_hurt()
	_drop_recall()
	if is_dead():
		return
	_sinking = true
	_safe_ground.enabled = false
	clear_knockback()
	fell_into_hazard.emit()

## Puts Ivo back on the last firm ground he stood on (SafeGroundTracker),
## still and briefly untouchable. Called behind a fade; nothing here eases.
func respawn() -> void:
	assert(not is_dead(), "A corpse is not respawned")
	_sit_requested = false
	global_position = _safe_ground.last_safe_position()
	velocity = Vector2.ZERO
	_sinking = false
	_safe_ground.enabled = true
	clear_knockback()
	_landing.cancel_recovery()
	hurtbox.grant_invulnerability(hazard_grace)

# What any hurt interrupts. The Memorina is not covered by the is_still()
# check: a hit that deals no knockback leaves Ivo standing perfectly still.
func _react_to_hurt() -> void:
	hurt.emit()
	_attack.cancel()
	_memorina.interrupt()
	# Being hurt knocks him off what he was holding, and off a bench.
	_climb.release()
	_stand_up()

func _on_attack_phase_started(_phase_index: int, phase: AttackPhaseData) -> void:
	_hitbox.damage = phase.damage
	_hitbox.knockback_strength = phase.knockback_strength
	_hitbox.knockback_lift = phase.knockback_lift
	# A sequence can end and a new one begin in the same frame (a pogo chain),
	# leaving the clip name unchanged — the swing still has to restart.
	_animation_driver.request_replay()

## Only pogo hits bounce Ivo; all attack contexts share this hitbox.
func _on_hitbox_connected(_target: Hurtbox) -> void:
	hit_landed.emit()
	if _attack_context == CTX_POGO:
		_pogo.try_bounce()

## Context is resolved once, at the moment a NEW sequence starts (see
## _try_attack), and held in _attack_context for the sequence's whole
## duration - AttackComponent itself never branches on it.
func _current_attack_context() -> StringName:
	if not is_on_floor():
		if _input.look_direction > 0.0:
			return CTX_POGO
		return CTX_JUMP if is_rising() else CTX_FALL
	return CTX_RUN if wants_to_move() else CTX_IDLE

func _attack_stats_for(context: StringName) -> AttackStats:
	match context:
		CTX_RUN:
			return attack_stats_run
		CTX_JUMP:
			return attack_stats_jump
		CTX_FALL:
			return attack_stats_fall
		CTX_POGO:
			return attack_stats_pogo
		_:
			return attack_stats_idle

## Item possession alone is not enough - sword use is also off wherever combat
## is disabled (safe rooms, NPC vicinity), tracked via _combat_disable_count.
func _can_use_sword() -> bool:
	return _has_item(Enums.PlayerItem.SWORD) and _combat_disable_count <= 0

## Wired per-scene from any CombatDisabledZone placed in a safe room or an
## NPC's own scene - see combat_disabled_zone.gd. A counter, not a bool,
## because overlapping zones must combine additively.
func _on_combat_zone_entered() -> void:
	_combat_disable_count += 1

func _on_combat_zone_exited() -> void:
	_combat_disable_count -= 1

#############################################
##  A B I L I T I E S                      ##
#############################################

func _has_unlocked(skill: Enums.PlayerSkill) -> bool:
	return SaveSystem.has_skill(skill)

func _has_item(item: Enums.PlayerItem) -> bool:
	return SaveSystem.has_item(item)
