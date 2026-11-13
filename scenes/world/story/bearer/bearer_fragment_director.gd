class_name BearerFragmentDirector
extends Node
## Runs a bearer fragment from Ivo's world performance of its song to the returning scene: the call in the room, the
## engraving on the hidden stage, the way back (architecture/story-04-bearer-fragments). Pausable and scaled; the pending
## fragment and the return point live in memory only, and nothing here writes the save.

## Asks Game to carry Ivo to `point` under a `colour` cover of `seconds` (0 cuts); Game answers with on_travelled.
signal travel_requested(point: TravelPoint, colour: Color, seconds: float)

const GROUP := &"bearer_directors"

enum Stage { IDLE, WAITING, CALLING, TRAVELLING_IN, ENGRAVING, LEAVING, TRAVELLING_BACK, RETURNING }

@export var catalog: BearerFragmentCatalog
@export var cutscenes: CutsceneDirector
@export var flashbacks: FlashbackDirector
@export var ivo: Player
## Its paper is the colour the call covers the screen in and the travel keeps.
@export var engraving: EngravingView
## Scaled seconds the start gates are checked for once the song's pulse is gone; then the fragment waits for the next
## performance of its song.
@export var start_grace: float = 2.0

var _stage: Stage = Stage.IDLE
var _fragment: BearerFragment
var _grace_left: float = 0.0
var _return: TravelPoint
## The room Game last made current.
var _room: Room
var _music: MusicRequest


func _enter_tree() -> void:
	add_to_group(GROUP)

func _ready() -> void:
	if ivo != null:
		ivo.song_performed.connect(on_song_performed)
	if cutscenes != null:
		cutscenes.scene_ended.connect(_on_scene_ended)
		if OS.is_debug_build() and catalog != null:
			var problems := catalog.validate(cutscenes.catalog, BearerFragmentCatalog.shipped_stats(), _paper())
			assert(problems.is_empty(), "Bearer fragment catalog: %s" % "; ".join(problems))

## Out of the tree (a death's SceneSwap, a quit): the fragment is forgotten and nothing is written, so it stays due.
func _exit_tree() -> void:
	_stage = Stage.IDLE
	_fragment = null
	_return = null
	_music = null

func _physics_process(delta: float) -> void:
	match _stage:
		Stage.WAITING:
			_tick_waiting(delta)
		Stage.LEAVING:
			_stage = Stage.TRAVELLING_BACK
			travel_requested.emit(_return, Color.BLACK, 0.0)

## The fragment pending or playing, or null.
func pending() -> BearerFragment:
	return _fragment

## Whether a fragment is past its call: on the stage or on its way there or back.
func is_visiting() -> bool:
	return _stage in [Stage.TRAVELLING_IN, Stage.ENGRAVING, Stage.LEAVING, Stage.TRAVELLING_BACK, Stage.RETURNING]

## The point Ivo goes back to, or null outside a visit.
func return_point() -> TravelPoint:
	return _return

## Connected to `Player.song_performed`: a due fragment of `song` waits for its pulse to end.
func on_song_performed(song: Song) -> void:
	if _stage != Stage.IDLE or catalog == null:
		return
	var fragment := catalog.by_song(song)
	if fragment == null or not BearerSchedule.due(SaveSystem.player_data, fragment):
		return
	_fragment = fragment
	_grace_left = start_grace
	_stage = Stage.WAITING

## Connected to `Game.room_changed`.
func on_room_changed(room: Room) -> void:
	_room = room

## Connected to `Game.travelled`, a broadcast: acted on only while this director awaits its own travel.
func on_travelled(arrived: bool) -> void:
	match _stage:
		Stage.TRAVELLING_IN:
			if not arrived:
				if cutscenes != null and cutscenes.fade != null:
					cutscenes.fade.to_clear()
				_finish()
				return
			_stage = Stage.ENGRAVING
			if not _play(_fragment.engraving, _stage_room()):
				_stage = Stage.LEAVING
		Stage.TRAVELLING_BACK:
			# Ivo never stays on the stage: a refused travel back is asked again on the next frame.
			if not arrived:
				_stage = Stage.LEAVING
				return
			_stage = Stage.RETURNING
			if not _play(_fragment.returning, _return.room):
				_finish()

## Every start gate holds: Ivo free for a scene, the Memorina sheathed, no lesson, talk, scene, fight or past, no other
## scene or visit, and no acting pulse of any song.
func can_start() -> bool:
	if ivo == null or not ivo.is_inside_tree() or cutscenes == null or _room == null:
		return false
	if not ivo.can_begin_scene() or ivo.is_memorina_drawn() or NoticeHold.applies(ivo) or ivo.in_past:
		return false
	if cutscenes.is_playing() or (flashbacks != null and flashbacks.visiting() != null):
		return false
	for member: Node in get_tree().get_nodes_in_group(ColorPulse.GROUP):
		if (member as ColorPulse).acts():
			return false
	return true

func _tick_waiting(delta: float) -> void:
	if not BearerSchedule.due(SaveSystem.player_data, _fragment):
		_finish()
		return
	# The song's own effect first: the grace counts once its pulse is gone.
	if not ColorPulse.lit(self, _fragment.song.id).is_empty():
		return
	if can_start():
		_call()
		return
	_grace_left -= delta
	if _grace_left <= 0.0:
		_finish()

func _call() -> void:
	var stage := _stage_room()
	if stage == null:
		push_error("Bearer fragment: no stage room '%s'" % _fragment.stage_room)
		_finish()
		return
	stage.prepare()
	_stage = Stage.CALLING
	if not _play(_fragment.call, _room):
		_finish()

func _on_scene_ended(scene: Cutscene) -> void:
	if _fragment == null or scene == null:
		return
	match _stage:
		Stage.CALLING:
			if scene.id != _fragment.call.id:
				return
			# A hurt drops the call unrecorded and its fade with it: the fragment stays due.
			if not cutscenes.ended_recorded():
				_finish()
				return
			_travel_in()
		Stage.ENGRAVING:
			if scene.id == _fragment.engraving.id:
				_stage = Stage.LEAVING
		Stage.RETURNING:
			if scene.id == _fragment.returning.id:
				_finish()

func _travel_in() -> void:
	var stage := _stage_room()
	if stage == null or ivo == null or _room == null:
		_finish()
		return
	_return = TravelPoint.new(_room, ivo.global_position, ivo.facing)
	if _fragment.music != null:
		_music = Music.request(_fragment.music, MusicRequest.Layer.SCENE, self)
	_stage = Stage.TRAVELLING_IN
	var feet := stage.get_bounds().position + _fragment.arrival
	travel_requested.emit(TravelPoint.new(stage, feet, _fragment.arrival_facing), _paper(), 0.0)

## Plays `scene` on `room`'s contents, so its ids resolve there; false when it cannot play.
func _play(scene: Cutscene, room: Room) -> bool:
	var host := room.contents() if room != null else null
	if cutscenes == null or host == null or not cutscenes.play(scene, host):
		push_error("Bearer fragment: '%s' could not play" % (scene.id if scene != null else &""))
		return false
	return true

func _stage_room() -> Room:
	if _fragment == null:
		return null
	for room: Room in get_tree().get_nodes_in_group(Room.GROUP):
		if room.id() == _fragment.stage_room:
			return room
	return null

func _paper() -> Color:
	return engraving.paper if engraving != null else Color.BLACK

func _finish() -> void:
	if _music != null:
		# Its fade, never a ring-out: the song's track is a one-shot longer than the visit.
		Music.release(_music, _music.cue.fade_out)
	_music = null
	_fragment = null
	_return = null
	_stage = Stage.IDLE
