class_name AirflowSource extends Node2D

## Registers an air source with the scene's `Airflow`; subclasses implement `wind_at()`.

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	var airflow := Airflow.find_in(self)
	if airflow:
		airflow.register(self)

func _exit_tree() -> void:
	if Engine.is_editor_hint():
		return
	var airflow := Airflow.find_in(self)
	if airflow:
		airflow.unregister(self)

## Returns source wind at a global point in px/s, before memory scaling.
func wind_at(_global_point: Vector2) -> Vector2:
	return Vector2.ZERO
