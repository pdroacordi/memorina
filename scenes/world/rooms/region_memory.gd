class_name RegionMemory extends Node2D

## How much of a region is still remembered, and the wells of forgetting that
## take it away (docs/design/03_mundo_e_ambiente.md sections 4.1 and 4.3).
##
## The wells are this node's own MemorySource children, so they are authored
## in the REGION's scene and not in any one room's contents. That is the whole
## point: MemoryField.sample() skips a source that is not visible in the tree
## and Room.deactivate() hides a room's contents, so a well authored inside a
## room can only ever be felt from inside that room - and a region is very
## often more than one room. Death marks will hang here too.
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

var _level: float = 1.0
var _wells: Array[MemorySource] = []
var _tween: Tween


func _ready() -> void:
	_level = authored
	for child: Node in get_children():
		if child is MemorySource:
			_wells.append(child as MemorySource)

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

# tween_method rather than tween_property so the change is announced as it
# happens; a property tween would leave every listener polling for it.
func _set_level(level: float) -> void:
	_level = level
	changed.emit(_level)

func _hide_wells() -> void:
	for well: MemorySource in _wells:
		well.hide()
