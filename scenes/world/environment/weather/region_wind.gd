class_name RegionWind extends AirflowSource

## The current region's weather push: one gust clock run at the memory at Ivo, blowing along x in the region's open-sky
## rooms (design 03 sections 5.3-5.5; architecture/regional-weather-push).

const GROUP := &"region_wind"

## Whose memory and fight the clock follows.
@export var subject: Player

var _region: Region
var _gust: WeatherGust
var _direction: int = 1
## The current region's open-sky room bounds, with the sky band over each top no room covers.
var _open: Array[Rect2] = []
var _had_sky: bool = false
var _shelters: Array[WeatherShelter] = []
var _memory: MemoryField


static func find_in(node: Node) -> RegionWind:
	return node.get_tree().get_first_node_in_group(GROUP) as RegionWind

func _enter_tree() -> void:
	add_to_group(GROUP)

func _ready() -> void:
	super()
	_memory = MemoryField.find_in(self)

# Priority -2 in region_wind.tscn: steps before AirflowBody (-1) samples it.
func _physics_process(delta: float) -> void:
	if _gust == null or subject == null:
		return
	var memory := _memory.sample(subject.global_position) if _memory != null else 1.0
	_gust.step(delta, memory, Guardian.fight_at(get_tree(), subject.global_position))

## Connected from `Game.room_changed`: a calm starts on walking out under the sky or into another region.
func on_room_changed(room: Room) -> void:
	var region := room.get_region()
	var new_region := region != _region
	if new_region:
		_region = region
		_direction = region.weather_wind
		_gust = WeatherGust.new(region.weather) if region.weather != null else null
		_open = _open_rects(region)
	if _gust != null and room.has_sky() and (new_region or not _had_sky):
		_gust.restart()
	_had_sky = room.has_sky()

## Connected from `Game.hazard_respawned`: a respawn starts in a calm, never back in the gust that dropped him
## (bugs/a-hazard-respawn-puts-ivo-back-into-the-gust-that-dropped-him).
func on_hazard_respawned() -> void:
	if _gust != null:
		_gust.restart()

## The current region's weather; null when it has none.
func profile() -> WeatherProfile:
	return _gust.profile if _gust != null else null

## Signed gust strength with the player's intensity, -1..1: what the snow shows.
func drive() -> float:
	if _gust == null:
		return 0.0
	return signf(_direction) * _gust.strength() * Settings.weather_intensity()

func wind_at(global_point: Vector2) -> Vector2:
	if _gust == null or not _in_open(global_point) or is_sheltered(global_point):
		return Vector2.ZERO
	return Vector2(_gust.air(_direction, Settings.weather_intensity()), 0.0)

func is_sheltered(global_point: Vector2) -> bool:
	for shelter: WeatherShelter in _shelters:
		if shelter.is_visible_in_tree() and shelter.covers(global_point):
			return true
	return false

func register_shelter(shelter: WeatherShelter) -> void:
	if not _shelters.has(shelter):
		_shelters.append(shelter)

func unregister_shelter(shelter: WeatherShelter) -> void:
	_shelters.erase(shelter)

func _in_open(global_point: Vector2) -> bool:
	for rect: Rect2 in _open:
		if rect.has_point(global_point):
			return true
	return false

## `region`'s open-sky room bounds and the sky bands over their tops, as WorldEdges walls them (systems/rooms "Edges").
func _open_rects(region: Region) -> Array[Rect2]:
	var open: Array[Rect2] = []
	var rooms: Array[Rect2] = []
	var closed: Array[PackedByteArray] = []
	for node: Node in get_tree().get_nodes_in_group(Room.GROUP):
		var room := node as Room
		var bounds := room.get_bounds()
		var mine := room.get_parent() == region and room.has_sky()
		var map := room.map() if mine else null
		rooms.append(bounds)
		# An empty top is closed, so only this region's open rooms get bands.
		closed.append(RoomEdges.closed_top(map) if map != null else PackedByteArray())
		if mine:
			open.append(bounds)
	open.append_array(RoomEdges.bands(rooms, closed))
	return open
