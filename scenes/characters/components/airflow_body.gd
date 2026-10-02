class_name AirflowBody extends Node

## Applies sampled airflow to this body; exposure follows design 03 section 5.4, item 2.
## Runs before the body so its carry is ready for that physics step.

## Sample offset in pixels from the body's origin.
@export var sample_offset := Vector2(0, -28)
## RigidBody2D wind drag coefficient per second.
@export var rigid_drag := 3.0

var exposure := 1.0

@onready var _body: Node2D = get_parent()
var _airflow: Airflow

func _ready() -> void:
	process_physics_priority = -1
	_airflow = Airflow.find_in(self)

func _physics_process(_delta: float) -> void:
	if _airflow == null:
		return
	var wind := _airflow.sample(_body.global_position + sample_offset) * exposure
	if wind.is_zero_approx():
		return
	if _body is Character:
		(_body as Character).push(wind)
	elif _body is RigidBody2D:
		var rigid := _body as RigidBody2D
		var along := wind.normalized()
		var slip := wind.length() - rigid.linear_velocity.dot(along)
		if slip > 0.0:
			# A force does not wake a sleeping body: a load that came to rest
			# before the gale arrived would sit through it.
			rigid.sleeping = false
			rigid.apply_central_force(along * slip * rigid.mass * rigid_drag)
