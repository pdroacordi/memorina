class_name IvoSounds
extends Node
## Ivo's body sounds: one-shots from his signals, steps and climb steps by animation contact (systems/sound-effects).
## Explicit PAUSABLE, so it sounds while Game holds Ivo DISABLED through a fade and pauses with the tree.

@export var sounds: IvoSoundSet
@export var footfalls: StepContacts

var _clock := StepClock.new()
var _was_climbing: bool = false

@onready var _player: Player = get_parent()
@onready var _emitter: SfxEmitter = $SfxEmitter


# A child of Ivo, so it runs after his move and after his AnimationTree has advanced this frame.
func _physics_process(_delta: float) -> void:
	var climbing := _player.is_climbing()
	if climbing and not _was_climbing:
		_emitter.play(sounds.climb_grab)
	_was_climbing = climbing
	var clip := _player.animation_state()
	var crossed := _clock.advance(clip, _player.animation_position(), _player.animation_length(),
			footfalls.contacts_of(clip))
	if crossed == 0 or _player.is_dead():
		return
	if climbing:
		_emitter.play(sounds.climb_step)
		return
	var ground := sounds.surface(_player.floor_surface())
	if ground != null:
		_emitter.play(ground.step)

## The emitter every voice goes through, for tests and the playtest log.
func emitter() -> SfxEmitter:
	return _emitter

func on_jumped(_at: Vector2) -> void:
	_emitter.play(sounds.jump)

func on_double_jumped(_at: Vector2) -> void:
	_emitter.play(sounds.double_jump)

func on_landed(_at: Vector2, impact_speed: float) -> void:
	if impact_speed < sounds.soft_land_min_speed or _player.is_dead():
		return
	var ground := sounds.surface(_player.floor_surface())
	if ground != null:
		_emitter.play(ground.land, ImpactLevel.db(impact_speed, sounds.soft_land_min_speed, sounds.soft_land_full_speed))

func on_hard_landed(_at: Vector2, _impact_speed: float) -> void:
	if not _player.is_dead():
		_emitter.play(sounds.land_hard)

func on_swung(_phase_index: int) -> void:
	_emitter.play(sounds.swing)

# A killing hit emits `died` before `hurt`: the death sound stands alone.
func on_hurt() -> void:
	if not _player.is_dead():
		_emitter.play(sounds.hurt)

func on_died() -> void:
	_emitter.play(sounds.death)

func on_sat_down(_seat: Seat) -> void:
	_emitter.play(sounds.rest)

func on_door_entered(door: Door) -> void:
	_emitter.play(sounds.door_open.get(door.look) as SoundCue)

func on_arrived_through(door: Door) -> void:
	_emitter.play(sounds.door_close.get(door.look) as SoundCue)

func on_door_knocked(_door: Door) -> void:
	_emitter.play(sounds.door_knock)

func on_took(what: Player.Taken) -> void:
	_emitter.play(sounds.taken.get(what) as SoundCue)
