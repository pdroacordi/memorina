class_name TeacherAnimationResolver
extends AnimationResolver
## One resolver for every teaching creature: the flourish plays through, sing while a phrase sounds, else idle.

const IDLE := &"idle"
const SING := &"sing"
const FLOURISH := &"flourish"

@onready var _teacher: TeachingCreature = get_parent()


func resolve() -> StringName:
	if _teacher.flourish_pending() or driver.holding(FLOURISH):
		return FLOURISH
	if _teacher.is_singing():
		return SING
	return IDLE
