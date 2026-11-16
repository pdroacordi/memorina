class_name EpilogueDirector
extends Node
## Orders the ending: the epilogue, then the credits on the same host, then a rest on the bench the credits open
## (architecture/story-07-epilogue, "The ending's order"). It writes nothing; the rest is Game's.

## The epilogue began: the ending runs until `ending_ended`.
signal ending_began
signal ending_ended
## The credits were recorded: Game seats Ivo on bench `bench_id` and rests there.
signal rest_requested(bench_id: StringName)

## Scaled seconds the black the credits end on clears over, once the rest has landed under it.
const CLEAR_SECONDS := 1.5

@export var epilogue: Cutscene
@export var credits: Cutscene
@export var bench_id: StringName = EpilogueSchedule.BENCH_ID
@export var cutscenes: CutsceneDirector
## The cover the credits end on; cleared after the rest, because a recorded end never clears a fade.
@export var fade: Fade

## The node the epilogue was played for; the credits play on it too.
var _host: Node
var _in_ending: bool = false


func _ready() -> void:
	assert(epilogue == null or epilogue.id == EpilogueSchedule.EPILOGUE_ID, "%s: the epilogue is not '%s'" % [name, EpilogueSchedule.EPILOGUE_ID])
	assert(credits == null or credits.id == EpilogueSchedule.CREDITS_ID, "%s: the credits are not '%s'" % [name, EpilogueSchedule.CREDITS_ID])
	if cutscenes != null:
		cutscenes.scene_began.connect(_on_scene_began)
		cutscenes.scene_ended.connect(_on_scene_ended)

## Out of the tree (a death's SceneSwap, a quit): the ending is forgotten and nothing is written, so it stays due.
func _exit_tree() -> void:
	_host = null
	_in_ending = false

func is_in_ending() -> bool:
	return _in_ending

func _on_scene_began(scene: Cutscene) -> void:
	if not _is(scene, epilogue) and not _is(scene, credits):
		return
	_host = cutscenes.host()
	if not _in_ending:
		_in_ending = true
		ending_began.emit()

func _on_scene_ended(scene: Cutscene) -> void:
	if _is(scene, epilogue):
		# A skip is recorded too, so a skipped epilogue still rolls the credits; a drop leaves it due.
		if cutscenes.ended_recorded() and credits != null:
			_play_credits.call_deferred()
		else:
			_close()
	elif _is(scene, credits):
		if cutscenes.ended_recorded():
			rest_requested.emit(bench_id)
			if fade != null and fade.is_black():
				fade.to_clear(CLEAR_SECONDS)
		_close()

## Deferred: every scene_ended listener (Player.end_scene first) sees the epilogue end before the credits begin.
func _play_credits() -> void:
	if not is_inside_tree():
		return
	if is_instance_valid(_host) and _host.is_inside_tree() and cutscenes.play(credits, _host):
		return
	_close()

func _close() -> void:
	_host = null
	if _in_ending:
		_in_ending = false
		ending_ended.emit()

func _is(scene: Cutscene, wanted: Cutscene) -> bool:
	return scene != null and wanted != null and scene.id == wanted.id
