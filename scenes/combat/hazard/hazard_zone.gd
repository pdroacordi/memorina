class_name HazardZone extends Area2D

## Somewhere a body cannot be: water, and later spikes or a drop into nothing.
## It tells the body (Character.receive_hazard), so nothing that stands in the
## world has to know what water is - the body decides what being taken means
## (a Character hurts; Player is also sent back to the last firm ground he stood
## on; a Guardian, never wounded, ignores it).
##
## It detects the BODY, never the Hurtbox. The hurtbox means "can be hit", and
## a roll's or a flinch's i-frames key it unmonitorable - which hid Ivo from the
## water, so he rolled onto the floor of a pool unseen and that floor became his
## safe ground
## (docs/knowledge/bugs/roll-iframes-hide-the-water-so-the-pool-floor-becomes-safe-ground.md).
## Being in water is where a body IS, not whether it can be hit.
## It also sits on the Hazard physics layer, so SafeGroundTracker can refuse
## any spot inside it.

## Health a body loses each time it falls in.
@export var damage := 1

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body is Character:
		(body as Character).receive_hazard(self)
