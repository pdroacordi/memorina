class_name HazardZone extends Area2D

## Reports hazard overlap to Character.receive_hazard; detects bodies so i-frames cannot hide them. See docs/knowledge/bugs/roll-iframes-hide-the-water-so-the-pool-floor-becomes-safe-ground.md.

## Deferred exit checks allow overlap shapes to rebuild without retriggering a body still inside.

## Health lost per hazard entry.
@export var damage := 1

var _inside: Array[Node2D] = []

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if _inside.has(body):
		return
	_inside.append(body)
	if body is Character:
		(body as Character).receive_hazard(self)

func _on_body_exited(body: Node2D) -> void:
	_forget.call_deferred(body)

func _forget(body: Node2D) -> void:
	if not is_instance_valid(body) or not overlaps_body(body):
		_inside.erase(body)
