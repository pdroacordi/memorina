class_name MemoryClock extends Node

## Runs its neighbour's clock at whatever rate the memory field allows here.
##
## This is the other half of the greyhush, and the more important one: a place
## the cinzesquecimento has taken is not merely colourless, it is STOPPED. See
## docs/design/03_mundo_e_ambiente.md section 2 - a branch caught mid-sway
## stays caught mid-sway, and resumes from exactly there when colour returns.
## Lowering an animation's amplitude would be the wrong thing entirely: that
## still leaves a cycle running.
##
## Environment only. Characters are never slowed - the player must stay
## responsive inside a dead zone, and an enemy frozen solid would be a combat
## mechanic nobody designed. _ready() asserts that.

## The node whose speed_scale is driven. Empty means the parent.
##
## A NodePath resolved in code, not an exported Node: a hand-written NodePath in
## a .tscn does not convert into an exported Node reference, it silently leaves
## the property null. That cost a whole verification pass here - the clock
## computed the right rate while driving nothing at all.
##
## Duck-typed rather than adapted per class: AnimatedSprite2D, AnimationPlayer,
## GPUParticles2D and CPUParticles2D all spell it the same way.
@export var target_path: NodePath

var target: Node

## Below this, the clock snaps to a dead stop instead of crawling. Without it a
## "stopped" area would still creep forward over a long visit.
@export_range(0.0, 1.0) var stop_threshold: float = 0.05

## How fast this spot's time is running, 0..1. Read-only.
var rate: float = 0.0
## Seconds of local time elapsed. A surface animated by a shader reads this
## instead of TIME so that it freezes and resumes with everything else.
var time: float = 0.0

var _field: MemoryField
var _anchor: Node2D

func _ready() -> void:
	target = get_node_or_null(target_path) if not target_path.is_empty() else get_parent()
	assert(target != null, "MemoryClock.target_path does not resolve: %s" % target_path)
	# Without this the clock ticks correctly and drives nothing, which reads
	# exactly like working code.
	assert("speed_scale" in target,
		"MemoryClock target '%s' has no speed_scale; it would be driven into the void." % target.name)
	assert(not _is_character(target), "MemoryClock must never drive a Character: the greyhush stops the world, not the people in it.")
	_field = MemoryField.find_in(self)
	_anchor = _find_anchor()
	assert(_anchor != null, "MemoryClock needs a Node2D ancestor to sample the field at.")

func _physics_process(delta: float) -> void:
	if _field == null:
		return
	rate = _field.sample(_anchor.global_position)
	if rate < stop_threshold:
		rate = 0.0
	time += delta * rate
	if "speed_scale" in target:
		target.set("speed_scale", rate)

func _is_character(node: Node) -> bool:
	var walker: Node = node
	while walker != null:
		if walker is Character:
			return true
		walker = walker.get_parent()
	return false

func _find_anchor() -> Node2D:
	var walker: Node = self
	while walker != null:
		if walker is Node2D:
			return walker as Node2D
		walker = walker.get_parent()
	return null
