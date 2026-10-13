class_name BackdropCut
extends RefCounted
## One straight run of open cut between two rooms' backdrop pictures: on their shared edge, or in the ring's void.

## The two rooms' ids, in alphabetical order.
var rooms: PackedStringArray
## Whether a cell on either side lies in the void around the rooms, shown only by the camera's yield into the ring.
var in_ring: bool
## Whether the line runs up and down (a constant x).
var vertical: bool
## World px of the line, and of the run's ends along it.
var line: float
var from: float
var to: float


func _init(a: String, b: String, ring: bool, upright: bool) -> void:
	rooms = PackedStringArray([a, b] if a < b else [b, a])
	in_ring = ring
	vertical = upright

## "<room>|<room> rooms|ring: x <line>, y <from>..<to>" (or y line, x span): what an allowlist names, so a new cut between
## two listed rooms is a new key.
func key() -> String:
	var across := "x" if vertical else "y"
	var along := "y" if vertical else "x"
	return "%s|%s %s: %s %d, %s %d..%d" % [rooms[0], rooms[1], "ring" if in_ring else "rooms", across, int(line), along, int(from), int(to)]
