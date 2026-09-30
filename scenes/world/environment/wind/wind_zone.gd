class_name WindZone extends AirflowSource

## A natural current: a box of air moving one way, breathing through its
## WindProfile. It reads as the WORLD's doing - directional streaks and leaves
## in layers, no ring, no colour of its own (design 03 section 5.3: "direcional
## e em camadas = foi o mundo") - and it pushes through Airflow like any other
## air, so Vendaval played into it adds to it (design 02 section 8, Outono
## Espacial 2) with no rule for the pair.
##
## Congelar stops it where it blows: while a FREEZE pulse covers it, the air
## is still and its streaks hang where they were, icy (design 02 section 8,
## Inverno Logico 2: freezing one current of several). The grey stops it too,
## through Airflow's memory scaling and the clock below.
##
## The box stands on the node, as a room map entity standing on its cell: it
## is centred on the node horizontally and rises `size.y` above it.

## Frozen streaks take this colour.
const FROST := Color(0.75, 0.88, 1.0)

@export var size := Vector2(256, 160)
@export var direction := Vector2.RIGHT
## The air's speed at full strength, px/s. Ivo's ground grip ignores anything
## under LocomotionStats.wind_deadzone; in the air he rides all of it.
@export var speed := 220.0
## Its breathing. Null blows steadily.
@export var profile: WindProfile
## Seconds into the profile it starts at, so two currents need not gust together.
@export var phase := 0.0
## Pixels over which the push fades to nothing at the box's edges.
@export var edge := 24.0

var _time := 0.0
var _strength := 1.0
var _frozen := false
var _memory: MemoryField

@onready var _streaks: CPUParticles2D = $Streaks
@onready var _leaves: CPUParticles2D = $Leaves
@onready var _receiver: SongReceiver = $FreezeReceiver
@onready var _receiver_shape: CollisionShape2D = $FreezeReceiver/CollisionShape2D

func _ready() -> void:
	super()
	_time = phase
	_memory = MemoryField.find_in(self)
	_fit()
	_receiver.song_entered.connect(_on_freeze_entered)
	_receiver.song_left.connect(_on_freeze_left)

func rect() -> Rect2:
	return Rect2(Vector2(-size.x * 0.5, -size.y), size)

func is_frozen() -> bool:
	return _frozen

func wind_at(global_point: Vector2) -> Vector2:
	if _frozen:
		return Vector2.ZERO
	var local := to_local(global_point)
	var box := rect()
	if not box.has_point(local):
		return Vector2.ZERO
	var inset := minf(minf(local.x - box.position.x, box.end.x - local.x), minf(local.y - box.position.y, box.end.y - local.y))
	var falloff := clampf(inset / edge, 0.0, 1.0) if edge > 0.0 else 1.0
	return direction.normalized() * speed * _strength * falloff

func _physics_process(delta: float) -> void:
	var rate := _memory.sample(to_global(rect().get_center())) if _memory else 1.0
	if not _frozen:
		_time += delta * rate
	_strength = profile.strength(_time) if profile else 1.0
	# Stopped air leaves its streaks hanging, exactly where they were.
	var flow := 0.0 if _frozen else rate
	for emitter: CPUParticles2D in [_streaks, _leaves]:
		emitter.speed_scale = flow
	_streaks.modulate = Color(FROST, 0.7) if _frozen else Color(1, 1, 1, lerpf(0.12, 0.7, _strength))
	_leaves.modulate.a = 1.0 if _frozen else lerpf(0.35, 1.0, _strength)

## Sizes the emitters and the freeze receiver to the box.
func _fit() -> void:
	var centre := rect().get_center()
	var velocity := speed * 1.6
	var travel := size.x if absf(direction.x) >= absf(direction.y) else size.y
	var area := size.x * size.y
	for emitter: CPUParticles2D in [_streaks, _leaves]:
		emitter.position = centre
		emitter.emission_rect_extents = size * 0.5
		emitter.direction = direction.normalized()
	_streaks.angle_min = rad_to_deg(direction.angle())
	_streaks.angle_max = _streaks.angle_min
	_streaks.initial_velocity_min = velocity
	_streaks.initial_velocity_max = velocity * 1.2
	_streaks.lifetime = travel / velocity
	_streaks.amount = clampi(roundi(area / 1800.0), 6, 64)
	_leaves.initial_velocity_min = speed * 0.7
	_leaves.initial_velocity_max = speed
	_leaves.lifetime = travel / speed
	_leaves.amount = clampi(roundi(area / 7000.0), 2, 18)
	var shape := RectangleShape2D.new()
	shape.size = size
	_receiver_shape.shape = shape
	_receiver_shape.position = centre

func _on_freeze_entered(_song: Song, _origin: Vector2) -> void:
	_frozen = true

func _on_freeze_left(_song: Song) -> void:
	_frozen = _receiver.is_lit()
