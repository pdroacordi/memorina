class_name Region extends Node2D

## The composition scene that places a region's rooms. Owns what belongs to
## the region rather than to any single room: which season its art is drawn
## in, whether a guardian keeps it - and, through its RegionMemory child, how
## much of it is still remembered.
##
## A value, not a switch, deliberately - see
## docs/design/03_mundo_e_ambiente.md section 4.1. The home village opens at
## 0.8 (alive, but already thinning), is revisited lower, and returns to 1.0.

## The region's memory moved. Re-emitted from RegionMemory so that whoever
## shows a region listens to the region, not to its parts.
signal memory_changed(level: float)

## The region's native season (docs/design/03_mundo_e_ambiente.md section
## 4.2). Every seasonal sheet in its rooms shows this season's band unless a
## pulse paints another over it.
@export var season: Enums.Season = Enums.Season.SPRING
## Whether a guardian keeps this region, and which. Restoring it lifts the
## region's memory to 1.0 for good (section 4.1, "estacao de repouso
## permanente"); the flag exists because an enum has no "none".
@export var has_guardian: bool = false
@export var guardian: Enums.Guardian = Enums.Guardian.FROST

@onready var _memory: RegionMemory = $Memory


## The guardian is heard from SaveSystem rather than from the Guardian itself:
## it is the one thing that knows, whatever order the world loaded in and
## whether or not the arena's room is still resident.
func _ready() -> void:
	_memory.changed.connect(memory_changed.emit)
	if not has_guardian:
		return
	if SaveSystem.is_guardian_restored(guardian):
		_memory.restore(0.0)
		return
	SaveSystem.guardian_restored.connect(_on_guardian_restored)

## The baseline as it stands now: the authored value until the region's
## guardian has been restored, then full memory.
func current_baseline() -> float:
	return _memory.current()

func _on_guardian_restored(restored: Enums.Guardian) -> void:
	if restored != guardian:
		return
	_memory.restore(_memory.lift_time)
