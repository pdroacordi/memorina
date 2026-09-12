class_name CombatDisabledZone
extends Area2D
## Persistent proximity gate for safe rooms and NPC vicinities - contrast with
## the one-shot PlayerProximityTrigger. Entering disables combat for as long
## as the player stays inside; exiting re-enables it. Drop directly into a
## safe room, or as a child of an NPC scene, since the mechanism is the same.

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
