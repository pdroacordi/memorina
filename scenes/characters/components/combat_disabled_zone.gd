class_name CombatDisabledZone
extends Area2D
## Disables combat while the player is inside a safe-room or NPC proximity area.

signal player_entered
signal player_exited


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group(Player.GROUP):
		player_entered.emit()

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group(Player.GROUP):
		player_exited.emit()
