class_name AirflowSource extends Node2D

## Something that moves the air: a natural current (WindZone), a song's gale
## (the RadialWind under GaleField). Registers with the scene's Airflow while
## it is in the tree; subclasses answer wind_at().

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

## The air this source moves at `global_point`, in px/s, before memory scales
## it. Zero outside the source.
func wind_at(_global_point: Vector2) -> Vector2:
	return Vector2.ZERO
