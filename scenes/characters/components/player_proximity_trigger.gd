class_name PlayerProximityTrigger
extends Area2D
## Fires once when the player enters this Area2D's CollisionShape2D radius,
## then disables itself. A plain one-shot proximity detector — for anything
## that only needs "the player got close," without the raycast/line-of-sight
## machinery EnemySight adds for chase detection.

signal player_entered


func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group(Player.GROUP):
		return
	# Area2D forbids changing `monitoring` synchronously from inside its own
	# in/out signal dispatch (it's "locked" mid-callback) — must be deferred.
	set_deferred("monitoring", false)
	player_entered.emit()
