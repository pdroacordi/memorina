class_name CastShadow extends PulseEffect

## Sombra (Enums.Song.SHADOW): the noon sun burns Ivo's shadow into the place
## he played, and until the pulse closes it COUNTS AS HIM being there (design
## 02 section 7.1). It weighs what he weighs - its Presence carries a Weight,
## so a plate or a seesaw counts it with no rule of its own - and creatures
## take it for him: the Presence is in EnemySight.PRESENCE, and it is a
## Hurtbox, so whatever they swing at it lands on it. It never fights back
## (design 02, "Sombra e o combate comum"): the first blow breaks it into
## ash, and whatever it was holding lets go.
##
## It is the frame Ivo was showing when the song ended - the instrument still
## raised - drawn as world art (the grey takes it), dark, with a rim burning
## in the summer tint and shimmering like air over hot stone. It rides what it
## was cast on: a shadow left on a seesaw's plank tilts with the plank, rather
## than floating off the wood and letting go of the weight it is there for.

## Terrain and Props: what a shadow can be cast on.
const FLOOR_MASK := 0b11
## How far below the feet the floor is looked for, px.
const FLOOR_PROBE := 12.0

@export var burn_material: ShaderMaterial
## How much lighter than the song's tint the rim burns.
@export_range(0.0, 1.0) var rim_lightness := 0.3
## Seconds a broken shadow takes to fall to ash.
@export var break_time := 0.35

var _silhouette: Sprite2D
var _material: ShaderMaterial
var _anchored := false
var _floor: Node2D
var _on_floor := Transform2D.IDENTITY
var _contract_from := -1.0
var _broken := false
var _clock := 0.0

@onready var _presence: Hurtbox = $Presence
@onready var _presence_shape: CollisionShape2D = $Presence/CollisionShape2D
@onready var _ash: CPUParticles2D = $Ash

func _ready() -> void:
	var body := pulse.performer as Character
	if body == null:
		# Nobody's frame to burn: a pulse no one played.
		queue_free()
		return
	global_position = body.global_position
	_silhouette = body.silhouette()
	_silhouette.transform = global_transform.affine_inverse() * _silhouette.transform
	_material = burn_material.duplicate() as ShaderMaterial
	_material.set_shader_parameter("rim_color", pulse.song().tint().lightened(rim_lightness))
	_silhouette.material = _material
	add_child(_silhouette)
	move_child(_silhouette, 0)
	_presence.hit_received.connect(_on_hit_received)

func _physics_process(delta: float) -> void:
	if not _anchored:
		_anchor()
	if is_instance_valid(_floor):
		global_transform = _floor.global_transform * _on_floor
	_clock += delta
	_material.set_shader_parameter("clock", _clock)
	if not _broken:
		_material.set_shader_parameter("fade", _fade())

## Whether it still stands for Ivo: false once something has broken it.
func is_standing() -> bool:
	return not _broken

## Finds what it was cast on, in the first physics frame (the space is only
## guaranteed current there), and keeps its place on it from then on.
func _anchor() -> void:
	_anchored = true
	var query := PhysicsRayQueryParameters2D.create(global_position + Vector2(0, -4), global_position + Vector2(0, FLOOR_PROBE), FLOOR_MASK)
	_floor = get_world_2d().direct_space_state.intersect_ray(query).get("collider") as Node2D
	if _floor:
		_on_floor = _floor.global_transform.affine_inverse() * global_transform

## Whole until the grey starts taking the pulse back, then as much of it as
## the pulse still covers.
func _fade() -> float:
	if pulse.phase() != PulseTimeline.Phase.CONTRACT:
		return 1.0
	if _contract_from < 0.0:
		_contract_from = maxf(pulse.radius(), 1.0)
	return clampf(pulse.radius() / _contract_from, 0.0, 1.0)

func _on_hit_received(_damage: int, _knockback: Vector2, _source: Node2D) -> void:
	if _broken:
		return
	_broken = true
	# Out of every creature's sight and off every sensor at once: whatever it
	# was holding lets go.
	_presence.remove_from_group(EnemySight.PRESENCE)
	_presence_shape.set_deferred("disabled", true)
	_ash.restart()
	var tween := create_tween()
	tween.tween_method(func(f: float) -> void: _material.set_shader_parameter("fade", f), _fade(), 0.0, break_time)
