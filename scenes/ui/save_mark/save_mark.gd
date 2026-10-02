class_name SaveMark extends TextureRect

## Displays a brief glow when SaveSystem emits `saved`; its scene uses PROCESS_MODE_ALWAYS.

@export var fade_in: float = 0.25
@export var hold: float = 1.2
@export var fade_out: float = 0.8
## How bright the quill burns at the height of its glow (modulate above 1).
@export var glow: Color = Color(1.7, 1.55, 1.2)

var _tween: Tween


func _ready() -> void:
	modulate = Color(1, 1, 1, 0)
	SaveSystem.saved.connect(show_kept)

func show_kept() -> void:
	if _tween != null:
		_tween.kill()
	modulate = Color(1, 1, 1, 0)
	_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_trans(Tween.TRANS_SINE)
	_tween.tween_property(self, "modulate", Color(glow, 1.0), fade_in).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "modulate", Color(1, 1, 1, 1), hold * 0.5)
	_tween.tween_interval(hold * 0.5)
	_tween.tween_property(self, "modulate:a", 0.0, fade_out).set_ease(Tween.EASE_IN)

func is_showing() -> bool:
	return modulate.a > 0.0
