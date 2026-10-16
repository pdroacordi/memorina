class_name FactStaging
extends Node2D
## Shows exactly one of its children, picked by the first FactStage that holds under the save (systems/story). It is the
## only writer of its children's visibility; never put RegionPresence on a direct child.

## In priority order: the first that holds is shown.
@export var stages: Array[FactStage] = []

## The stage shown; -1 when none holds.
var _picked: int = -1
## The child the stage shows, or a stand-in; null shows nothing.
var _shown: CanvasItem
var _stand_in: CanvasItem
var _fade: Tween
var _fade_from: CanvasItem
## A cutscene's actor stands for this staging (systems/cutscenes).
var _covered: bool = false


## The index of the first stage that holds under `data`; -1 when none does.
static func pick(from: Array[FactStage], data: PlayerData) -> int:
	for i: int in from.size():
		if from[i] != null and from[i].holds(data):
			return i
	return -1

func _ready() -> void:
	SaveSystem.progress_changed.connect(_on_progress_changed)
	_go_to(pick(stages, SaveSystem.player_data), true)

## The stage shown now; -1 when none holds.
func picked() -> int:
	return _picked

## The child shown now (a stand-in included); null when none is.
func shown() -> CanvasItem:
	return _shown

## A beat shows `child` at once, until the picked stage next changes or `release(child)`.
func stand_in(child: StringName) -> void:
	_stand_in = get_node_or_null(NodePath(child)) as CanvasItem
	assert(_stand_in != null, "%s has no child '%s' to stand in" % [name, child])
	_show(_stand_in, 0.0)

## Returns to the picked stage if `child` is still the stand-in; a later beat's stand-in stays.
func release(child: StringName) -> void:
	if _stand_in == null or _stand_in.name != child:
		return
	_stand_in = null
	_show(_child_of(_picked), 0.0)

## A cutscene's actor takes the shown child's place: nothing shows, and the pick follows the save silently until `uncover()`.
func cover() -> void:
	_covered = true
	_snap_fade()
	visible = false

## The actor left: the pick (or a live stand-in) shows at once, with no fade.
func uncover() -> void:
	_covered = false
	_snap_fade()
	visible = true

func is_covered() -> bool:
	return _covered

func _on_progress_changed() -> void:
	var now := pick(stages, SaveSystem.player_data)
	if now != _picked:
		_go_to(now, false)

func _go_to(index: int, instant: bool) -> void:
	_picked = index
	_stand_in = null
	var seconds := 0.0 if instant or index < 0 else stages[index].fade_seconds
	_show(_child_of(index), seconds)

func _child_of(index: int) -> CanvasItem:
	if index < 0 or stages[index].show == &"":
		return null
	var child := get_node_or_null(NodePath(stages[index].show)) as CanvasItem
	assert(child != null, "%s: stage %d shows '%s', no such child" % [name, index, stages[index].show])
	return child

## Cuts to `target`, or cross-fades from what is shown over `seconds` on a scaled tween bound to this node (pausable).
func _show(target: CanvasItem, seconds: float) -> void:
	_snap_fade()
	var from := _shown
	_shown = target
	for node: Node in get_children():
		var child := node as CanvasItem
		if child != null and child != target and (child != from or seconds <= 0.0):
			child.visible = false
			child.modulate.a = 1.0
	if target == null and (from == null or seconds <= 0.0):
		return
	if target != null:
		target.visible = true
		target.modulate.a = 1.0
	if seconds <= 0.0 or from == target:
		return
	_fade_from = from
	_fade = create_tween().set_parallel(true)
	if target != null:
		target.modulate.a = 0.0
		_fade.tween_property(target, "modulate:a", 1.0, seconds)
	if from != null:
		_fade.tween_property(from, "modulate:a", 0.0, seconds)
	_fade.finished.connect(_snap_fade)

## Ends a running cross-fade at its end state; a killed tween never emits finished (gotchas/a-killed-tween-never-emits-finished).
func _snap_fade() -> void:
	if _fade != null:
		_fade.kill()
		_fade = null
	if _fade_from != null and _fade_from != _shown:
		_fade_from.visible = false
		_fade_from.modulate.a = 1.0
	_fade_from = null
	if _shown != null:
		_shown.modulate.a = 1.0
