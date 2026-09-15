class_name MemoryField extends Node

## The world's memory, queryable at any point. Lives in game.tscn and is found
## by group, the same way DustEmitter finds the Spawner - it is per-game-scene
## state, not application state, so it is not an autoload.
##
## Answers the CPU side only (time-stop, and how fast a pulse dies).
## GreyhushRenderer reads from it to feed the shader; this class never learns
## that a renderer exists.

const GROUP := "memory_field"
const MAX_SHIELDS := 8
## The shader carries a fixed-size uniform array, so the renderer cannot push
## more than this many sources in one frame.
const MAX_SOURCES := 32

## How much of this region is still remembered, before any source. Pushed in by
## Game on room entry; see docs/design/03_mundo_e_ambiente.md section 4.1.
@export_range(0.0, 1.0) var baseline: float = 1.0

var _sources: Array[MemorySource] = []
## Creatures that hold back the grey around themselves. Kept separate from
## _sources on purpose: a shield is a RENDERING concession, and must never
## change what sample() reports, or standing somewhere would thaw the world.
var _shields: Array[GreyhushShield] = []

## Convenience for the several nodes that need the field from anywhere in the
## tree, so the group name is written once.
static func find_in(node: Node) -> MemoryField:
	return node.get_tree().get_first_node_in_group(GROUP) as MemoryField

func _enter_tree() -> void:
	add_to_group(GROUP)

func register(source: MemorySource) -> void:
	if not _sources.has(source):
		_sources.append(source)

func unregister(source: MemorySource) -> void:
	_sources.erase(source)

func register_shield(shield: GreyhushShield) -> void:
	if not _shields.has(shield):
		_shields.append(shield)

func unregister_shield(shield: GreyhushShield) -> void:
	_shields.erase(shield)

func shields() -> Array[GreyhushShield]:
	var result: Array[GreyhushShield] = []
	for shield: GreyhushShield in _shields:
		if shield.is_active():
			result.append(shield)
	return result

## Memory at a world point, 0..1. `exclude` lets a pulse ask what the world
## around it was like without counting its own light.
##
## Hidden sources drop out: Room.deactivate() hides a room's contents, so a
## resident-but-inactive room's patches stop counting with no bookkeeping here.
func sample(global_point: Vector2, exclude: MemorySource = null) -> float:
	var influences := PackedFloat32Array()
	for source: MemorySource in _sources:
		if source == exclude or not source.is_visible_in_tree():
			continue
		influences.append(source.influence_at(global_point))
	return MemoryFieldMath.combine(baseline, influences)

## Every visible source whose disc touches `world_rect`. Used by the renderer
## to cull to what is actually on screen.
func sources_intersecting(world_rect: Rect2) -> Array[MemorySource]:
	var result: Array[MemorySource] = []
	for source: MemorySource in _sources:
		if not source.is_visible_in_tree():
			continue
		if world_rect.grow(source.reach()).has_point(source.global_position):
			result.append(source)
	return result
