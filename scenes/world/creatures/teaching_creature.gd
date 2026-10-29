class_name TeachingCreature extends Node2D

## A coloured creature that sings a song's first half for Ivo to echo (design 02 section 2; systems/teaching-creatures).
## The glue between Ivo, its TeachingFlow, its voices and the HUD balloon; it has no body, so blows pass through.

## Teachers teach the first half; songbooks the second (FoundPickup.TAUGHT_HALF).
const TAUGHT_HALF := Enums.SongHalf.FIRST

## Set in the species scene.
@export var lesson: CreatureLesson

var _flow: TeachingFlow
var _ivo: Player
var _teachable: bool = false
## phrase_echoed arrived; acted on at the next tick, never inside the note's own call.
var _echoed: bool = false
var _flourish_pending: bool = false

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _driver: AnimationDriver = $AnimationDriver
@onready var _resolver: TeacherAnimationResolver = $AnimationResolver
@onready var _anchor: Marker2D = $BalloonAnchor
@onready var _call: PhraseCall = $Call
@onready var _duet: PhraseCall = $Duet


func _ready() -> void:
	assert(lesson != null, "%s has no lesson" % name)
	if OS.is_debug_build():
		lesson.validate()
	_resolver.driver = _driver
	_flow = TeachingFlow.new(lesson)
	_flow.sing_requested.connect(_on_sing_requested)
	_flow.sing_stopped.connect(_stop_singing)
	_flow.balloon_shown.connect(_on_balloon_shown)
	_flow.revealed.connect(_on_revealed)
	_flow.lit.connect(_on_lit)
	_flow.shaken.connect(_on_shaken)
	_flow.balloon_closed.connect(_on_balloon_closed)
	_flow.learn_requested.connect(_on_learn_requested)
	_flow.flourished.connect(_on_flourished)
	_call.note_sounded.connect(_flow.note_sung)
	_call.finished.connect(_flow.phrase_sung)
	SaveSystem.progress_changed.connect(_refresh_teachable)
	_refresh_teachable()

func _physics_process(delta: float) -> void:
	_find_ivo()
	if _ivo != null:
		var near := lesson.reaches(global_position, _ivo.global_position)
		_flow.set_near(near)
		_flow.set_busy(_ivo.is_in_story() or _ivo.is_in_lesson())
		if near:
			_face(_ivo.global_position.x)
		_sync_echo(near)
		if _echoed:
			_echoed = false
			_flow.echoed(SongHalves.completes(SaveSystem.player_data, lesson.song.id, TAUGHT_HALF))
	_flow.tick(delta)
	_driver.play(_resolver.resolve())
	_flourish_pending = false

# A room that idles or unloads stops this node's tick, which alone would close the echo.
func _notification(what: int) -> void:
	if what == NOTIFICATION_DISABLED or what == NOTIFICATION_EXIT_TREE:
		_release()

func is_singing() -> bool:
	return _call.is_calling() or _duet.is_calling()

## The flourish was asked for this tick; the resolver holds it until the clip ends.
func flourish_pending() -> bool:
	return _flourish_pending

func flow() -> TeachingFlow:
	return _flow

func _find_ivo() -> void:
	if is_instance_valid(_ivo):
		return
	_ivo = get_tree().get_first_node_in_group(Player.GROUP) as Player
	if _ivo == null:
		return
	_ivo.memorina_drawn.connect(_on_ivo_drew.unbind(2))
	_ivo.memorina_sheathed.connect(_on_ivo_sheathed)
	_ivo.note_played.connect(_on_ivo_note.unbind(2))
	_ivo.sequence_failed.connect(_on_ivo_failed)
	_ivo.sequence_reset.connect(_on_ivo_reset)
	_ivo.phrase_echoed.connect(_on_ivo_echoed)

## The echo is open exactly while Ivo is in reach of an untaught teacher.
func _sync_echo(near: bool) -> void:
	var mine := _ivo.is_echo_open() and _ivo.echo_phrase() == lesson.phrase()
	if near and _teachable:
		_ivo.open_echo(lesson.phrase())
	elif mine:
		_ivo.close_echo()

## Closes Ivo's echo if it is this teacher's, and the balloon with it.
func _release() -> void:
	if _flow != null:
		_flow.set_near(false)
	if is_instance_valid(_ivo) and _ivo.is_echo_open() and _ivo.echo_phrase() == lesson.phrase():
		_ivo.close_echo()

func _owns_echo() -> bool:
	return _ivo != null and _ivo.is_echo_open() and _ivo.echo_phrase() == lesson.phrase() \
		and lesson.reaches(global_position, _ivo.global_position)

func _face(x: float) -> void:
	# The art faces west.
	_sprite.scale.x = -1.0 if x > global_position.x else 1.0

func _refresh_teachable() -> void:
	_teachable = SongHalves.can_teach(SaveSystem.player_data, lesson.song.id, TAUGHT_HALF)
	_flow.set_teachable(_teachable)

func _balloon() -> TeacherBalloon:
	return TeacherBalloon.find(get_tree())

func _on_sing_requested(interval: float, lead_in: float, duet: bool) -> void:
	_call.note_interval = interval
	_call.play(lesson.phrase(), lead_in)
	if duet:
		_duet.note_interval = interval
		_duet.play(lesson.phrase(), lead_in)

func _stop_singing() -> void:
	_call.stop()
	_duet.stop()

func _on_balloon_shown(lit_as_sung: bool) -> void:
	var balloon := _balloon()
	if balloon != null:
		balloon.show_for(_anchor, lesson.phrase(), lit_as_sung)

func _on_revealed(index: int) -> void:
	var balloon := _my_balloon()
	if balloon != null:
		balloon.reveal(index)

func _on_lit(count: int) -> void:
	var balloon := _my_balloon()
	if balloon != null:
		balloon.light(count)

func _on_shaken() -> void:
	var balloon := _my_balloon()
	if balloon != null:
		balloon.shake()

func _on_balloon_closed(linger: float) -> void:
	var balloon := _my_balloon()
	if balloon != null:
		balloon.close(linger)

## The balloon while it is over this teacher; another teacher's is never touched.
func _my_balloon() -> TeacherBalloon:
	var balloon := _balloon()
	if balloon == null or balloon.speaker() != _anchor:
		return null
	return balloon

func _on_learn_requested() -> void:
	var ok := _ivo != null and _ivo.learn_song_half(lesson.song, TAUGHT_HALF, false)
	if not ok and _ivo != null and _owns_echo():
		# A fresh echo: the finished one ignores every note.
		_ivo.close_echo()
		_ivo.open_echo(lesson.phrase())
	_flow.learned(ok)

func _on_flourished() -> void:
	_flourish_pending = true
	_driver.request_replay()

func _on_ivo_drew() -> void:
	_flow.drawn()

func _on_ivo_sheathed() -> void:
	if _owns_echo():
		_flow.echo_cleared()

func _on_ivo_note() -> void:
	if _owns_echo():
		_flow.note_echoed()

func _on_ivo_failed() -> void:
	if _owns_echo():
		_flow.echo_failed()

func _on_ivo_reset() -> void:
	if _owns_echo():
		_flow.echo_reset()

func _on_ivo_echoed() -> void:
	if _owns_echo():
		_echoed = true
