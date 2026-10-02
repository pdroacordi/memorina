class_name Drawbridge extends Node2D

## Rope-held bridge plank rotates around this node and carries riders (docs/knowledge/systems/weight-presence-release.md).

## Bridge length in 32 px map cells.
@export var length_cells := 4
## Fall direction: 1 right of hinge, -1 left.
@export var side := 1
## Time for the bridge to rotate between raised and lowered positions, in seconds.
@export var fall_time := 0.45

@onready var _releasable: Releasable = $Releasable
@onready var _plank: AnimatableBody2D = $Plank
@onready var _plank_shape: CollisionShape2D = $Plank/CollisionShape2D
@onready var _plank_sprite: Sprite2D = $Plank/Sprite2D
@onready var _rider_sensor: Area2D = $Plank/RiderSensor
@onready var _rider_shape: CollisionShape2D = $Plank/RiderSensor/CollisionShape2D
@onready var _receiver_shape: CollisionShape2D = $ReleaseReceiver/CollisionShape2D

var _tween: Tween

func _ready() -> void:
	# A moving bridge cannot be a safe respawn surface.
	_plank.add_to_group(SafeGroundTracker.UNSAFE)
	_plank.sync_to_physics = true
	var length := length_cells * float(RoomMapNode.FLOOR_TILESET.tile_size.x)
	var box := RectangleShape2D.new()
	box.size = Vector2(length, 10)
	_plank_shape.shape = box
	_plank_shape.position = Vector2(length * 0.5 * side, -5)
	_rider_shape.shape = box
	_rider_shape.position = Vector2(length * 0.5 * side, -12)
	_plank_sprite.region_rect = Rect2(0, 0, length, 12)
	_plank_sprite.position = Vector2(length * 0.5 * side, -6)
	var reach := CircleShape2D.new()
	reach.radius = 24.0
	_receiver_shape.shape = reach
	_plank.rotation = _raised()
	_releasable.released.connect(func() -> void: _turn(0.0, true))
	_releasable.restored.connect(func() -> void: _turn(_raised(), false))
	_rider_sensor.body_entered.connect(func(body: Node2D) -> void: if body is Player: _releasable.hold())
	_rider_sensor.body_exited.connect(func(body: Node2D) -> void: if body is Player: _releasable.let_go())

func is_down() -> bool:
	return is_zero_approx(_plank.rotation)

func _raised() -> float:
	return -PI * 0.5 * side

func _turn(angle: float, falling: bool) -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	var step := _tween.tween_property(_plank, "rotation", angle, fall_time)
	step.set_trans(Tween.TRANS_BOUNCE if falling else Tween.TRANS_SINE)
	step.set_ease(Tween.EASE_OUT)
