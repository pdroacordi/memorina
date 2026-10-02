class_name Bench extends Node2D

## A restoration point (design 02, "Pontos de restauração"): sitting on it
## heals Ivo, brings the region's creatures back and saves - the only save
## there is (the user's decisions, 2026-10-01) - and a death brings him back
## here, seated. It is full shelter from the wind (design 03 section 5.4,
## item 4), so the pause it asks for is a quiet one.
##
## Placed from a room map (legend `R`) with a `bench_id` that is unique across
## every map: the save names where Ivo comes back by it. The bench itself does
## nothing on a rest; it is a place. Ivo's body decides when he sits, and the
## composition root does the healing and the saving.

## The authored id the save remembers this bench by. Required, unique across
## every map (room_files_test checks both).
@export var bench_id: StringName = &""
## Which way Ivo faces sitting here: 1 right, -1 left.
@export var facing: int = 1

@export_group("Bloom")
## A rest lights the place: remembered colour swells around the bench and
## fades - the place remembers him. A memory source, so it reads as strongly
## as the place is forgotten, and not at all where it is already whole.
@export_range(0.0, 1.0) var bloom_strength: float = 0.9
## It opens like a small colour pulse - the vocabulary the player already
## reads as "colour comes back here": from a point to this radius, its
## stippled leading ring bright as it opens and fading as it settles.
@export var bloom_radius: float = 96.0
## Warm, the gold of the life notes refilling beside it.
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

# Hidden between rests: a source that is not visible is not sampled, so a
# bench costs the field nothing until it blooms.
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
