class_name Region extends Node2D

## Composes a region's rooms, season, guardian state, and memory (design 03 section 4.1).

## Re-emitted when RegionMemory changes.
signal memory_changed(level: float)

## Translation key of the region's name; a rest saves it for the title.
@export var name_key: String = ""
## Translation key of the line under the name in the first-visit title (systems/region-title).
@export var epithet_key: String = ""
## Whether the first entry plays the region title; false on test beds.
@export var shows_title: bool = true
## Native season (design 03 section 4.2).
@export var season: Enums.Season = Enums.Season.SPRING
## Guardian that keeps this region; restoring it sets memory to 1.0.
@export var has_guardian: bool = false
@export var guardian: Enums.Guardian = Enums.Guardian.FROST
## The backdrop every room shows unless its Backdrop overrides it (systems/backdrops).
@export var backdrop_set: BackdropSet
## The region's one horizon, px below this node: where each backdrop layer's horizon row stands at the reference camera.
@export var horizon_y: float = 0.0
## Ivo cannot swing the sword in this region's interiors (STORY-14: the village's houses).
@export var calm_interiors: bool = false
## The region's theme, stems `base` and `memory`; null is silence (music/region-themes).
@export var music: MusicCue
## The weather that pushes Ivo in this region's open rooms; null blows nothing (architecture/regional-weather-push).
@export var weather: WeatherProfile
## The one way the region's weather blows.
@export_enum("West:-1", "East:1") var weather_wind: int = 1

@onready var _memory: RegionMemory = $Memory


## Reads guardian restoration from SaveSystem, independent of room residency.
func _ready() -> void:
	_memory.changed.connect(memory_changed.emit)
	# Mount marks even when restored; only newer deaths remain in the save.
	_memory.mark_deaths(SaveSystem.deaths_in(SceneKey.of(self)))
	_memory.follow_restorations(SaveSystem.restored_guardian_count())
	var own_unrestored: bool = has_guardian and not SaveSystem.is_guardian_restored(guardian)
	if (has_guardian and not own_unrestored) or SaveSystem.is_world_restored():
		_memory.restore(0.0)
	if own_unrestored or not _memory.steps.is_empty():
		SaveSystem.guardian_restored.connect(_on_guardian_restored)
	# The final battle restores every region, its own guardian or not (GRD-06).
	if not SaveSystem.is_world_restored():
		SaveSystem.world_restored.connect(_on_world_restored)

## Current baseline memory value.
func current_baseline() -> float:
	return _memory.current()

func _on_guardian_restored(restored: Enums.Guardian) -> void:
	if has_guardian and restored == guardian:
		_memory.restore(_memory.lift_time)
		# Death marks follow the live save and return on death before the next bench.
		SaveSystem.clear_deaths(SceneKey.of(self))
		_memory.erase_marks(_memory.lift_time)
	_memory.follow_restorations(SaveSystem.restored_guardian_count())

func _on_world_restored() -> void:
	_memory.restore(_memory.lift_time)
	SaveSystem.clear_deaths(SceneKey.of(self))
	_memory.erase_marks(_memory.lift_time)
