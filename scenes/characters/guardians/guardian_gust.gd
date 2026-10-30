class_name GuardianGust extends Node

## Carries Ivo along the floor, away from its guardian, while a move with `push_speed` swings: a velocity the air
## carries, through Character.push (systems/air). Runs before Ivo, as AirflowBody does.

@onready var _guardian: Guardian = get_parent()


func _ready() -> void:
	process_physics_priority = -1

## The push the guardian's move gives a body at `feet`, in px/s; zero outside the swing, behind it or above `push_height`.
static func push_for(attack: GuardianAttack, swinging: bool, facing: int, origin: Vector2, feet: Vector2) -> Vector2:
	if attack == null or not swinging or attack.push_speed <= 0.0:
		return Vector2.ZERO
	if signf(feet.x - origin.x) != float(facing) or absf(feet.y - origin.y) > attack.push_height:
		return Vector2.ZERO
	return Vector2(facing * attack.push_speed, 0.0)

func is_blowing() -> bool:
	var attack := _guardian.current_attack()
	return attack != null and _guardian.is_swinging() and attack.push_speed > 0.0

func _physics_process(_delta: float) -> void:
	if not is_blowing():
		return
	var ivo := _guardian.fought_player()
	if ivo == null:
		return
	var push := push_for(_guardian.current_attack(), true, _guardian.facing, _guardian.global_position,
			ivo.global_position)
	if push != Vector2.ZERO:
		ivo.push(push)
