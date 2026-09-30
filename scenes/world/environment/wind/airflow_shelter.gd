class_name AirflowShelter extends Node2D

## A place the air cannot reach, whatever blows around it: the bell jar's
## shell (Redoma), a bench, the lee of a rock (design 03 section 5.4, item 4).
## Registers with the scene's Airflow; subclasses answer covers().

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	var airflow := Airflow.find_in(self)
	if airflow:
		airflow.register_shelter(self)

func _exit_tree() -> void:
	if Engine.is_editor_hint():
		return
	var airflow := Airflow.find_in(self)
	if airflow:
		airflow.unregister_shelter(self)

func covers(_global_point: Vector2) -> bool:
	return false
