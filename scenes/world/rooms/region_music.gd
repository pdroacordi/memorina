class_name RegionMusic
extends Node
## Asks Music for the region Ivo is in and lifts its memory stem with the region's memory (music/region-themes).

const MEMORY_STEM := &"memory"
## Real seconds the memory stem takes to follow a change of the region's memory.
const MEMORY_FOLLOW := 4.0

var _region: Region
var _request: MusicRequest


## The memory stem's level, 0..1, for a region memory of `memory` (0..1); squared so a grey region stays near silent.
static func memory_level(memory: float) -> float:
	return clampf(memory, 0.0, 1.0) ** 2

## Connected to `Game.room_changed`.
func on_room_changed(room: Room) -> void:
	var region := room.get_region()
	if region == _region:
		return
	if _region != null and is_instance_valid(_region):
		_region.memory_changed.disconnect(_on_memory_changed)
	Music.release(_request)
	_request = null
	_region = region
	_region.memory_changed.connect(_on_memory_changed)
	if region.music == null:
		return
	_request = Music.request(region.music, MusicRequest.Layer.REGION, region)
	Music.set_stem(_request, MEMORY_STEM, memory_level(region.current_baseline()), 0.0)

func _on_memory_changed(level: float) -> void:
	Music.set_stem(_request, MEMORY_STEM, memory_level(level), MEMORY_FOLLOW)
