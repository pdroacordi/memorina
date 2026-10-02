class_name PlayerProximityTrigger
extends Area2D
## Emits once when the player enters the area, then disables monitoring.

signal player_entered


func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group(Player.GROUP):
		return
	# Area2D monitoring cannot change during its own signal dispatch.
	set_deferred("monitoring", false)
	player_entered.emit()
