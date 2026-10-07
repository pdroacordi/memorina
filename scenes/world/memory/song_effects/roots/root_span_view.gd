class_name RootSpanView extends Node2D

## Draws a root span and adds its bridge, rung or pillar collision when joined.

## How thick the strands are drawn, px (the root art's height).
const STRAND_THICKNESS := 10.0
const BRIDGE_THICKNESS := 8.0
const POLE_WIDTH := 20.0

var _span: RootSpanFinder.Span
var _crossings: Array[Dictionary] = []
var _floor: StaticBody2D
var _climbable: Climbable

func setup(span: RootSpanFinder.Span, room: RoomMapNode, strand: Texture2D) -> void:
	top_level = true
	_span = span
	match span.kind:
		RootSpanFinder.Kind.BRIDGE:
			var ra := room.cell_rect(span.a)
			var rb := room.cell_rect(span.b)
			var from := Vector2(ra.end.x, ra.position.y)
			var to := Vector2(rb.position.x, rb.position.y)
			_add_crossing(from, to, strand, STRAND_THICKNESS * 0.5)
			_floor = StaticBody2D.new()
			# Roots wither: never a place to be sent back to.
			_floor.add_to_group(SafeGroundTracker.UNSAFE)
			var shape := CollisionShape2D.new()
			var box := RectangleShape2D.new()
			box.size = Vector2(to.x - from.x, BRIDGE_THICKNESS)
			shape.shape = box
			shape.one_way_collision = true
			shape.disabled = true
			shape.position = Vector2((from.x + to.x) * 0.5, from.y + BRIDGE_THICKNESS * 0.5)
			_floor.add_child(shape)
			add_child(_floor)
		RootSpanFinder.Kind.SHAFT:
			_climbable = Climbable.new()
			_climbable.grip = Climbable.Grip.WALL
			add_child(_climbable)
			for row: int in range(span.rows.x, span.rows.y + 1):
				var ra := room.cell_rect(Vector2i(span.a.x, row))
				var rb := room.cell_rect(Vector2i(span.b.x, row))
				var y := ra.get_center().y
				var crossing := _add_crossing(Vector2(ra.end.x, y), Vector2(rb.position.x, y), strand, 0.0)
				var shape := CollisionShape2D.new()
				var box := RectangleShape2D.new()
				box.size = Vector2(rb.position.x - ra.end.x, ra.size.y)
				shape.shape = box
				shape.disabled = true
				shape.position = Vector2((ra.end.x + rb.position.x) * 0.5, y)
				_climbable.add_child(shape)
				crossing["shape"] = shape
		RootSpanFinder.Kind.PILLAR:
			var floor_rect := room.cell_rect(span.a)
			var ceiling_rect := room.cell_rect(span.b)
			var x := floor_rect.get_center().x
			var crossing := _add_crossing(Vector2(x, floor_rect.position.y), Vector2(x, ceiling_rect.end.y), strand, 0.0)
			_climbable = Climbable.new()
			_climbable.grip = Climbable.Grip.POLE
			add_child(_climbable)
			var shape := CollisionShape2D.new()
			var box := RectangleShape2D.new()
			box.size = Vector2(POLE_WIDTH, floor_rect.position.y - ceiling_rect.end.y)
			shape.shape = box
			shape.disabled = true
			shape.position = Vector2(x, (floor_rect.position.y + ceiling_rect.end.y) * 0.5)
			_climbable.add_child(shape)
			crossing["shape"] = shape

func advance(delta: float, grower: RootGrower) -> void:
	for crossing: Dictionary in _crossings:
		var strands: RootStrands = crossing["strands"]
		var a: Vector2 = crossing["a"]
		var b: Vector2 = crossing["b"]
		var along := (b - a).normalized()
		# Wet earth is needed to reach across, not to hold: a joined span stays while the pulse covers its faces.
		var allowed := strands.is_joined() or grower.reaches(_span, a, b)
		strands.advance(delta, grower.grow_speed, grower.wither_speed,
			grower.memory_at(a + along * strands.a), grower.memory_at(b - along * strands.b),
			allowed and grower.holds(a), allowed and grower.holds(b))
		var sprite_a: Sprite2D = crossing["sprite_a"]
		var sprite_b: Sprite2D = crossing["sprite_b"]
		sprite_a.region_rect.size.x = strands.a
		sprite_b.region_rect.size.x = strands.b
		sprite_a.visible = strands.a > 0.0
		sprite_b.visible = strands.b > 0.0
		var joined := strands.is_joined()
		if crossing["joined"] != joined:
			crossing["joined"] = joined
			var shape: CollisionShape2D = crossing["shape"]
			if shape == null and _floor:
				shape = _floor.get_child(0) as CollisionShape2D
			if shape:
				shape.set_deferred(&"disabled", not joined)

## Whether any crossing is currently joined.
func is_joined() -> bool:
	for crossing: Dictionary in _crossings:
		if crossing["joined"]:
			return true
	return false

func span() -> RootSpanFinder.Span:
	return _span

func _add_crossing(a: Vector2, b: Vector2, strand: Texture2D, drop: float) -> Dictionary:
	var crossing := {
		"a": a,
		"b": b,
		"strands": RootStrands.new(a.distance_to(b)),
		"sprite_a": _strand_sprite(a, b - a, strand, drop),
		"sprite_b": _strand_sprite(b, a - b, strand, drop),
		"joined": false,
		"shape": null,
	}
	_crossings.append(crossing)
	return crossing

## Creates a repeated strand along a line; `drop` offsets it vertically in pixels.
func _strand_sprite(from: Vector2, direction: Vector2, strand: Texture2D, drop: float) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = strand
	sprite.centered = false
	sprite.region_enabled = true
	sprite.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	sprite.region_rect = Rect2(0.0, 0.0, 0.0, STRAND_THICKNESS)
	sprite.rotation = direction.angle()
	sprite.offset = Vector2(0.0, -STRAND_THICKNESS * 0.5)
	sprite.position = from + Vector2(0.0, drop)
	sprite.visible = false
	add_child(sprite)
	return sprite
