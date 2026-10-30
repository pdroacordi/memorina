class_name DialogueBoxSide
extends RefCounted
## Where the dialogue box opens: in the screen half the speakers are not in ("Opposite the speakers (Recommended)",
## user, 2026-10-15), and never over a tall speaker's face ("Caixa pela cabeça", user, 2026-10-30; systems/dialogue).

enum Side { TOP, BOTTOM }


## The Side opposite the speakers' mean screen y; at or below the middle (the usual low floor) is the top. Returns an
## int: a `-> Side` return failed to parse once other scripts typed `DialogueBoxSide.Side`
## (gotchas/a-static-func-returning-its-own-enum-fails-once-another-script-types-it).
static func opposite(speaker_ys: PackedFloat32Array, screen_height: float) -> int:
	if speaker_ys.is_empty():
		return Side.TOP
	var total := 0.0
	for y: float in speaker_ys:
		total += y
	return Side.BOTTOM if total / speaker_ys.size() < screen_height * 0.5 else Side.TOP


## The Side for a talk: the bottom when the top box would cover the speaker's face (`face_y` above `top_box_bottom`),
## otherwise `opposite`. A NAN `face_y` is no face. Returns an int, as `opposite`.
static func place(speaker_ys: PackedFloat32Array, screen_height: float, face_y: float = NAN,
		top_box_bottom: float = 0.0) -> int:
	if face_y < top_box_bottom:
		return Side.BOTTOM
	return opposite(speaker_ys, screen_height)
