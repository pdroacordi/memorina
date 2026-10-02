class_name MemoryField extends Node

## Provides world memory samples and source lists; see docs/knowledge/systems/greyhush.md.

const GROUP := "memory_field"
const MAX_SHIELDS := 8
## Maximum memory sources supported by the shader uniform array.
const MAX_SOURCES := 32

## Baseline memory, 0..1; see docs/design/03_mundo_e_ambiente.md section 4.1.
@export_range(0.0, 1.0) var baseline: float = 1.0
## Region season used where no pulse overrides it.
var season: Enums.Season = Enums.Season.SPRING
## Season palette; see docs/design/03_mundo_e_ambiente.md section 5.2.
var palette: SeasonPalette

var _sources: Array[MemorySource] = []
## Render-only shields; keep separate from `_sources` so they never affect `sample()`.
var _shields: Array[GreyhushShield] = []

## Finds the scene's memory field.
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

## Memory at a world point, 0..1; `exclude` omits one source.
func sample(global_point: Vector2, exclude: MemorySource = null) -> float:
	var influences := PackedFloat32Array()
	for source: MemorySource in _sources:
		if source == exclude or not source.is_visible_in_tree():
			continue
		influences.append(source.influence_at(global_point))
	return MemoryFieldMath.combine(baseline, influences)

## Visible sources whose influence discs intersect `world_rect`.
func sources_intersecting(world_rect: Rect2) -> Array[MemorySource]:
	var result: Array[MemorySource] = []
	for source: MemorySource in _sources:
		if not source.is_visible_in_tree():
			continue
		if world_rect.grow(source.reach()).has_point(source.global_position):
			result.append(source)
	return result
