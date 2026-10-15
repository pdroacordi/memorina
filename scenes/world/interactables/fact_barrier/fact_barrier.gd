class_name FactBarrier
extends StaticBody2D
## A barrier (a fence, a street grate) that bars the way until the save holds `requires` (design 04 section 2; systems/rooms "Fact grate").

## The save fact that opens it.
@export var requires: SaveFact
## Replaces the scene's own sprite (the gate for FactBarrier, the grate for FactGrate); null keeps it.
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

## Whether its body bars the way for the current save.
func is_closed() -> bool:
	return not is_open_for(SaveSystem.player_data)

## Its body in global coordinates.
func body_rect() -> Rect2:
	var shape := get_node("CollisionShape2D") as CollisionShape2D
	var box := (shape.shape as RectangleShape2D).size * shape.global_scale
	return Rect2(shape.global_position - box * 0.5, box)

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
