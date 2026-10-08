class_name RootGrower extends PulseEffect

## Enraizar grows roots between earth faces inside its pulse; see design 02 sections 7.1 and 7.4.

## Widest gap, in cells, roots cross from an earth face to a thing hanging beside it.
const MAX_CATCH_CELLS := 3

@export var grow_speed := 110.0
@export var wither_speed := 180.0
## Widest gap a bridge crosses, in cells; wet earth reaches `wet_bridge_cells`.
@export var max_bridge_cells := 10
@export var wet_bridge_cells := 14
@export var max_shaft_width := 4
@export var min_shaft_rows := 2
@export var max_pillar_cells := 8
@export var strand: Texture2D

var _room: RoomMapNode
var _field: MemoryField
var _views: Array[RootSpanView] = []
# Every span in the room this pulse may grow (one pillar at most), which of
# them have a view, and the reach those were built for.
var _spans: Array[RootSpanFinder.Span] = []
var _built := {}
var _built_reach := 0.0
# LoweringPlatform -> the RootCatch holding it.
var _catches := {}

## Whether a bridge `gap` cells wide may grow: up to `dry_cells`, or up to `wet_cells` when both faces are wet.
static func may_bridge(gap: int, dry_cells: int, wet_cells: int, wet: bool) -> bool:
	return gap <= dry_cells or (wet and gap <= wet_cells)

func _ready() -> void:
	top_level = true
	global_position = Vector2.ZERO
	_room = RoomMapNode.at(self, pulse.global_position)
	if _room == null:
		return
	_field = MemoryField.find_in(self)
	var spans := RootSpanFinder.find(_room.map, wet_bridge_cells, max_shaft_width, min_shaft_rows, max_pillar_cells)
	var pillar := _nearest_pillar(spans)
	for span: RootSpanFinder.Span in spans:
		if span.kind != RootSpanFinder.Kind.PILLAR or span == pillar:
			_spans.append(span)
	_build_within(pulse.max_radius())

func _physics_process(delta: float) -> void:
	# Solstice can stretch the pulse after it opened: build what it now reaches.
	if pulse.max_radius() > _built_reach:
		_build_within(pulse.max_radius())
	for view: RootSpanView in _views:
		view.advance(delta, self)
	_update_catches(delta)

## The memory at a point, for the tips: 1 where there is no field.
func memory_at(point: Vector2) -> float:
	return _field.sample(point) if _field else 1.0

## Whether a root may grow from `point`: inside this pulse's clean disc.
func holds(point: Vector2) -> bool:
	return pulse.contains(point)

## Whether this span may be crossed: short enough, or wet at both faces.
func reaches(span: RootSpanFinder.Span, a: Vector2, b: Vector2) -> bool:
	if span.kind != RootSpanFinder.Kind.BRIDGE:
		return true
	# Rain is looked up only for a span too wide to cross dry.
	if may_bridge(span.gap(), max_bridge_cells, wet_bridge_cells, false):
		return true
	return may_bridge(span.gap(), max_bridge_cells, wet_bridge_cells, _wet(a) and _wet(b))

func _wet(point: Vector2) -> bool:
	for rain: ColorPulse in ColorPulse.lit(self, Enums.Song.RAIN):
		if rain.contains(point):
			return true
	return false

## Builds views for spans reachable at `radius`, with one cell of slack.
func _build_within(radius: float) -> void:
	_built_reach = radius
	var reach := radius + float(RoomMapNode.FLOOR_TILESET.tile_size.x)
	for span: RootSpanFinder.Span in _spans:
		if _built.has(span) or not _within(span, reach):
			continue
		_built[span] = true
		var view := RootSpanView.new()
		view.setup(span, _room, strand)
		add_child(view)
		_views.append(view)

## Whether both of a span's faces lie within `reach` of where the song was
## played (a shaft: at its nearest row).
func _within(span: RootSpanFinder.Span, reach: float) -> bool:
	var origin := pulse.global_position
	var a := _room.cell_rect(span.a).get_center()
	var b := _room.cell_rect(span.b).get_center()
	if span.kind == RootSpanFinder.Kind.SHAFT:
		var top := _room.cell_rect(Vector2i(span.a.x, span.rows.x)).get_center().y
		var bottom := _room.cell_rect(Vector2i(span.a.x, span.rows.y)).get_center().y
		var y := clampf(origin.y, top, bottom)
		a.y = y
		b.y = y
	return a.distance_to(origin) <= reach and b.distance_to(origin) <= reach

## The one pillar that grows: from the floor Ivo played on, nearest him.
func _nearest_pillar(spans: Array[RootSpanFinder.Span]) -> RootSpanFinder.Span:
	var best: RootSpanFinder.Span = null
	var best_distance := INF
	var origin := pulse.global_position
	for span: RootSpanFinder.Span in spans:
		if span.kind != RootSpanFinder.Kind.PILLAR:
			continue
		var floor_rect := _room.cell_rect(span.a)
		if absf(floor_rect.position.y - origin.y) > floor_rect.size.y * 0.5:
			continue
		var distance := absf(floor_rect.get_center().x - origin.x)
		if distance < best_distance and distance <= floor_rect.size.x:
			best_distance = distance
			best = span
	return best

## Seizes what hangs between earth faces inside this pulse, and lets go of what the roots no longer hold.
func _update_catches(delta: float) -> void:
	if _room == null:
		return
	for node: Node in get_tree().get_nodes_in_group(LoweringPlatform.GROUP):
		var body := node as LoweringPlatform
		if body == null or _catches.has(body):
			continue
		var faces := _catch_faces(body)
		if faces.is_empty():
			continue
		var catch := RootCatch.new()
		add_child(catch)
		catch.setup(body, faces, body.catch_edges(), strand)
		_catches[body] = catch
	# Untyped: a freed platform fails a typed loop variable (gotchas/a-typed-loop-variable-fails-on-a-freed-object).
	for body in _catches.keys():
		var catch: RootCatch = _catches[body]
		if not is_instance_valid(body) or not catch.advance(delta, self):
			catch.queue_free()
			_catches.erase(body)

## The earth faces left and right of `body` at its height, when both lie in this pulse's clean disc with the body; empty otherwise.
func _catch_faces(body: LoweringPlatform) -> PackedVector2Array:
	var edges := body.catch_edges()
	var faces := PackedVector2Array()
	for side in 2:
		var direction := -1 if side == 0 else 1
		var cell := _room.cell_at(edges[side] + Vector2(direction, 0))
		var column := RootCatchFinder.earth_face(_room.map, cell, direction, MAX_CATCH_CELLS)
		if column < 0 or not holds(edges[side]):
			return PackedVector2Array()
		var rect := _room.cell_rect(Vector2i(column, cell.y))
		var face := Vector2(rect.end.x if side == 0 else rect.position.x, edges[side].y)
		if not holds(face):
			return PackedVector2Array()
		faces.append(face)
	return faces
