class_name Draft
extends CPUParticles2D
## A faint draft of dust at a secret's mouth, frozen in the grey (architecture/secret-false-walls, "Hints").

## Where the dust drifts: 1 right, -1 left, 0 up.
@export_range(-1, 1) var facing: int = 1:
	set(value):
		facing = value
		_aim()


func _ready() -> void:
	_aim()

func _aim() -> void:
	direction = Vector2(facing, 0.0) if facing != 0 else Vector2.UP
	emission_rect_extents = Vector2(1.0, 12.0) if facing != 0 else Vector2(12.0, 1.0)
