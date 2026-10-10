class_name GrassRun
extends RefCounted
## One row of consecutive grassy tops of one look, in global map cells (architecture/generated-grass).

## The ground cells' row; the walk line is its top edge.
var row := 0
var first := 0
var last := 0
var look := 0
## An end beside air keeps the biome's rounded corner bare; an end against ground, the map edge or a secret is closed.
var open_left := false
var open_right := false


func _init(at_row: int, from: int, to: int, of_look: int, left_open: bool, right_open: bool) -> void:
	row = at_row
	first = from
	last = to
	look = of_look
	open_left = left_open
	open_right = right_open

func cells() -> int:
	return last - first + 1
