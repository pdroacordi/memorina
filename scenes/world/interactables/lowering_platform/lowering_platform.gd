class_name LoweringPlatform extends AnimatableBody2D

## A platform on a braked rope: Soltar frees the brake and it lowers swinging, no footing until it stops or roots seize it (design 02 sections 7.1 and 8.4, Combinado 3).

## Group RootGrower looks in for things its roots can seize.
const GROUP := &"root_catchable"
## Radius of the brake's release receiver at the hanger, px: Soltar's disc must reach this far around it.
const BRAKE_RADIUS := 24.0
## Rope drawn above where it hangs, px.
const ROPE_ABOVE := 32.0

## Width in 32 px map cells.
@export var width_cells := 3
## Height of its top above the floor of the cell it is placed on, px.
@export var hang_height := 160.0
## Farthest it lowers, px below where it hangs.
@export var drop := 320.0
## Lowering speed with the brake off, px/s.
@export var lower_speed := 35.0
## Speed it is winched back up when the grey returns, px/s.
@export var return_speed := 80.0
## Widest swing while it moves, degrees.
@export var swing_degrees := 14.0
## Swings a second while it moves.
@export var swing_rate := 0.8

var _top_y := 0.0
# Its world y, kept here: with sync_to_physics a position write lands only on the next step (gotchas/sync-to-physics-lands-a-move-next-step).
var _y := 0.0
var _released := false
var _seized_by: Array[Object] = []
var _swing_clock := 0.0
var _solid := true

@onready var _releasable: Releasable = $Releasable
@onready var _shape: CollisionShape2D = $CollisionShape2D
@onready var _sprite: Sprite2D = $Sprite2D
@onready var _rope: Line2D = $Rope
@onready var _brake: Area2D = $ReleaseReceiver
@onready var _rider_sensor: Area2D = $RiderSensor

func _ready() -> void:
	add_to_group(GROUP)
	# A moving platform is not a valid return location.
	add_to_group(SafeGroundTracker.UNSAFE)
	# Computed, not read back: AnimatableBody2D syncs to physics by default, so a write lands next step.
	_top_y = global_position.y - hang_height
	_y = _top_y
	global_position.y = _top_y
	var width := width_cells * float(RoomMapNode.FLOOR_TILESET.tile_size.x)
	var box := RectangleShape2D.new()
	box.size = Vector2(width, 10)
	_shape.shape = box
	_shape.position = Vector2(0, 5)
	_sprite.region_rect = Rect2(0, 0, width, 12)
	_sprite.position = Vector2(0, 6)
	# The brake stays on the hanger: the platform lowering out of Soltar's disc does not give it back.
	var brake := CircleShape2D.new()
	brake.radius = BRAKE_RADIUS
	(_brake.get_node("CollisionShape2D") as CollisionShape2D).shape = brake
	var rider := RectangleShape2D.new()
	rider.size = Vector2(width, 8)
	var rider_shape := _rider_sensor.get_node("CollisionShape2D") as CollisionShape2D
	rider_shape.shape = rider
	rider_shape.position = Vector2(0, -4)
	# The grey waits to winch it up while Ivo stands on it, as for every Soltar thing.
	_rider_sensor.body_entered.connect(func(body: Node2D) -> void: if body is Player: _releasable.hold())
	_rider_sensor.body_exited.connect(func(body: Node2D) -> void: if body is Player: _releasable.let_go())
	_brake.top_level = true
	_brake.global_position = Vector2(global_position.x, _top_y)
	_releasable.released.connect(func() -> void: _released = true)
	_releasable.restored.connect(func() -> void: _released = false)
	_draw_rope()

func _physics_process(delta: float) -> void:
	var moving := false
	if _seized_by.is_empty():
		var target := _top_y + drop if _released else _top_y
		var speed := lower_speed if _released else return_speed
		var y := move_toward(_y, target, speed * delta)
		moving = not is_equal_approx(y, _y)
		if moving:
			_y = y
			global_position.y = roundf(_y)
			_draw_rope()
	_swing(delta, moving)
	# Footing only while it is still: a swinging plank cannot be ridden past the exit.
	if _solid == moving:
		_solid = not moving
		_shape.set_deferred(&"disabled", moving)

## Roots hold it where it is until every root that seized it lets go.
func seize(by: Object) -> void:
	if not by in _seized_by:
		_seized_by.append(by)

func let_go(by: Object) -> void:
	_seized_by.erase(by)

## World points at mid-height of its left and right edges, where roots take hold.
func catch_edges() -> PackedVector2Array:
	var half := width_cells * float(RoomMapNode.FLOOR_TILESET.tile_size.x) * 0.5
	var at := Vector2(global_position.x, roundf(_y))
	return PackedVector2Array([at + Vector2(-half, 5), at + Vector2(half, 5)])

func _swing(delta: float, moving: bool) -> void:
	if moving:
		_swing_clock += delta
		_sprite.rotation = deg_to_rad(swing_degrees) * sin(TAU * swing_rate * _swing_clock)
	else:
		_swing_clock = 0.0
		_sprite.rotation = move_toward(_sprite.rotation, 0.0, deg_to_rad(swing_degrees) * 4.0 * delta)

func _draw_rope() -> void:
	_rope.points = PackedVector2Array([Vector2.ZERO, Vector2(0, _top_y - roundf(_y) - ROPE_ABOVE)])
