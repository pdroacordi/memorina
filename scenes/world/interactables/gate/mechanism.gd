class_name Mechanism extends AnimatableBody2D

## An AnimatableBody2D that moves `travel` px over `move_time` seconds while its triggers hold.

## The trigger it follows. A bare id in a room map resolves to that entity.
@export var trigger_path: NodePath
## A second trigger that must hold as well (design 02 section 8.4, Combinado 4); empty: the first alone.
@export var second_trigger_path: NodePath
## Trigger that jams movement (design 02 section 8, Outono Logico 1); empty disables jamming.
@export var lock_path: NodePath
## Where it goes when triggered, relative to where it was placed.
@export var travel := Vector2(0, -96)
@export var move_time := 0.6
## Start triggered (a drawbridge that is already down, a lift already up).
@export var start_moved := false

var _rest := Vector2.ZERO
var _progress := 0.0
var _target := 0.0
var _first := false
var _second := true
var _locked := false

func _ready() -> void:
	# Moving mechanisms are not valid return locations.
	add_to_group(SafeGroundTracker.UNSAFE)
	sync_to_physics = true
	_rest = position
	var trigger := get_node_or_null(trigger_path)
	var second := get_node_or_null(second_trigger_path)
	_first = start_moved
	if second:
		_second = start_moved
	_retarget()
	_progress = _target
	_apply()
	if trigger:
		trigger.activated.connect(func() -> void: _set_first(true))
		trigger.deactivated.connect(func() -> void: _set_first(false))
	if second:
		second.activated.connect(func() -> void: _set_second(true))
		second.deactivated.connect(func() -> void: _set_second(false))
	var lock := get_node_or_null(lock_path)
	if lock:
		lock.activated.connect(func() -> void: _set_locked(true))
		lock.deactivated.connect(func() -> void: _set_locked(false))

func is_moved() -> bool:
	return _progress >= 1.0

## Map cells its top passes from rest to `travel`, placed at `at` (map px), as floors for the reachability audit; none
## for a body taller than wide (a gate), a wall the audit assumes open. Reads only authored values.
func reach_cells(_map: RoomMap, at: Vector2) -> Array[Vector2i]:
	var shape := get_node("CollisionShape2D") as CollisionShape2D
	var box := (shape.shape as RectangleShape2D).size
	if box.y >= box.x:
		return []
	var left := at.x + shape.position.x - box.x * 0.5
	var top := at.y + shape.position.y - box.y * 0.5
	var cells: Array[Vector2i] = []
	var steps := ceili(travel.length() / RoomMap.CELL_PX)
	for i: int in steps + 1:
		var moved := travel * (float(i) / maxf(steps, 1))
		for cell: Vector2i in MapCells.floor_cells(left + moved.x, left + moved.x + box.x, top + moved.y, top + moved.y):
			if not cell in cells:
				cells.append(cell)
	return cells

func _physics_process(delta: float) -> void:
	if is_equal_approx(_progress, _target):
		return
	_progress = move_toward(_progress, _target, delta / maxf(move_time, 0.0001))
	_apply()

func _set_first(value: bool) -> void:
	_first = value
	_retarget()

func _set_second(value: bool) -> void:
	_second = value
	_retarget()

func _set_locked(value: bool) -> void:
	_locked = value
	_retarget()

func _retarget() -> void:
	_target = 1.0 if _first and _second and not _locked else 0.0

func _apply() -> void:
	# Ease motion and round positions to whole pixels.
	position = (_rest + travel * smoothstep(0.0, 1.0, _progress)).round()
