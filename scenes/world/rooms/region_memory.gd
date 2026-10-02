class_name RegionMemory extends Node2D

## Region memory and forgetting wells (design 03 sections 4.1 and 4.3); the Region supplies restoration state.

## Emitted whenever the memory level changes.
signal changed(level: float)

## Initial memory level, 0..1.
@export_range(0.0, 1.0) var authored: float = 0.8
## Restoration duration, in seconds.
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

## Restores memory over `seconds`; see design 03 section 4.1.
func restore(seconds: float) -> void:
	if _tween != null:
		_tween.kill()
	if seconds <= 0.0:
		_set_level(1.0)
		for well: MemorySource in _wells:
			well.strength = 0.0
			well.hide()
		return
	# Memory restoration continues while the lesson pauses the world.
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

# Remove before freeing so the source unregisters before the frame ends.
func _clear_marks() -> void:
	for mark: Node in _marks.get_children():
		_marks.remove_child(mark)
		mark.queue_free()

# tween_method emits level changes while the tween runs.
func _set_level(level: float) -> void:
	_level = level
	changed.emit(_level)

func _hide_wells() -> void:
	for well: MemorySource in _wells:
		well.hide()
