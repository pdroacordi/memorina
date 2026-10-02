class_name Seat extends Area2D

## Where Ivo sits on a bench. Only a PLACE, like Climbable: an area on the
## Interactable layer that a body's SitComponent finds through its own sensor.
## Its origin is where the feet go. It knows which bench it belongs to (the
## save names a bench by its authored id) and watches for Ivo's BODY - never
## his hurtbox, which a roll's i-frames switch off - only so its bench can
## show the prompt while he is in reach.

## The state the prompt reads changed: Ivo came into reach, left it, sat, rose.
signal changed
## A rest was taken here (not merely a seat taken: arriving after a death puts
## Ivo on it without one). The bench answers with its bloom.
signal rested

## The physics layer seats live on (layer 6, "Interactable").
const LAYER := 1 << 5
## Ivo's body (layer 9, "Player").
const PLAYER_BODY := 1 << 8
const GROUP := &"seats"

## The bench's authored id, unique across every map. Pushed by the bench.
var bench_id: StringName = &""
## Which way he faces sitting here: 1 right, -1 left.
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
