class_name NoticeHold
extends RefCounted
## The one test both HUD notices wait on, the notebook quill and the item and intent notice (systems/notices).


## Ivo is in a lesson (its unpaused lead-in included), a talk, a cutscene or a guardian fight where he stands; false
## with no subject. A lesson starts unpaused and freezes later, so the pause alone would let a notice in
## (bugs/the-notebook-quill-shows-through-a-lesson).
static func applies(subject: Player) -> bool:
	return subject != null and subject.is_inside_tree() and (subject.is_in_lesson() or subject.is_in_story()
			or Guardian.fight_at(subject.get_tree(), subject.global_position))
