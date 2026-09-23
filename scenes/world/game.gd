extends Node2D

## How many rooms (including the current one) stay resident — deactivated
## but not destroyed — at once. Backtracking within this many rooms of the
## current one keeps enemy position/AI/animation state intact; anything
## older gets evicted (see Room.evict()) and comes back fresh next visit.
const MAX_RESIDENT_ROOMS := 2

## Where a region's season is turned into a look: the palette of that
## season's songs.
@export var song_catalog: SongCatalog
## Seconds Ivo is seen sinking before the screen starts to fade: the fall
## gets its own moment instead of vanishing into the dark on contact.
@export var hazard_sink_hold: float = 0.25

@onready var _fade   : Fade   = %Fade
@onready var _camera : GameCamera = %Camera2D
@onready var _player : Player = %Player
@onready var _memory_field : MemoryField = %MemoryField
var _current_room    : Room
var _is_transitioning: bool      = false
## Which fall the running beat belongs to. Control comes back while the screen
## is still clearing, so Ivo can fall in again mid-beat; the newer fall owns
## the screen, and an older beat that wakes up finds it is not the latest and
## stops (Fade.faded resumes it when the newer fade lands).
var _hazard_beat     : int       = 0

## Most-recently-used first. A room only ever leaves this list via eviction
## (_touch_resident below), never just by being left — that's the whole
## point of keeping it "warm" instead of destroying it.
var _resident_rooms: Array[Room] = []

## The regions are reached through the rooms already being walked - a room is
## always a child of its region - so nothing needs a group of its own.
func _ready() -> void:
	_camera.follow(_player)
	_player.fell_into_hazard.connect(_on_player_fell_into_hazard)
	for room: Room in get_tree().get_nodes_in_group(Room.GROUP):
		room.room_entered.connect(_on_player_entered_room)
		var region := room.get_region()
		if not region.memory_changed.is_connected(_on_region_memory_changed):
			region.memory_changed.connect(_on_region_memory_changed.bind(region))

func _on_player_entered_room(room: Room) -> void:
	if room == _current_room or _is_transitioning:
		return
	_is_transitioning = true
	_player.process_mode = Node.PROCESS_MODE_DISABLED
	if _current_room:
		await _fade.to_black()
	_enter_room(room)
	await _fade.to_clear()
	_player.process_mode = Node.PROCESS_MODE_INHERIT
	_is_transitioning = false

## The swap itself, behind whatever fade the caller is holding: the old room
## sleeps, the new one wakes, and the memory field and the camera follow it.
func _enter_room(room: Room) -> void:
	if _current_room:
		_current_room.deactivate()
	_current_room = room
	_current_room.activate()
	# The greyhush is a regional property, so it follows the room the player is
	# standing in rather than being set once at startup.
	var region := _current_room.get_region()
	_memory_field.baseline = region.current_baseline()
	_memory_field.season = region.season
	_memory_field.palette = song_catalog.palette_for(region.season) if song_catalog else null
	_touch_resident(room)
	_camera.set_bounds(_current_room.get_bounds())

## Water took Ivo (design: he does not swim). He sinks while the screen fades,
## comes back on the last firm ground he stood on, and the screen clears.
## A second fall while the screen clears starts a beat of its own.
func _on_player_fell_into_hazard() -> void:
	_hazard_beat += 1
	var beat := _hazard_beat
	await get_tree().create_timer(hazard_sink_hold, false).timeout
	if beat != _hazard_beat:
		return
	await _fade.to_black()
	if beat != _hazard_beat:
		return
	# A hit during the fade can have killed him: a corpse is not put back.
	if not _player.is_dead():
		_player.respawn()
		# Firm ground can be in another room: swap to it here, behind this
		# beat's black, so its own trigger later finds it already current.
		var room := _room_at(_player.global_position)
		if room != null and room != _current_room:
			_enter_room(room)
		_camera.snap()
	await _fade.to_clear()

func _room_at(point: Vector2) -> Room:
	for room: Room in get_tree().get_nodes_in_group(Room.GROUP):
		if room.get_bounds().has_point(point):
			return room
	return null

## Marks `room` as the most recently visited, then evicts whichever
## resident room hasn't been touched in the longest time if that pushes the
## cache past its cap.
func _touch_resident(room: Room) -> void:
	_resident_rooms.erase(room)
	_resident_rooms.push_front(room)
	while _resident_rooms.size() > MAX_RESIDENT_ROOMS:
		_resident_rooms.pop_back().evict()

## The one place MemoryField.baseline is written. A region lifts its own
## memory when its guardian is restored, which can happen while the player is
## standing in it, so the field follows the region it is showing rather than
## only being refreshed at the next doorway.
func _on_region_memory_changed(level: float, region: Region) -> void:
	if _current_room != null and _current_room.get_region() == region:
		_memory_field.baseline = level
