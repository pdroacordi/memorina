class_name LifeHud extends Control

## Displays Player.health_changed as LifeNotes; see docs/design/02_mecanicas.md section Vida.

const NOTE := preload("res://scenes/ui/life_hud/life_note.tscn")

## Phase spacing in frames between neighbouring notes.
@export var phase_step: float = 2.0
## Real seconds between successive note refills.
@export var refill_step: float = 0.18
## Scaled seconds the notes take to fade out when a flashback's visit, the ending or a `hud_hidden` scene begins, and
## back after the ending or the scene.
@export var visit_fade: float = 1.5

## False until the initial health update, which is shown without animation.
var _shown: bool = false
var _fade: Tween
## The playing scene faded the notes (`Cutscene.hud_hidden`).
var _scene_hid: bool = false

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

## Wired from `Game.room_changed`: hidden in the past ("Esconder no passado", architecture/story-05-playable-flashbacks).
func on_room_changed(room: Room) -> void:
	_stop_fade()
	_scene_hid = false
	modulate.a = 1.0
	visible = not room.is_past()

## Wired from `FlashbackDirector.visit_began`: the notes fade before the travel, so a hidden swap into the past shows no
## change (flashback 5).
func on_visit_began(_flashback: Flashback) -> void:
	_fade_to(0.0)

## Wired from `CutsceneDirector.scene_began`: a scene with `hud_hidden` fades the notes, as the ending does.
func on_scene_began(scene: Cutscene) -> void:
	if scene != null and scene.hud_hidden:
		_scene_hid = true
		_fade_to(0.0)

## Wired from `CutsceneDirector.scene_ended`: the notes a scene faded come back over the same time.
func on_scene_ended(_scene: Cutscene) -> void:
	if _scene_hid:
		_scene_hid = false
		_fade_to(1.0)

## Wired from `EpilogueDirector.ending_began`: the notes fade for the ending, as for a visit.
func on_ending_began() -> void:
	_fade_to(0.0)

## Wired from `EpilogueDirector.ending_ended`: the notes come back over the same time.
func on_ending_ended() -> void:
	_fade_to(1.0)

## Returns notes in display order.
func notes() -> Array[LifeNote]:
	var result: Array[LifeNote] = []
	for child: Node in _row.get_children():
		result.append(child as LifeNote)
	return result

func _fade_to(alpha: float) -> void:
	_stop_fade()
	_fade = create_tween()
	_fade.tween_property(self, ^"modulate:a", alpha, visit_fade)

func _stop_fade() -> void:
	if _fade != null:
		_fade.kill()
		_fade = null

func _fit(count: int) -> void:
	while _row.get_child_count() < count:
		var note := NOTE.instantiate() as LifeNote
		note.phase = _row.get_child_count() * phase_step
		_row.add_child(note)
	while _row.get_child_count() > count:
		var last := _row.get_child(_row.get_child_count() - 1)
		_row.remove_child(last)
		last.queue_free()
