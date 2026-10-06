class_name MapScreen
extends MenuScreen
## The map: every seen room over the dimmed world, opened centred on Ivo, panned and zoomed in real time. It never holds the world.

## Pack px per 64 px cell at each zoom step, farthest first.
const CELL_PX_STEPS: Array[int] = [1, 2, 4, 8]
## Index in CELL_PX_STEPS the map opens at; 4 px per cell is the approved mockup's scale.
const OPEN_STEP := 2
## Longest pan step one frame may take, in real seconds, so a hitch does not throw the view.
const MAX_PAN_SECONDS := 0.05

## Pan speed in pack px per real second at full tilt.
@export var pan_speed: float = 160.0

## Ivo: the map centres on him and asks him whether it may open. Set through Screens.
var subject: Player
## Pan intent. Set by Screens.
var menu_input: MenuInput

## World px at the middle of the screen.
var _centre: Vector2 = Vector2.ZERO
var _step: int = OPEN_STEP
## `Time.get_ticks_usec()` at the last pan; the pan runs on real time.
var _ticks_usec: int = 0
## 1 per axis once that axis has read zero since the open: a walk direction held through the open does not pan.
var _pan_armed: Vector2 = Vector2.ZERO
## Each room's geometry with the bytes it was built from, keyed by room scene key; an open rebuilds only rooms whose bytes changed.
var _built: Dictionary[String, MapCanvas.Patch] = {}
var _built_from: Dictionary[String, PackedByteArray] = {}

@onready var _art: Control = $Art
@onready var _canvas: MapCanvas = %Canvas


func _ready() -> void:
	set_process(false)

# Real seconds: the world's clock is slowed by a recall and a hit-stop, and the map's pan is not.
func _process(_delta: float) -> void:
	var now := Time.get_ticks_usec()
	var seconds := (now - _ticks_usec) / 1_000_000.0
	_ticks_usec = now
	if menu_input != null:
		pan_held(menu_input.pan, seconds)

func can_open() -> bool:
	return subject != null and subject.can_open_map()

func open() -> void:
	_canvas.build(_seen_patches())
	_step = OPEN_STEP
	_canvas.set_cell_px(cell_px())
	_centre = _clamped(subject.global_position if subject != null else Vector2.ZERO)
	_place()
	_ticks_usec = Time.get_ticks_usec()
	_pan_armed = Vector2.ZERO
	set_process(true)
	show()

func close() -> void:
	set_process(false)
	hide()

## +1 steps nearer, -1 farther; the centre stays where it is.
func zoom(direction: int) -> void:
	var step := clampi(_step + direction, 0, CELL_PX_STEPS.size() - 1)
	if step == _step:
		return
	_step = step
	_canvas.set_cell_px(cell_px())
	_place()

## Pans by `pan` (-1..1 per axis) held for `seconds` real seconds, capped at MAX_PAN_SECONDS.
## An axis held since the open is ignored until it reads zero (bugs/a-direction-held-when-the-map-opens-pans-it-off-ivo).
func pan_held(pan: Vector2, seconds: float) -> void:
	if is_zero_approx(pan.x):
		_pan_armed.x = 1.0
	if is_zero_approx(pan.y):
		_pan_armed.y = 1.0
	var armed := pan * _pan_armed
	if armed != Vector2.ZERO:
		pan_by(armed * pan_speed * minf(seconds, MAX_PAN_SECONDS))

## Moves the view by `offset` pack px, clamped so the centre never leaves the seen area.
func pan_by(offset: Vector2) -> void:
	_centre = _clamped(_centre + offset * MapGrid.CELL_PX / cell_px())
	_place()

func cell_px() -> int:
	return CELL_PX_STEPS[_step]

## World px at the middle of the screen.
func centre() -> Vector2:
	return _centre

func _clamped(point: Vector2) -> Vector2:
	var seen := _canvas.seen_rect()
	if not seen.has_area():
		return point
	return point.clamp(seen.position, seen.end)

## Whole pack px, so every cell lands on the 2x pixel grid.
func _place() -> void:
	_canvas.position = (_art.size * 0.5 - _centre * cell_px() / MapGrid.CELL_PX).round()

func _seen_patches() -> Array[MapCanvas.Patch]:
	var patches: Array[MapCanvas.Patch] = []
	for room: Room in get_tree().get_nodes_in_group(Room.GROUP):
		var key := SceneKey.of(room)
		var bytes := SaveSystem.map_seen(key)
		if bytes.is_empty():
			continue
		var bounds := room.get_bounds()
		var patch: MapCanvas.Patch = _built.get(key)
		if _built_from.get(key, PackedByteArray()) != bytes or (patch != null and patch.origin != bounds.position):
			var grid := MapGrid.from_bytes(bytes, MapGrid.dims_for(bounds))
			patch = MapCanvas.Patch.new(bounds.position, grid) if not grid.is_empty() else null
			_built[key] = patch
			_built_from[key] = bytes
		if patch != null:
			patches.append(patch)
	return patches
