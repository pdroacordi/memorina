class_name LifeHud extends Control

## Displays Player.health_changed as LifeNotes; see docs/design/02_mecanicas.md section Vida.

const NOTE := preload("res://scenes/ui/life_hud/life_note.tscn")

## Phase spacing in frames between neighbouring notes.
@export var phase_step: float = 2.0
## Real seconds between successive note refills.
@export var refill_step: float = 0.18

## False until the initial health update, which is shown without animation.
var _shown: bool = false

@onready var _row: HBoxContainer = $Row


func show_health(current: int, max_hp: int) -> void:
	var instant := not _shown
	_shown = true
	_fit(max_hp)
	var regained := 0
	for i: int in _row.get_child_count():
		var note := _row.get_child(i) as LifeNote
		if i < current and not instant and not note.is_remembered():
			note.regain(regained * refill_step)
			regained += 1
		else:
			note.remember(i < current, instant)

## Returns notes in display order.
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
