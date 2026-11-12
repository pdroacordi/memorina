class_name FlashbackDirector
extends Node
## Runs a flashback's visit: after its crossing, travel to the past, the opening, free play until the leaving scene,
## travel back to the same step and facing, the returning scene (architecture/story-05-playable-flashbacks).
## The return point lives in memory only; nothing here writes the save.

## Asks Game to carry Ivo to `point` under a `colour` cover of `seconds` (0 cuts); Game answers with on_travelled.
signal travel_requested(point: TravelPoint, colour: Color, seconds: float)
## A crossing was accepted: the visit runs from now until the returning scene ends.
signal visit_began(flashback: Flashback)

const GROUP := &"flashback_directors"
## The id of the cue with no stream that holds the music silent after the leaving scene.
const SILENCE := &"flashback_silence"

enum Stage { IDLE, WAITING_TALK, WAITING_MARK, TRAVELLING_IN, IN_PAST, LEAVING_TALK, TRAVELLING_BACK, RETURNING }

@export var catalog: FlashbackCatalog
@export var cutscenes: CutsceneDirector
@export var dialogue: DialogueDirector
@export var ivo: Player
## Its rest thickness has one writer: this director.
@export var letterbox: Letterbox

var _stage: Stage = Stage.IDLE
var _visit: Flashback
var _return: TravelPoint
## The room Game last made current.
var _room: Room
var _music: MusicRequest


## The director of the world `tree` runs; null when none is loaded.
static func find(tree: SceneTree) -> FlashbackDirector:
	return tree.get_first_node_in_group(GROUP) as FlashbackDirector

func _enter_tree() -> void:
	add_to_group(GROUP)

func _ready() -> void:
	if cutscenes != null:
		cutscenes.scene_ended.connect(_on_scene_ended)
		if OS.is_debug_build() and catalog != null:
			var problems := catalog.validate(cutscenes.catalog)
			assert(problems.is_empty(), "Flashback catalog: %s" % "; ".join(problems))

## Out of the tree (a death's SceneSwap, a quit): the visit is forgotten and nothing is written, so it stays due.
func _exit_tree() -> void:
	_stage = Stage.IDLE
	_visit = null
	_return = null
	_music = null

func _physics_process(_delta: float) -> void:
	match _stage:
		Stage.WAITING_TALK:
			if dialogue == null or not dialogue.is_talking():
				if _visit.music != null:
					_music = Music.request(_visit.music, MusicRequest.Layer.SCENE, self)
				_stage = Stage.WAITING_MARK
		Stage.WAITING_MARK:
			if _entry_reached():
				_try_travel_in()
		Stage.LEAVING_TALK:
			# A leaving scene played from a talk's beat: the talk ends under the black before the travel.
			if dialogue == null or not dialogue.is_talking():
				_stage = Stage.TRAVELLING_BACK
				travel_requested.emit(_return, Color.BLACK, 0.0)

## The visit running, or null.
func visiting() -> Flashback:
	return _visit

## The point Ivo goes back to, or null outside a visit.
func return_point() -> TravelPoint:
	return _return

## Connected to `Game.room_changed`.
func on_room_changed(room: Room) -> void:
	_room = room

## Connected to `Game.travelled`.
func on_travelled(arrived: bool) -> void:
	match _stage:
		Stage.TRAVELLING_IN:
			if not arrived:
				_finish()
				return
			_stage = Stage.IN_PAST
			_set_bars(_visit.bars_thin)
			_play(_visit.opening)
		Stage.TRAVELLING_BACK:
			_stage = Stage.RETURNING
			if not _play(_visit.returning):
				_finish()

func _on_scene_ended(scene: Cutscene) -> void:
	match _stage:
		Stage.IDLE:
			var found := catalog.by_crossing(scene) if catalog != null else null
			# A dropped crossing is unrecorded and never travels.
			if found != null and SaveSystem.is_scene_seen(scene.id) \
					and FlashbackSchedule.due(SaveSystem.player_data) == found.number:
				_visit = found
				_stage = Stage.WAITING_TALK
				var past := _past_room()
				if past != null:
					past.prepare()
				visit_began.emit(found)
		Stage.IN_PAST:
			if scene.id == _visit.leaving.id and SaveSystem.is_scene_seen(scene.id):
				_set_bars(0.0)
				_hush()
				_stage = Stage.LEAVING_TALK
		Stage.RETURNING:
			if scene.id == _visit.returning.id:
				_finish()

## The visit's music reached its entry mark, or plays no more.
func _entry_reached() -> bool:
	if _music == null or Music.playing() != _music or _visit.music.stream == null:
		return true
	return Music.position() >= _visit.entry_mark

## Travels in at the entry mark: hidden while Ivo stands, free and on the floor, inside the room's FlashbackSwap; else
## by the flashback's own entry.
func _try_travel_in() -> void:
	var swap := FlashbackSwap.in_room(_room, _visit.number)
	if swap != null and ivo != null and swap.holds(ivo):
		if ivo.is_on_floor() and not ivo.is_in_story():
			_travel_in(true)
		return
	_travel_in(false)

func _travel_in(hidden: bool) -> void:
	var past := _past_room()
	if past == null or ivo == null or _room == null:
		push_error("Flashback %d: no past room '%s'" % [_visit.number, _visit.past_room])
		_finish()
		return
	_return = TravelPoint.new(_room, ivo.global_position, ivo.facing)
	_stage = Stage.TRAVELLING_IN
	if hidden:
		# The twin room's same pixel, his facing and motion kept: nothing on screen changes.
		var twin := TravelPoint.new(past, past.get_bounds().position + ivo.global_position - _room.get_bounds().position,
				ivo.facing)
		twin.keep_motion = true
		travel_requested.emit(twin, Color.TRANSPARENT, 0.0)
		return
	var feet := past.get_bounds().position + _visit.arrival
	travel_requested.emit(TravelPoint.new(past, feet, _visit.arrival_facing), _visit.entry_colour, _visit.entry_fade)

## Plays `scene` on the current room's contents, so its ids resolve there; false when it cannot play.
func _play(scene: Cutscene) -> bool:
	var host := _room.contents() if _room != null else null
	if cutscenes == null or host == null or not cutscenes.play(scene, host):
		push_error("Flashback %d: '%s' could not play" % [_visit.number, scene.id if scene != null else &""])
		return false
	return true

## The visit's music stops at the cut, and silence holds the SCENE layer over the region's music until the returning
## scene ends (design drafts/camada_pessoal.md §2, "A volta").
func _hush() -> void:
	Music.release(_music, 0.0)
	var silence := MusicCue.new()
	silence.id = SILENCE
	silence.fade_in = 0.0
	silence.fade_out = 0.0
	_music = Music.request(silence, MusicRequest.Layer.SCENE, self)

func _past_room() -> Room:
	for room: Room in get_tree().get_nodes_in_group(Room.GROUP):
		if room.id() == _visit.past_room:
			return room
	return null

func _set_bars(px: float) -> void:
	if letterbox != null:
		letterbox.rest_at(px, 0.0)

func _finish() -> void:
	Music.release(_music)
	_music = null
	_set_bars(0.0)
	_visit = null
	_return = null
	_stage = Stage.IDLE
