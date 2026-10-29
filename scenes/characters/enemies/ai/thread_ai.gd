class_name ThreadAI
extends EnemyAI
## A creature on a silk thread: rests under its anchor, lets itself down toward a target's chest while the target is in
## its column, bites what comes into reach, and climbs back after `linger` s without a target in its column.

## Steer per px off the height or the column it holds, px/s per px.
const HOLD_GAIN := 6.0
## Distance under which it stops steering, px.
const SETTLE := 1.0

## Half-width of the column under it in which a target draws it down, px.
@export var column_half_width: float = 64.0
## Farthest it lets itself down below where it rests, px.
@export var max_drop: float = 256.0
## Speed down the thread, px/s.
@export var descend_speed: float = 140.0
## Speed up the thread, px/s.
@export var climb_speed: float = 80.0
## Time without a target in its column before it climbs back, s.
@export var linger: float = 1.5
## Height of the anchor above where it rests, px: it rests at its placed cell's centre, the anchor at the cell's top.
@export var anchor_height: float = 16.0
## Height of its own chest above its origin, px: the point it lines up with a target's chest.
@export var chest_height: float = 12.0

## Time since a target was last in its column, s.
var _lonely: float = 0.0


## Where its thread is tied, world px.
func anchor() -> Vector2:
	var rest := _home if _awake else _body.global_position
	return rest - Vector2(0.0, anchor_height)

func _away_from_home() -> bool:
	return _body.global_position.distance_to(_home) > HOME_TOLERANCE

func _idle_tick(_delta: float) -> void:
	steer = _toward_height(_home.y)

func _approach_tick(delta: float) -> void:
	if absf(_target.global_position.x - _home.x) > column_half_width:
		_wait_or_climb(delta)
		return
	_lonely = 0.0
	var chest := _target.global_position.y + CHEST.y + chest_height
	steer = _toward_height(clampf(chest, _home.y, _home.y + max_drop))

func _home_tick(delta: float) -> void:
	_wait_or_climb(delta)

func _telegraph_tick(_delta: float) -> void:
	steer = Vector2.ZERO

## The bite reaches: it does not move.
func _active_tick(_delta: float) -> void:
	steer = Vector2.ZERO

func _recover_tick(_delta: float) -> void:
	steer = Vector2.ZERO

func _wait_or_climb(delta: float) -> void:
	_lonely += delta
	steer = _toward_height(_home.y if _lonely >= linger else _body.global_position.y)

## Straight up or down the thread to `y`, swinging back under the anchor after a knock.
func _toward_height(y: float) -> Vector2:
	var offset := Vector2(_home.x, y) - _body.global_position
	if offset.length() < SETTLE:
		return Vector2.ZERO
	return Vector2(clampf(offset.x * HOLD_GAIN, -climb_speed, climb_speed),
			clampf(offset.y * HOLD_GAIN, -climb_speed, descend_speed))
