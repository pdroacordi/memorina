class_name MemoryClock extends Node

## Drives environmental animation time from the memory field (docs/design/03_mundo_e_ambiente.md section 2).

## Node whose `speed_scale` is driven; empty uses the parent.
## Keep a NodePath: scene-authored Node references do not resolve reliably from exports.
@export var target_path: NodePath

var target: Node

## Rates below this threshold stop instead of crawling.
@export_range(0.0, 1.0) var stop_threshold: float = 0.05

## How fast this spot's time is running, 0..1. Read-only.
var rate: float = 0.0
## Elapsed local seconds; shaders use this instead of TIME to freeze and resume with the world.
var time: float = 0.0

var _field: MemoryField
var _anchor: Node2D

func _ready() -> void:
	target = get_node_or_null(target_path) if not target_path.is_empty() else get_parent()
	assert(target != null, "MemoryClock.target_path does not resolve: %s" % target_path)
	# Catch valid clocks with unresolved or unsupported targets at setup.
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
