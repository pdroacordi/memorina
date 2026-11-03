class_name MusicRequest
extends RefCounted
## One node's ask for a cue at a layer; it lasts while its owner is in the tree.

enum Layer { REGION, FIGHT, SCENE, MENU }

var cue: MusicCue
var layer: Layer
var owner: Node
## Order of arrival; the newest wins a tie.
var serial: int = 0
## Stem levels asked while the request lives, 0..1; applied again if it comes back on top.
var levels: Dictionary[StringName, float] = {}


func _init(asked: MusicCue, at: Layer, by: Node) -> void:
	cue = asked
	layer = at
	owner = by

## The owner still exists and is in the tree.
func is_alive() -> bool:
	return is_instance_valid(owner) and owner.is_inside_tree()
