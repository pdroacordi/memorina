class_name Seat extends Area2D

## Bench seat interaction area; it tracks the player's body to show the reach prompt.

## Emitted when reach or occupancy state changes.
signal changed
## Emitted when the player rests here.
signal rested

## Interactable collision layer (layer 6).
const LAYER := 1 << 5
## Player body collision layer (layer 9).
const PLAYER_BODY := 1 << 8
const GROUP := &"seats"

## Authored bench ID, unique across maps.
var bench_id: StringName = &""
## Facing direction: 1 right, -1 left.
var facing: int = 1

var _occupied: bool = false
var _bodies: int = 0


func _init() -> void:
	collision_layer = LAYER
	collision_mask = PLAYER_BODY
	monitorable = true
	monitoring = true

## The seat of the bench with this id, if its room is loaded.
static func find(tree: SceneTree, id: StringName) -> Seat:
	for node: Node in tree.get_nodes_in_group(GROUP):
		var seat := node as Seat
		if seat != null and seat.bench_id == id:
			return seat
	return null

func _enter_tree() -> void:
	add_to_group(GROUP)

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func set_occupied(occupied: bool) -> void:
	if occupied == _occupied:
		return
	_occupied = occupied
	changed.emit()

## Called by whoever carries the rest out (the composition root).
func rest() -> void:
	rested.emit()

func is_occupied() -> bool:
	return _occupied

func has_body_in_reach() -> bool:
	return _bodies > 0

func _on_body_entered(_body: Node2D) -> void:
	_bodies += 1
	changed.emit()

func _on_body_exited(_body: Node2D) -> void:
	_bodies = maxi(_bodies - 1, 0)
	changed.emit()
