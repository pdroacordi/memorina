class_name Region extends Node2D

## Composes a region's rooms, season, guardian state, and memory (design 03 section 4.1).

## Re-emitted when RegionMemory changes.
signal memory_changed(level: float)

## Native season (design 03 section 4.2).
@export var season: Enums.Season = Enums.Season.SPRING
## Guardian that keeps this region; restoring it sets memory to 1.0.
@export var has_guardian: bool = false
@export var guardian: Enums.Guardian = Enums.Guardian.FROST

@onready var _memory: RegionMemory = $Memory


## Reads guardian restoration from SaveSystem, independent of room residency.
func _ready() -> void:
	_memory.changed.connect(memory_changed.emit)
	# Mount marks even when restored; only newer deaths remain in the save.
	_memory.mark_deaths(SaveSystem.deaths_in(SceneKey.of(self)))
	if not has_guardian:
		return
	if SaveSystem.is_guardian_restored(guardian):
		_memory.restore(0.0)
		return
	SaveSystem.guardian_restored.connect(_on_guardian_restored)

## Current baseline memory value.
func current_baseline() -> float:
	return _memory.current()

func _on_guardian_restored(restored: Enums.Guardian) -> void:
	if restored != guardian:
		return
	_memory.restore(_memory.lift_time)
	# Death marks follow the live save and return on death before the next bench.
	SaveSystem.clear_deaths(SceneKey.of(self))
	_memory.erase_marks(_memory.lift_time)
