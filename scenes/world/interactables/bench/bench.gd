class_name Bench extends Node2D

## Restoration point: resting heals Ivo and saves his return location (design 02, restoration points).

## Required save identifier, unique across maps; checked by room_files_test.
@export var bench_id: StringName = &""
## Which way Ivo faces sitting here: 1 right, -1 left.
@export var facing: int = 1

@export_group("Bloom")
## Memory strength controlled by the region's forgotten amount.
@export_range(0.0, 1.0) var bloom_strength: float = 0.9
@export var bloom_radius: float = 96.0
@export var bloom_tint: Color = Color(1.0, 0.86, 0.62)
@export var bloom_rise: float = 0.5
@export var bloom_hold: float = 0.8
@export var bloom_fall: float = 1.8

var _bloom_tween: Tween

@onready var _seat: Seat = $Seat
@onready var _prompt: KeyGlyph = $Prompt
@onready var _bloom: MemorySource = $Bloom


func _ready() -> void:
	_seat.bench_id = bench_id
	_seat.facing = facing
	_seat.changed.connect(_refresh_prompt)
	_seat.rested.connect(_on_rested)
	_prompt.show_action(&"look_down")
	_refresh_prompt()

func is_blooming() -> bool:
	return _bloom.visible

# Hidden between rests so MemoryField does not sample the source.
func _on_rested() -> void:
	if _bloom_tween != null:
		_bloom_tween.kill()
	_bloom.strength = 0.0
	_bloom.radius = 8.0
	_bloom.ring = 1.0
	_bloom.tint = bloom_tint
	_bloom.show()
	_bloom_tween = create_tween().set_trans(Tween.TRANS_SINE)
	_bloom_tween.set_parallel(true)
	_bloom_tween.tween_property(_bloom, "strength", bloom_strength, bloom_rise).set_ease(Tween.EASE_OUT)
	_bloom_tween.tween_property(_bloom, "radius", bloom_radius, bloom_rise).set_ease(Tween.EASE_OUT)
	_bloom_tween.tween_property(_bloom, "ring", 0.0, bloom_rise + bloom_hold).set_ease(Tween.EASE_IN)
	_bloom_tween.chain().tween_property(_bloom, "strength", 0.0, bloom_fall).set_ease(Tween.EASE_IN)
	_bloom_tween.chain().tween_callback(_bloom.hide)

## The key, shown while Ivo stands in reach and is not already sitting. No
## prose: the key is the whole prompt.
func _refresh_prompt() -> void:
	_prompt.visible = _seat.has_body_in_reach() and not _seat.is_occupied()
