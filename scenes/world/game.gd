extends Node2D

## The camera frames a new current room; the map reveals it from here. Emitted after an arrival's seat and snap.
signal room_changed(room: Room)

## Palette lookup by region season.
@export var song_catalog: SongCatalog
## Seconds Ivo sinks before the hazard fade starts.
@export var hazard_sink_hold: float = 0.25
## Seconds the body remains still after its death clip.
@export var death_hold: float = 0.6
## Seconds the memory baseline takes to reach the new region's after a walk across a region seam.
@export var baseline_glide_time: float = 0.45
## Loaded at swap time: the title exports this scene, so a PackedScene export would be a cycle.
@export_file("*.tscn") var title_scene: String = ""

@onready var _fade   : Fade   = %Fade
@onready var _camera : GameCamera = %Camera2D
@onready var _player : Player = %Player
@onready var _memory_field : MemoryField = %MemoryField
@onready var _screens : Screens = $ScreenLayer/Screens
@onready var _notebook_watcher : NotebookWatcher = $World/NotebookWatcher
var _current_room    : Room
var _is_transitioning: bool      = false
## Identifies the latest hazard beat so an older overlapping beat can stop.
var _hazard_beat     : int       = 0
## Prevents room transitions while the death sequence is running.
var _dying           : bool      = false

var _residency := RoomResidency.new()
var _baseline_tween: Tween

func _ready() -> void:
	assert(SaveSystem.has_session(), "The game runs on a session that Boot or the title began")
	_camera.follow(_player)
	_player.fell_into_hazard.connect(_on_player_fell_into_hazard)
	_player.died.connect(_on_player_died)
	_player.sat_down.connect(_on_player_sat_down)
	_player.door_entered.connect(_on_player_entered_door)
	_screens.set_map_subject(_player)
	_screens.set_notebook_watcher(_notebook_watcher)
	if SaveSystem.bench_id() != &"":
		_arrive()
	for room: Room in get_tree().get_nodes_in_group(Room.GROUP):
		room.room_entered.connect(_on_room_entered)
		var region := room.get_region()
		if not region.memory_changed.is_connected(_on_region_memory_changed):
			region.memory_changed.connect(_on_region_memory_changed.bind(region))

## Quits without saving: only benches save.
func quit_game() -> void:
	get_tree().quit()

## Leaves for the title without saving, behind the black Screens already drew.
func quit_to_title() -> void:
	_swap_to_title.call_deferred()

# Ivo leaves the current room only when his whole body is out of it: a hop that straddles a seam never flips
# the room (bugs/a-hop-below-a-seam-flips-the-room-twice, bugs/walking-across-a-room-seam-fades-back-and-forth);
# the camera keeps him in frame meanwhile. Walking across a seam neither fades nor stops him
# (bugs/a-jump-across-a-horizontal-seam-loses-its-height-in-the-fade).
func _physics_process(_delta: float) -> void:
	if _current_room == null or _is_transitioning or _dying:
		return
	var body := _player.body_rect()
	if _current_room.get_bounds().intersects(body):
		return
	var room := _room_at(body.get_center())
	if room == null:
		return
	# A region seam cuts: its memory, season and weather would show mixed in a glide
	# (bugs/a-neighbour-room-in-another-region-runs-on-the-current-regions-memory). So does a teleport.
	var glide := room.get_region() == _current_room.get_region() and RoomResidency.touches(_current_room, room)
	_enter_room(room, glide)
	if not glide:
		_camera.snap()
	room_changed.emit(room)

## Seeds the first room when no bench placed Ivo; later rooms are found from his feet.
func _on_room_entered(room: Room) -> void:
	if _current_room != null or _is_transitioning or _dying:
		return
	if not room.get_bounds().has_point(_player.body_rect().get_center()):
		return
	_is_transitioning = true
	# Deferred: body_entered arrives inside the physics step (gotchas/disabling-a-body-inside-its-own-physics-step-errors-its-move).
	_player.set_deferred(&"process_mode", Node.PROCESS_MODE_DISABLED)
	_enter_room(room)
	room_changed.emit(room)
	await _fade.to_clear()
	_player.process_mode = Node.PROCESS_MODE_INHERIT
	_is_transitioning = false

## Makes `room` current, runs its neighbours and moves the memory field and camera to it; `glide` eases both.
func _enter_room(room: Room, glide: bool = false) -> void:
	_current_room = room
	_residency.settle(room, get_tree().get_nodes_in_group(Room.GROUP))
	# The greyhush is a regional property, so it follows the room the player is
	# standing in rather than being set once at startup.
	var region := _current_room.get_region()
	_set_baseline(region.current_baseline(), glide)
	_memory_field.season = region.season
	_memory_field.palette = song_catalog.palette_for(region.season) if song_catalog else null
	_camera.set_bounds(_current_room.get_bounds(), glide)
	if not room.interior:
		_screens.clear_map_anchor()

func _set_baseline(level: float, glide: bool) -> void:
	if _baseline_tween:
		_baseline_tween.kill()
	if not glide:
		_memory_field.baseline = level
		return
	_baseline_tween = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	_baseline_tween.tween_property(_memory_field, "baseline", level, baseline_glide_time)

## Respawns at firm ground after a hazard fade; a newer fall supersedes this beat.
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
			room_changed.emit(room)
		_camera.snap()
	await _fade.to_clear()

## Enters the saved bench room and waits for deferred contents before finding its seat.
func _arrive() -> void:
	var room := _room_by_key(SaveSystem.bench_room())
	if room == null:
		push_warning("The saved bench's room %s is not in this world; starting at the authored start" % SaveSystem.bench_room())
		return
	_is_transitioning = true
	_player.process_mode = Node.PROCESS_MODE_DISABLED
	await _land_in(room, _seat_at_saved_bench)
	_player.process_mode = Node.PROCESS_MODE_INHERIT
	_is_transitioning = false
	await _fade.to_clear()

func _seat_at_saved_bench() -> void:
	var seat := Seat.find(get_tree(), SaveSystem.bench_id())
	if seat != null:
		_player.sit(seat)
	else:
		push_warning("The saved bench %s is not in its room; starting at the authored start" % SaveSystem.bench_id())

## Enters `room` behind the black, waits for its deferred contents, lets `place` put Ivo in it, then frames it.
func _land_in(room: Room, place: Callable) -> void:
	_enter_room(room)
	var contents := room.contents()
	if contents != null and not contents.is_node_ready():
		await contents.ready
	place.call()
	_camera.snap()
	# Not at _enter_room: a physics step can run before the placing, framing the old spot (bugs/a-debug-boot-reveals-map-cells-ivo-never-saw).
	room_changed.emit(room)

## Carries Ivo through `door` to its partner (architecture/doors-and-interiors).
func _on_player_entered_door(door: Door) -> void:
	if _is_transitioning or _dying or _current_room == null:
		return
	var room := _room_named(door.to_room, _current_room.get_region())
	if room == null:
		push_warning("Door %s leads to room %s, which is not in region %s" % [door.link, door.to_room, _current_room.get_region().name])
		return
	# Copied before the first await: the door's room is deactivated, and may be evicted, behind the black.
	var link := door.link
	var door_point := door.global_position
	var leaving_map := not _current_room.interior
	_is_transitioning = true
	# Deferred: the press arrives inside Ivo's own physics step (gotchas/disabling-a-body-inside-its-own-physics-step-errors-its-move).
	_player.set_deferred(&"process_mode", Node.PROCESS_MODE_DISABLED)
	await _fade.to_black()
	await _land_in(room, _arrive_through.bind(room, link))
	if leaving_map and room.interior:
		_screens.set_map_anchor(door_point)
	await _fade.to_clear()
	_player.process_mode = Node.PROCESS_MODE_INHERIT
	_is_transitioning = false

func _arrive_through(room: Room, link: StringName) -> void:
	var arrival := Door.find(get_tree(), room, link)
	if arrival == null:
		push_warning("Room %s has no door with link %s" % [room.id(), link])
		return
	_player.arrive_at(arrival)

## The room with id `room_id` among `region`'s rooms.
func _room_named(room_id: StringName, region: Region) -> Room:
	for room: Room in get_tree().get_nodes_in_group(Room.GROUP):
		if room.get_region() == region and room.id() == room_id:
			return room
	return null

func _room_by_key(key: String) -> Room:
	for room: Room in get_tree().get_nodes_in_group(Room.GROUP):
		if SceneKey.of(room) == key:
			return room
	return null

## Restores Ivo and records the bench as the respawn point.
func _on_player_sat_down(seat: Seat) -> void:
	_player.rest()
	seat.rest()
	var room := _room_at(seat.global_position)
	var room_key := SceneKey.of(room) if room != null else ""
	var region_key := room.get_region().name_key if room != null else ""
	SaveSystem.rest_at(seat.bench_id, room_key, region_key)
	if _current_room != null:
		_residency.wake(_current_room, get_tree().get_nodes_in_group(Room.GROUP))

## Rewinds to the bench only after the death clip and black fade finish.
func _on_player_died() -> void:
	assert(not get_tree().paused, "Nothing deals damage while the world is paused")
	_dying = true
	# A hazard beat still running stands down at its next check.
	_hazard_beat += 1
	var region := _current_room.get_region() if _current_room != null else null
	var region_key := SceneKey.of(region) if region != null else ""
	var point := region.to_local(_player.global_position) if region != null else Vector2.ZERO
	if not _player.is_death_shown():
		await _player.death_shown
	await get_tree().create_timer(death_hold, false).timeout
	await _fade.to_black()
	if region != null:
		SaveSystem.record_death(region_key, point)
	else:
		SaveSystem.rewind()
	_reload_world.call_deferred()

func _reload_world() -> void:
	SceneSwap.replace(self, load(scene_file_path) as PackedScene)

func _swap_to_title() -> void:
	SceneSwap.replace(self, load(title_scene) as PackedScene)

func _room_at(point: Vector2) -> Room:
	for room: Room in get_tree().get_nodes_in_group(Room.GROUP):
		if room.get_bounds().has_point(point):
			return room
	return null

## Updates the displayed region's memory immediately when it changes.
func _on_region_memory_changed(level: float, region: Region) -> void:
	if _current_room != null and _current_room.get_region() == region:
		_set_baseline(level, false)
