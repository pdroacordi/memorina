class_name SaveLedger extends RefCounted

## Tracks live and bench-committed save data (docs/knowledge/architecture/the-life-loop-rewinds-by-reloading.md); `SaveSystem` handles disk access.

var live: PlayerData
var committed: PlayerData
## Enemies defeated since the last rest or death, keyed by `save_id`; transient and not saved.
var defeated: Dictionary[String, bool] = {}


func _init(start: PlayerData) -> void:
	committed = start
	live = copy(start)

## Deep-copies data so live flag arrays cannot mutate the committed save.
static func copy(data: PlayerData) -> PlayerData:
	return data.duplicate_deep(Resource.DEEP_DUPLICATE_ALL) as PlayerData

## Commits live data and clears transient defeated enemies. `elapsed` is the play time since the last commit, in seconds.
func commit(elapsed: float = 0.0) -> PlayerData:
	live.play_time += elapsed
	committed = copy(live)
	defeated.clear()
	return committed

## Restores committed data and clears transient defeated enemies. The play time `elapsed` since the last commit is kept.
func rewind(elapsed: float = 0.0) -> void:
	committed.play_time += elapsed
	live = copy(committed)
	defeated.clear()

## Records a region-local death point and the play time `elapsed` before rewinding (design 03, section 4.3).
func record_death(region_key: String, point: Vector2, elapsed: float = 0.0) -> PlayerData:
	var points: PackedVector2Array = committed.deaths.get(region_key, PackedVector2Array())
	points.append(point)
	committed.deaths[region_key] = points
	rewind(elapsed)
	return committed
