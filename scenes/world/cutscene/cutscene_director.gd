class_name CutsceneDirector
extends Node
## Plays one Cutscene at a time on the pausable, scaled physics clock, and at its end records SCENE_SEEN before every
## actor's place goes back to its staging in the same frame (systems/cutscenes).

signal scene_began(scene: Cutscene)
signal scene_ended(scene: Cutscene)
## Ivo walks by `controller` until it is null again.
signal ivo_driven(controller: ScriptedController)
## What Ivo holds (DialogueBeat.Pose).
signal ivo_posed(pose: DialogueBeat.Pose)

const GROUP := &"cutscene_directors"
## Leaves begun in one tick at most: a scene of instant steps cannot hang the frame.
const MAX_BEGUN_PER_TICK := 256

@export var catalog: CutsceneCatalog
@export var ivo: Player
@export var camera: GameCamera
@export var letterbox: Letterbox
@export var fade: Fade
@export var dialogue: DialogueDirector
## Scaled seconds the bars take to close at a scene's end.
@export var letterbox_close_seconds: float = 0.4

var _scene: Cutscene
## The beat or trigger that asked for the scene; its contents scene scopes the ids.
var _host: Node
var _runner: CutsceneRunner
var _context: WorldCutsceneContext
## Leaf id -> its running task.
var _tasks: Dictionary[int, CutsceneTask] = {}
var _skip_requested: bool = false
## The frame easing back to Ivo after a scene: seconds left of WorldCutsceneContext.RETURN_SECONDS; 0 when none.
var _return_left: float = 0.0
var _return_from: Vector2
## The trigger armed in the current room, and scaled seconds left of its delay.
var _armed: CutsceneTrigger
var _armed_left: float = 0.0
## The side the playing (or last) scene turned or walked Ivo to; 0 when it did not.
var _ivo_turned: int = 0

@onready var _rig: CameraRig = _make_rig()
@onready var _ivo_controller: ScriptedController = _make_controller()


## The director of the world `tree` runs; null when none is loaded.
static func find(tree: SceneTree) -> CutsceneDirector:
	return tree.get_first_node_in_group(GROUP) as CutsceneDirector

func _enter_tree() -> void:
	add_to_group(GROUP)

func _ready() -> void:
	if OS.is_debug_build() and catalog != null:
		var problems := catalog.validate()
		assert(problems.is_empty(), "Cutscene catalog: %s" % "; ".join(problems))

## Out of the tree (a death's SceneSwap, a quit): the world goes with it, so nothing is written or restored.
func _exit_tree() -> void:
	_scene = null
	_runner = null
	_context = null
	_tasks.clear()

func _physics_process(delta: float) -> void:
	_tick_return(delta)
	if _scene == null:
		_tick_trigger(delta)
		return
	if _skip_requested:
		_skip_requested = false
		_skip()
		if _scene == null:
			return
	for id: int in _tasks.keys():
		if _tasks[id].tick(delta):
			_tasks.erase(id)
			_runner.done(id)
	_advance()
	if _runner.is_finished() and _tasks.is_empty():
		_end(true)

## Starts `scene` for `host` (a CutsceneBeat or CutsceneTrigger, whose contents scope its ids); false when a scene
## already plays, so no scene runs inside a talk inside a scene.
func play(scene: Cutscene, host: Node) -> bool:
	if _scene != null or scene == null or host == null or ivo == null:
		return false
	_scene = scene
	_host = host
	_runner = CutsceneRunner.new(scene, SaveSystem.player_data)
	_context = WorldCutsceneContext.new(self, _scope_of(host), _rig, _ivo_controller)
	_tasks.clear()
	_skip_requested = false
	_ivo_turned = 0
	scene_began.emit(scene)
	_advance()
	return true

func is_playing() -> bool:
	return _scene != null

func playing() -> Cutscene:
	return _scene

## Whether the pause menu offers "Skip scene": a skippable scene plays and no talk of it has the box.
func can_skip() -> bool:
	if _scene == null or not _scene.skippable:
		return false
	for id: int in _tasks:
		if _runner.step(id) is CutsceneTalk:
			return false
	return true

## The pause menu's "Skip scene": the scene lands on its next unpaused tick.
func request_skip() -> void:
	if can_skip():
		_skip_requested = true

## A hurt, a hazard or Ivo's room changing drops the scene unrecorded: the rest shown before it, a stand-in included, shows
## again.
func interrupt() -> void:
	if _scene != null:
		_end(false)

## Connected to `Game.room_changed`: a scene whose contents are not the room's is dropped, and the room's first trigger
## whose gates hold is armed. Read from the room's contents, not the tree: contents made on this visit are added deferred
## (bugs/a-cutscene-trigger-in-a-first-visited-room-never-arms).
func on_room_changed(room: Room) -> void:
	if _scene != null and not _in_room(_host, room):
		_end(false)
	_armed = null
	var contents := room.contents() if room != null else null
	if contents == null:
		return
	for trigger: CutsceneTrigger in _triggers_under(contents):
		if trigger.wants(SaveSystem.player_data):
			_armed = trigger
			_armed_left = trigger.delay
			return

## The side the last scene left Ivo facing, if it turned or walked him; 0 otherwise.
func ivo_turned() -> int:
	return _ivo_turned

## Called by the context when a step turns or walks Ivo.
func note_ivo_turned() -> void:
	if ivo != null:
		_ivo_turned = ivo.facing

## A new scene takes the frame from the rig's way back to Ivo.
func stop_return() -> void:
	_return_left = 0.0

func _advance() -> void:
	var begun := 0
	while begun < MAX_BEGUN_PER_TICK:
		var ids := _runner.next()
		if ids.is_empty():
			return
		for id: int in ids:
			begun += 1
			var task := _runner.step(id).begin(_context)
			if task.tick(0.0):
				_runner.done(id)
			else:
				_tasks[id] = task

func _skip() -> void:
	for task: CutsceneTask in _tasks.values():
		task.stop()
	_tasks.clear()
	for step: CutsceneStep in _runner.to_land():
		step.land(_context)
	_advance()
	if _runner.is_finished() and _tasks.is_empty():
		_end(true, true)

## The scene is over (`record`) or dropped: SCENE_SEEN first, so the stagings re-pick their new rest before they are
## uncovered in the same frame. A skip's end cuts the frame and the bars back at once (`cut`): the skip is a cut already.
func _end(record: bool, cut: bool = false) -> void:
	var scene := _scene
	for task: CutsceneTask in _tasks.values():
		task.stop()
	_tasks.clear()
	if record:
		SaveSystem.mark_scene_seen(scene.id)
	_context.restore(not record, cut)
	if _context.took_camera() and camera != null:
		if cut:
			camera.zoom_to(camera.rest_zoom(), 0.0)
			camera.follow(ivo)
			camera.snap()
		else:
			_return_from = _rig.global_position
			_return_left = WorldCutsceneContext.RETURN_SECONDS
			camera.zoom_to(camera.rest_zoom(), WorldCutsceneContext.RETURN_SECONDS)
	_scene = null
	_host = null
	_runner = null
	_context = null
	_skip_requested = false
	scene_ended.emit(scene)

## Eases the rig back to Ivo's framed centre, then the camera follows him again with no jump.
func _tick_return(delta: float) -> void:
	if _return_left <= 0.0 or camera == null or ivo == null:
		return
	_return_left = maxf(_return_left - delta, 0.0)
	var weight := 1.0 - _return_left / WorldCutsceneContext.RETURN_SECONDS
	var to := camera.rig_point_for(camera.centre_for(ivo))
	_rig.move_to(_return_from.lerp(to, ease(weight, -2.0)), 0.0)
	if _return_left <= 0.0:
		camera.follow(ivo)

func _tick_trigger(delta: float) -> void:
	if _armed == null:
		return
	if not is_instance_valid(_armed) or not _armed.wants(SaveSystem.player_data):
		_armed = null
		return
	# Its contents may still wait for their deferred add; the delay counts from when it is in the world.
	if not _armed.is_inside_tree():
		return
	_armed_left = maxf(_armed_left - delta, 0.0)
	if _armed_left > 0.0 or ivo == null or not (_armed.from_black or ivo.can_begin_scene()):
		return
	var trigger := _armed
	_armed = null
	play(trigger.cutscene, trigger)

## Every trigger under `node`, in tree order, whether or not it is inside the tree yet.
func _triggers_under(node: Node) -> Array[CutsceneTrigger]:
	var found: Array[CutsceneTrigger] = []
	if node is CutsceneTrigger:
		found.append(node as CutsceneTrigger)
	for child: Node in node.get_children():
		found.append_array(_triggers_under(child))
	return found

## The contents scene a host belongs to: ids resolve under it.
func _scope_of(host: Node) -> Node:
	return host.owner if host.owner != null else host

func _in_room(node: Node, room: Room) -> bool:
	if not is_instance_valid(node) or room == null:
		return false
	var contents := room.contents()
	return contents != null and (contents == node or contents.is_ancestor_of(node))

func _make_rig() -> CameraRig:
	var made := CameraRig.new()
	made.name = &"CameraRig"
	add_child(made)
	return made

func _make_controller() -> ScriptedController:
	var made := ScriptedController.new()
	made.name = &"IvoController"
	add_child(made)
	return made
