class_name HazardZone extends Area2D

## Somewhere a body cannot be: water, and later spikes or a drop into nothing.
## It reaches bodies through their Hurtbox, the same contract a Hitbox uses,
## so nothing that stands in the world has to know what water is - the body
## decides what being taken means (Character: it hurts; Player: it also sends
## him back to the last firm ground he stood on).

## Health a body loses each time it falls in.
@export var damage := 1

func _ready() -> void:
	area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area2D) -> void:
	if area is Hurtbox:
		(area as Hurtbox).receive_hazard(self)
