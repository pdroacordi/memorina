class_name LifeHud extends Control

## Ivo's life, always on screen (design 02, "Vida"): one LifeNote per unit, in
## colour while he has it, grey and still once lost - the rightmost forgets
## first. It only draws what Player.health_changed tells it; it never reads
## Health. No text: a life the player reads by colour carries no translation.
##
## PROCESS_MODE_ALWAYS and the last child of the CanvasLayer, over the fade and
## the letterbox, because "always visible" means through a lesson and a death.

const NOTE := preload("res://scenes/ui/life_hud/life_note.tscn")

## How many frames apart neighbouring notes sway, so the row breathes rather
## than marches.
@export var phase_step: float = 2.0

## False until the first pool arrives: that one is shown, not animated.
var _shown: bool = false

@onready var _row: HBoxContainer = $Row


func show_health(current: int, max_hp: int) -> void:
	var instant := not _shown
	_shown = true
	_fit(max_hp)
	for i: int in _row.get_child_count():
		(_row.get_child(i) as LifeNote).remember(i < current, instant)

## The notes, left to right.
func notes() -> Array[LifeNote]:
	var result: Array[LifeNote] = []
	for child: Node in _row.get_children():
		result.append(child as LifeNote)
	return result

func _fit(count: int) -> void:
	while _row.get_child_count() < count:
		var note := NOTE.instantiate() as LifeNote
		note.phase = _row.get_child_count() * phase_step
		_row.add_child(note)
	while _row.get_child_count() > count:
		var last := _row.get_child(_row.get_child_count() - 1)
		_row.remove_child(last)
		last.queue_free()
