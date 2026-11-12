class_name FlashbackSwap
extends Area2D
## Where a flashback's travel into the past is hidden (flashback 5): the twin room shows the same picture at the same
## room-relative pixel, so Ivo standing inside crosses with no cover; outside it the flashback's own entry plays
## (architecture/story-05-playable-flashbacks).

const GROUP := &"flashback_swaps"
## Player body collision layer (layer 9).
const PLAYER_BODY := 1 << 8

## The flashback whose travel it hides.
@export var number: int = 5


func _init() -> void:
	collision_layer = 0
	collision_mask = PLAYER_BODY
	monitorable = false
	monitoring = true

func _enter_tree() -> void:
	add_to_group(GROUP)

## The swap of flashback `number` in `room`'s contents, or null.
static func in_room(room: Room, number: int) -> FlashbackSwap:
	var contents := room.contents() if room != null else null
	if contents == null or not contents.is_inside_tree():
		return null
	for node: Node in contents.get_tree().get_nodes_in_group(GROUP):
		var swap := node as FlashbackSwap
		if swap != null and swap.number == number and contents.is_ancestor_of(swap):
			return swap
	return null

func holds(body: Node2D) -> bool:
	return is_inside_tree() and overlaps_body(body)
