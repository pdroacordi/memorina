class_name AirflowBody extends Node

## Lets the air move the body it is a child of. Each physics frame it asks the
## Airflow how the air moves at the body and hands that on:
##   - a Character gets it as carry (Character.push), which its own motion
##     steers toward - so the body decides what wind means to it;
##   - a RigidBody2D is dragged toward the wind's velocity along the wind.
## Runs before its body (process_physics_priority), so the carry is ready when
## the body moves - no frame of lag.
##
## `exposure` is the body's judgement, pushed in the way `enabled` gates an
## ability: Ivo is half sheltered while the instrument is out (design 03
## section 5.4, item 2).

## Where on the body the air is sampled, from its origin (the feet).
@export var sample_offset := Vector2(0, -28)
## How hard a RigidBody2D is dragged toward the wind's velocity, per second.
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
