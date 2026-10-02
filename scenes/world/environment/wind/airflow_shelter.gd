class_name AirflowShelter extends Node2D

## Airflow shelter registered with the scene's Airflow; see docs/knowledge/systems/air.md.

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
