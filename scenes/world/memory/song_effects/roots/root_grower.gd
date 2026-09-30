class_name RootGrower extends PulseEffect

## Enraizar (Enums.Song.ROOT): roots join earth to earth (design 02 section
## 7.1). Wherever two earth faces are both inside the pulse's clean disc, roots
## grow across the gap from both, at the memory under each tip: between two
## banks a bridge (a one-way floor once they meet), across a narrow shaft a web
## of rungs to climb, from the floor under Ivo to the ceiling above him a
## pillar to climb. A face the pulse leaves withers its root back, so a bridge
## breaks at its tips first; stone never roots. Wet earth - inside a Chuva
## pulse - lets a bridge reach farther (design 02 section 7.4).
##
## Where roots can grow is read once from the room's map (RootSpanFinder);
## what grows, and how far, is decided every frame from the pulse.

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

func _ready() -> void:
	top_level = true
	global_position = Vector2.ZERO
	_room = RoomMapNode.at(self, pulse.global_position)
	if _room == null:
		return
	_field = MemoryField.find_in(self)
	var spans := RootSpanFinder.find(_room.map, wet_bridge_cells, max_shaft_width, min_shaft_rows, max_pillar_cells)
	var pillar := _nearest_pillar(spans)
	var reach := pulse.song().pulse_stats.max_radius + float(RoomMapNode.FLOOR_TILESET.tile_size.x)
	for span: RootSpanFinder.Span in spans:
		if span.kind == RootSpanFinder.Kind.PILLAR and span != pillar:
			continue
		# Only what this pulse could ever reach is built at all.
		if not _within(span, reach):
			continue
		var view := RootSpanView.new()
		view.setup(span, _room, strand)
		add_child(view)
		_views.append(view)

func _physics_process(delta: float) -> void:
	for view: RootSpanView in _views:
		view.advance(delta, self)

## The memory at a point, for the tips: 1 where there is no field.
func memory_at(point: Vector2) -> float:
	return _field.sample(point) if _field else 1.0

## Whether a root may grow from `point`: inside this pulse's clean disc.
func holds(point: Vector2) -> bool:
	return pulse.contains(point)

## Whether this span may be crossed: short enough, or wet at both faces.
func reaches(span: RootSpanFinder.Span, a: Vector2, b: Vector2) -> bool:
	if span.kind != RootSpanFinder.Kind.BRIDGE or span.gap() <= max_bridge_cells:
		return true
	return span.gap() <= wet_bridge_cells and _wet(a) and _wet(b)

func _wet(point: Vector2) -> bool:
	for rain: ColorPulse in ColorPulse.lit(self, Enums.Song.RAIN):
		if rain.contains(point):
			return true
	return false

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
