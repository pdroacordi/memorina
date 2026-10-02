class_name HangingLoad extends RigidBody2D

## A rope-suspended rigid body returns to its anchor when its pulse ends (docs/knowledge/systems/weight-presence-release.md).

## Vertical gap from the supporting floor to the load bottom, in pixels.
@export var hang_height := 64.0
## Rope length above the load, in pixels.
@export var rope_length := 96.0
## Fade duration at each end of the return, in seconds.
@export var return_time := 0.5

var _rest := Transform2D.IDENTITY
## Return tween; cancel it if another pulse releases the load mid-fade.
var _return: Tween
# Whether it hangs from its rope, and whether a rider put its return off.
var _on_rope := true
var _return_put_off := false

@onready var _releasable: Releasable = $Releasable
@onready var _rope: Line2D = $Rope
@onready var _rider_sensor: Area2D = $RiderSensor

func _ready() -> void:
	# A moving load cannot be a safe respawn surface.
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
