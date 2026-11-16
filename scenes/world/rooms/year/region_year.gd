class_name RegionYear
extends Node
## The only owner of a region's year: its elapsed time, in memory only, advanced on the pausable, scaled clock while Ivo
## is outdoors in the region, out of any story, and no forgetting source is in view (architecture/story-07-epilogue).

## A turn ended: the region is now in `season`.
signal season_changed(season: Enums.Season)

@export var stats: YearStats

## Scaled seconds of advance, wrapped at one cycle.
var _elapsed: float = 0.0
var _start: Enums.Season = Enums.Season.SPRING
var _field: MemoryField
var _ivo: Player
## The room Ivo was last found in, so the search runs only when he leaves it.
var _room: Room
## A run (`run_year`): scaled seconds left, advance per scaled second, and where it began; `_run_left` 0 when none.
var _run_left: float = 0.0
var _run_rate: float = 0.0
var _run_from: float = 0.0


func _ready() -> void:
	var region := get_parent() as Region
	assert(region != null and stats != null, "%s needs a Region parent and YearStats" % name)
	_start = region.season
	_field = MemoryField.find_in(self)

func _physics_process(delta: float) -> void:
	if is_running():
		_tick_run(delta)
	elif can_advance():
		advance(delta)

func season() -> Enums.Season:
	return YearMath.at(_elapsed, stats, _start).season

func next_season() -> Enums.Season:
	return YearMath.at(_elapsed, stats, _start).next

## 0..1 through the turn into `next_season()`; 0 while a season holds.
func turn() -> float:
	return YearMath.at(_elapsed, stats, _start).turn

## Moves the year on by `seconds` of advance, emitting `season_changed` at each commit it passes.
func advance(seconds: float) -> void:
	var before := season()
	var whole := seconds
	while whole > 0.0:
		var step := minf(whole, stats.season_seconds * 0.5)
		_elapsed = fposmod(_elapsed + step, stats.cycle_seconds())
		whole -= step
		var now := season()
		if now != before:
			before = now
			season_changed.emit(now)

## Passes one whole year over `seconds` (scaled), whatever the gate, ending on the season it began on (the credits).
func run_year(seconds: float) -> void:
	_run_from = _elapsed
	_run_left = maxf(seconds, 0.0)
	_run_rate = stats.cycle_seconds() / seconds if seconds > 0.0 else 0.0

## Ends a run at once where it began; nothing when none runs.
func settle() -> void:
	if not is_running():
		return
	_run_left = 0.0
	_jump_to(_run_from)

func is_running() -> bool:
	return _run_left > 0.0

## The gate, Ivo outdoors in this region and out of any story, and no forgetting source in view.
func can_advance() -> bool:
	if _field == null or _field.year != self:
		return false
	if _ivo == null:
		_ivo = get_tree().get_first_node_in_group(Player.GROUP) as Player
	if _ivo == null:
		return false
	return may_advance(SaveFact.gates_pass(stats.when, [], SaveSystem.player_data), _room_of_ivo(), get_parent() as Region,
			_ivo.is_in_story(), forgetting_in_view(_field, _view()))

## The year moves only on an open room of its own region, out of any story, with no forgetting source in view.
static func may_advance(gate: bool, room: Room, region: Region, in_story: bool, forgetting: bool) -> bool:
	return gate and room != null and room.get_region() == region and room.has_sky() and not in_story and not forgetting

## A visible source that takes memory away reaches `view`.
static func forgetting_in_view(field: MemoryField, view: Rect2) -> bool:
	for source: MemorySource in field.sources_intersecting(view):
		if source.strength < 0.0:
			return true
	return false

func _tick_run(delta: float) -> void:
	var step := minf(delta, _run_left)
	_run_left -= step
	if _run_left > 0.0:
		advance(step * _run_rate)
	else:
		_jump_to(_run_from)

## Sets the elapsed time, emitting `season_changed` if the season differs.
func _jump_to(elapsed: float) -> void:
	var before := season()
	_elapsed = elapsed
	if season() != before:
		season_changed.emit(season())

func _room_of_ivo() -> Room:
	var feet := _ivo.global_position
	if _room == null or not is_instance_valid(_room) or not _room.get_bounds().has_point(feet):
		_room = Room.at(get_tree(), feet)
	return _room

func _view() -> Rect2:
	var viewport := get_viewport()
	return viewport.get_canvas_transform().affine_inverse() * viewport.get_visible_rect()
