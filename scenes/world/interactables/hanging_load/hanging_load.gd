class_name HangingLoad extends RigidBody2D

## A heavy thing on a rope - a cocoon, a sack, a counterweight. Soltar cuts the
## rope: it falls for real (a RigidBody2D), lands, weighs down whatever plate
## it lands on, can be shoved along by Vendaval (it rides the air like any
## light thing), and can be stood on (Props layer). When the grey takes the
## pulse back it returns to its rope - not while Ivo is standing on it.
##
## It slides rather than tumbles (rotation locked, a slick silk surface):
## lying on its side it held the floor harder than a gale could drag it, and
## a cocoon cartwheeling along a ledge reads as a toy, not a weight. Its
## body's bottom corners are cut: a square corner catches on the seams
## between floor tiles and stops dead under a full gale.
##
## Placed like a room map entity standing on its cell: the load hangs so its
## bottom is `hang_height` above that floor, the rope running up
## `rope_length` from its top.

@export var hang_height := 64.0
@export var rope_length := 96.0
## Seconds to fade out where it lies and back in on its rope.
@export var return_time := 0.5

var _rest := Transform2D.IDENTITY
## The fade back to the rope, killed if another pulse lets it go mid-fade -
## left running, it would hang the load back up under a pulse still lit.
var _return: Tween
# Whether it hangs from its rope, and whether a rider put its return off.
var _on_rope := true
var _return_put_off := false

@onready var _releasable: Releasable = $Releasable
@onready var _rope: Line2D = $Rope
@onready var _rider_sensor: Area2D = $RiderSensor

func _ready() -> void:
	# It moves or goes away: never a place to be sent back to.
	add_to_group(SafeGroundTracker.UNSAFE)
	position.y -= hang_height + _half_height()
	_rest = global_transform
	freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
	freeze = true
	_rope.points = PackedVector2Array([Vector2(0, -_half_height()), Vector2(0, -_half_height() - rope_length)])
	_releasable.released.connect(_on_released)
	_releasable.restored.connect(_on_restored)
	_rider_sensor.body_entered.connect(_on_rider_entered)
	_rider_sensor.body_exited.connect(_on_rider_exited)

func is_released() -> bool:
	return _releasable.is_released()

func _on_released() -> void:
	_on_rope = false
	_return_put_off = false
	if _return:
		_return.kill()
		modulate.a = 1.0
	_rope.visible = false
	freeze = false
	sleeping = false

## A rider landing while it fades back to its rope puts the return off until
## they step off: the grey never pulls the floor from under someone.
func _on_rider_entered(body: Node2D) -> void:
	if not body is Player:
		return
	_releasable.hold()
	if _return and _return.is_running() and not _on_rope:
		_return.kill()
		modulate.a = 1.0
		_return_put_off = true

func _on_rider_exited(body: Node2D) -> void:
	if not body is Player:
		return
	_releasable.let_go()
	if _return_put_off:
		_return_put_off = false
		_on_restored()

func _on_restored() -> void:
	_return = create_tween()
	_return.tween_property(self, "modulate:a", 0.0, return_time * 0.5)
	_return.tween_callback(_back_on_the_rope)
	_return.tween_property(self, "modulate:a", 1.0, return_time * 0.5)

func _back_on_the_rope() -> void:
	_on_rope = true
	freeze = true
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	global_transform = _rest
	_rope.visible = true

func _half_height() -> float:
	return ($CollisionShape2D as CollisionShape2D).shape.get_rect().size.y * 0.5
