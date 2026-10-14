class_name FactBarrier
extends StaticBody2D
## A fence that bars the way until the save holds `requires` (design 04 section 2, "ter a Memorina").

## The save fact that opens it.
@export var requires: SaveFact
## Replaces the village gate where another fence fits the place; null keeps the gate.
@export var art: Texture2D

@onready var _shape: CollisionShape2D = $CollisionShape2D
@onready var _sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	if art != null:
		_sprite.texture = art
	SaveSystem.progress_changed.connect(_refresh)
	_refresh()

func is_open_for(data: PlayerData) -> bool:
	return requires != null and requires.holds(data)

## Map cells its closed body fills, placed at `at` (map px), for the reachability audit's kit check. Reads only
## authored values.
func reach_wall_cells(_map: RoomMap, at: Vector2) -> Array[Vector2i]:
	var shape := get_node("CollisionShape2D") as CollisionShape2D
	var box := (shape.shape as RectangleShape2D).size
	return MapCells.box_cells(Rect2(at + shape.position - box * 0.5, box))

## The facts that open it, for the kit check; none when `requires` is unset, which ReachKit.opened_by reads as never.
func reach_needs() -> Array[SaveFact]:
	var facts: Array[SaveFact] = []
	if requires != null:
		facts.append(requires)
	return facts

func _refresh() -> void:
	var open := is_open_for(SaveSystem.player_data)
	# Deferred: progress can change inside a physics callback.
	_shape.set_deferred(&"disabled", open)
	visible = not open
