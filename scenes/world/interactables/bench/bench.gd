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

@onready var _seat: Seat = $Seat
@onready var _prompt: KeyGlyph = $Prompt


func _ready() -> void:
	_seat.bench_id = bench_id
	_seat.facing = facing
	_seat.changed.connect(_refresh_prompt)
	_prompt.show_action(&"look_down")
	_refresh_prompt()

## The key, shown while Ivo stands in reach and is not already sitting. No
## prose: the key is the whole prompt.
func _refresh_prompt() -> void:
	_prompt.visible = _seat.has_body_in_reach() and not _seat.is_occupied()
