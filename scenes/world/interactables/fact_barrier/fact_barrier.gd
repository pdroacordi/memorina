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

func _refresh() -> void:
	var open := is_open_for(SaveSystem.player_data)
	# Deferred: progress can change inside a physics callback.
	_shape.set_deferred(&"disabled", open)
	visible = not open
