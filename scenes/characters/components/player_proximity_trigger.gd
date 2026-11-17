class_name PlayerProximityTrigger
extends Area2D
## Emits when the player enters the area, then disables monitoring; with `stays_open` the receiver calls `close()` once
## it acts, so a refused entry fires again on the next one.

signal player_entered

var stays_open: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)

func close() -> void:
	# Area2D monitoring cannot change during its own signal dispatch.
	set_deferred("monitoring", false)

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group(Player.GROUP):
		return
	if not stays_open:
		close()
	player_entered.emit()
