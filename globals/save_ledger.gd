class_name SaveLedger extends RefCounted

## What the save carries between benches (docs/knowledge/architecture/
## the-life-loop-rewinds-by-reloading.md). Two copies: `live`, which the world
## reads and writes as it is played, and `committed`, the save as the last
## bench left it. Only benches save, and death rewinds to the last of them, so
## the two differ by exactly what dying would cost.
##
## Pure: it never touches the disk. SaveSystem writes whatever commit() and
## record_death() hand back.

var live: PlayerData
var committed: PlayerData
## Enemies defeated since the last rest or death, by save_id. Never on disk:
## resting brings them back, and so does dying, since a death returns the world
## to the bench where they had just come back.
var defeated: Dictionary[String, bool] = {}


func _init(start: PlayerData) -> void:
	committed = start
	live = copy(start)

## A deep copy. A shallow duplicate() would SHARE the flag arrays, and a song
## learned after a bench would leak into the save the bench left.
static func copy(data: PlayerData) -> PlayerData:
	return data.duplicate_deep(Resource.DEEP_DUPLICATE_ALL) as PlayerData

## A rest: the world as it stands becomes the save, and the defeated return.
func commit() -> PlayerData:
	committed = copy(live)
	defeated.clear()
	return committed

## A death: the world goes back to the last bench.
func rewind() -> void:
	live = copy(committed)
	defeated.clear()

## A death leaves its mark ON the bench's save, then rewinds to it: the death
## undoes everything since the bench except the death itself (design 03,
## section 4.3). `point` is local to the region.
func record_death(region_key: String, point: Vector2) -> PlayerData:
	var points: PackedVector2Array = committed.deaths.get(region_key, PackedVector2Array())
	points.append(point)
	committed.deaths[region_key] = points
	rewind()
	return committed
