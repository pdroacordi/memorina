class_name RegionMemory extends Node2D

## How much of a region is still remembered, and the wells of forgetting that
## take it away (docs/design/03_mundo_e_ambiente.md sections 4.1 and 4.3).
##
## The wells are this node's own MemorySource children, so they are authored
## in the REGION's scene and not in any one room's contents. That is the whole
## point: MemoryField.sample() skips a source that is not visible in the tree
## and Room.deactivate() hides a room's contents, so a well authored inside a
## room can only ever be felt from inside that room - and a region is very
## often more than one room. Death marks hang here too, for the same reason,
## under their own DeathMarks node: they are not wells, and a restoration that
## fills the wells back in never touches them - only erase_marks() does.
##
## It never reads SaveSystem. Whether this region's guardian has been restored
## is the Region's judgement, pushed in through restore().

## The level changed - every frame of a lift, so whoever is showing this
## region can follow it without polling.
signal changed(level: float)

## What the region remembers before its guardian is restored. A value, not a
## switch: the home village opens at 0.8 (alive, but already thinning).
@export_range(0.0, 1.0) var authored: float = 0.8
## Seconds the wells take to fill in and the level to climb to 1.0 once the
## guardian is restored - the first act of the lesson.
@export var lift_time: float = 6.0
## How the player's deaths here become marks.
@export var death_mark_stats: DeathMarkStats = preload("res://resources/memory/death_mark_stats.tres")

var _level: float = 1.0
var _wells: Array[MemorySource] = []
var _tween: Tween
var _marks: Node2D
var _marks_tween: Tween


func _ready() -> void:
	_level = authored
	for child: Node in get_children():
		if child is MemorySource:
			_wells.append(child as MemorySource)
	_marks = Node2D.new()
	_marks.name = "DeathMarks"
	add_child(_marks)

## The region's memory as it stands right now.
func current() -> float:
	return _level

## The place remembers with its guardian: the wells fill back in and the level
## climbs to 1.0, both across `seconds`. At or below 0 it is simply already
## whole - a later visit, loaded that way rather than lifted.
##
## The tween ignores the pause because the lesson freezes TIME, not MEMORY:
## this lift is the first thing that happens while the track plays.
func restore(seconds: float) -> void:
	if _tween != null:
		_tween.kill()
	if seconds <= 0.0:
		_set_level(1.0)
		for well: MemorySource in _wells:
			well.strength = 0.0
			well.hide()
		return
	_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel(true)
	_tween.tween_method(_set_level, _level, 1.0, seconds)
	for well: MemorySource in _wells:
		_tween.tween_property(well, "strength", 0.0, seconds)
	_tween.chain().tween_callback(_hide_wells)

## Mounts one mark per cluster of the deaths the save holds for this region,
## replacing whatever marks were there. `points` are local to the REGION (this
## node's parent), as the composition root recorded them.
func mark_deaths(points: PackedVector2Array) -> void:
	_clear_marks()
	if death_mark_stats == null:
		return
	var stats := death_mark_stats
	for cluster: Dictionary in DeathMarkClusters.cluster(points, stats.merge_distance, stats.max_marks):
		var deaths: int = cluster["deaths"]
		var mark := MemorySource.new()
		mark.shape = MemoryFieldMath.Shape.CIRCLE
		mark.radius = stats.radius_for(deaths)
		mark.feather = stats.feather
		mark.strength = -stats.strength_for(deaths)
		mark.show_in_editor = false
		_marks.add_child(mark)
		mark.global_position = get_parent().to_global(cluster["centre"])

## The marks here, as they stand.
func marks() -> Array[MemorySource]:
	var result: Array[MemorySource] = []
	for child: Node in _marks.get_children():
		result.append(child as MemorySource)
	return result

## The guardian is restored and the place forgets the player's deaths in it
## (the user's decision, 2026-10-01): the marks thin out across `seconds`,
## alongside the lift. At or below 0 they are simply gone.
func erase_marks(seconds: float) -> void:
	if _marks_tween != null:
		_marks_tween.kill()
	if seconds <= 0.0 or _marks.get_child_count() == 0:
		_clear_marks()
		return
	_marks_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel(true)
	for mark: MemorySource in marks():
		_marks_tween.tween_property(mark, "strength", 0.0, seconds)
	_marks_tween.chain().tween_callback(_clear_marks)

# remove_child before freeing: a source unregisters from the field on leaving
# the tree, and a mark left registered until the frame ends would still be drawn.
func _clear_marks() -> void:
	for mark: Node in _marks.get_children():
		_marks.remove_child(mark)
		mark.queue_free()

# tween_method rather than tween_property so the change is announced as it
# happens; a property tween would leave every listener polling for it.
func _set_level(level: float) -> void:
	_level = level
	changed.emit(_level)

func _hide_wells() -> void:
	for well: MemorySource in _wells:
		well.hide()
