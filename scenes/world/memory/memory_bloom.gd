class_name MemoryBloom
extends Node2D
## Owns one MemorySource that a scene or a beat grows and shrinks; hidden at rest, like a bench's bloom
## (systems/cutscenes, "CutsceneBloom"). It writes only its own source, so MemoryFieldMath and the shader are untouched.

const GROUP := &"memory_blooms"

## Unique among the cutscene ids of one contents scene.
@export var bloom_id: StringName = &""
## Px of outward edge fade; 0 scales with the source's extent.
@export var feather: float = 0.0
## What the greyhush tints the bloom's area with.
@export var tint: Color = Color.WHITE

var _tween: Tween
var _source: MemorySource


func _enter_tree() -> void:
	add_to_group(GROUP)

func _ready() -> void:
	_source = MemorySource.new()
	_source.name = &"Source"
	_source.show_in_editor = false
	_source.feather = feather
	_source.tint = tint
	add_child(_source)
	reset()

## Moves the source to `centre` (world px), its `shape`, size and `strength` (-1..1), and the leading `ring` (0..1)
## over `seconds` scaled seconds; 0 cuts.
func bloom_to(shape: MemoryFieldMath.Shape, rect_size: Vector2, radius: float, centre: Vector2, strength: float,
		ring: float, seconds: float) -> void:
	_kill()
	_source.shape = shape
	_source.show()
	if seconds <= 0.0:
		_source.global_position = centre
		_source.rect_size = rect_size
		_source.radius = radius
		_source.strength = strength
		_source.ring = ring
		return
	_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_property(_source, ^"global_position", centre, seconds)
	_tween.tween_property(_source, ^"rect_size", rect_size, seconds)
	_tween.tween_property(_source, ^"radius", radius, seconds)
	_tween.tween_property(_source, ^"strength", strength, seconds)
	_tween.tween_property(_source, ^"ring", ring, seconds)

## Hidden, at rest: no contribution to the field.
func reset() -> void:
	_kill()
	_source.hide()
	_source.position = Vector2.ZERO
	_source.rect_size = Vector2.ZERO
	_source.radius = 0.0
	_source.strength = 0.0
	_source.ring = 0.0

func is_blooming() -> bool:
	return _source.visible

func source() -> MemorySource:
	return _source

func _kill() -> void:
	if _tween != null:
		_tween.kill()
		_tween = null
