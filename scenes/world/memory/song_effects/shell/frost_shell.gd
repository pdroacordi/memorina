class_name FrostShell extends PulseEffect

## Redoma (Enums.Song.BELL_JAR); see docs/design/02_canções.md section 7.1.

const LAYER := 1 << 3
const INSIDE_MASK := (1 << 8) | (1 << 1)
const SEGMENTS := 48
## Exit clearance in px before a body is considered outside the shell.
const CLEARANCE := 28.0
## Seconds between rime crystal rerolls.
const RIME_PERIOD := 0.25

@export var color := Color(0.86, 0.95, 1.0, 0.95)
@export var thickness := 2.0

var _collider: StaticBody2D
var _segments: Array[SegmentShape2D] = []
var _shapes: Array[CollisionShape2D] = []
var _inside: Array[PhysicsBody2D] = []
var _closed := false
var _radius := 0.0
var _held_water: Array[WaterBody] = []
# The effect's own clock: world time, so the rime holds still under a pause.
var _clock := 0.0

@onready var _shelter: DiscShelter = $Shelter

func _ready() -> void:
	top_level = true
	global_position = pulse.global_position
	_collider = StaticBody2D.new()
	# The shrinking shell is not a valid respawn surface.
	_collider.add_to_group(SafeGroundTracker.UNSAFE)
	_collider.collision_layer = LAYER
	_collider.collision_mask = 0
	add_child(_collider)
	for i in SEGMENTS:
		var segment := SegmentShape2D.new()
		var shape := CollisionShape2D.new()
		shape.shape = segment
		shape.disabled = true
		_collider.add_child(shape)
		_segments.append(segment)
		_shapes.append(shape)

func _physics_process(delta: float) -> void:
	_clock += delta
	var radius := pulse.radius()
	if not _closed and pulse.phase() != PulseTimeline.Phase.ATTACK and radius > CLEARANCE:
		_close(radius)
	if _closed:
		# Prevent a later pulse expansion from growing a closed shell through bodies.
		radius = minf(radius, _radius)
		if absf(radius - _radius) > 0.5:
			_refit(radius)
		# A body that came to be wholly inside without crossing the ring (a respawn) may leave too.
		_adopt(radius - CLEARANCE)
		_let_out(radius)
	_shelter.radius = _radius if _closed else 0.0
	_hold_water_out(_radius if _closed else 0.0)
	queue_redraw()

func _exit_tree() -> void:
	for water: WaterBody in _held_water:
		if is_instance_valid(water):
			water.release(self)

func _draw() -> void:
	var radius := _radius if _closed else pulse.radius()
	if radius < 2.0:
		return
	var points := maxi(32, int(radius * 0.5))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, points, color, thickness, false)
	var seed_step := int(_clock / RIME_PERIOD)
	for i in 12:
		var angle := fposmod(float(i * 7919 + seed_step * 131) * 0.137, TAU)
		draw_rect(Rect2((Vector2.from_angle(angle) * radius).round() - Vector2.ONE, Vector2(2, 2)), Color.WHITE)

func holds(global_point: Vector2) -> bool:
	return _closed and global_point.distance_to(global_position) < _radius

func _close(radius: float) -> void:
	_closed = true
	_adopt(radius)
	_refit(radius)
	for shape: CollisionShape2D in _shapes:
		shape.set_deferred(&"disabled", false)

## Lets every Player or Props body within `radius` of the centre pass the ring: it is inside, and may leave.
func _adopt(radius: float) -> void:
	if radius <= 0.0:
		return
	var query := PhysicsShapeQueryParameters2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius
	query.shape = circle
	query.transform = Transform2D(0.0, global_position)
	query.collision_mask = INSIDE_MASK
	for hit: Dictionary in get_world_2d().direct_space_state.intersect_shape(query, 32):
		var body := hit.get("collider") as PhysicsBody2D
		if body and not _inside.has(body):
			_collider.add_collision_exception_with(body)
			_inside.append(body)

func _refit(radius: float) -> void:
	_radius = radius
	for i in SEGMENTS:
		_segments[i].a = Vector2.from_angle(TAU * i / SEGMENTS) * radius
		_segments[i].b = Vector2.from_angle(TAU * (i + 1) / SEGMENTS) * radius

func _let_out(radius: float) -> void:
	for body: PhysicsBody2D in _inside.duplicate():
		if not is_instance_valid(body):
			_inside.erase(body)
		elif body.global_position.distance_to(global_position) > radius + CLEARANCE:
			_collider.remove_collision_exception_with(body)
			_inside.erase(body)

func _hold_water_out(radius: float) -> void:
	for member: Node in get_tree().get_nodes_in_group(WaterBody.GROUP):
		var water := member as WaterBody
		var near := radius > 0.0 and absf(water.global_position.x - global_position.x) < water.size.x * 0.5 + radius
		if near:
			water.hold_out(self, global_position, radius)
			if not _held_water.has(water):
				_held_water.append(water)
		elif _held_water.has(water):
			water.release(self)
			_held_water.erase(water)
