class_name AmbientMotion
extends Node
## Cycles its parent Sprite2D's frames on the memory clock at the prop's own point, so it stops
## mid-gesture in the grey and resumes from there (architecture/props-and-ambient-life).

## Frames per second at memory 1.
@export var frames_per_second: float = 6.0
## Frame order with holds or ping-pong; empty plays 0..hframes-1.
@export var sequence: PackedInt32Array = PackedInt32Array()
## 0..1 of a loop; negative derives it from the prop's position.
@export var phase: float = -1.0
## Local px where the memory is read (a flag's cloth, not its pole).
@export var sample_offset: Vector2 = Vector2.ZERO
## Memory (0..1) below which the cycle stops: "Stop below 0.2 memory" (user, 2026-10-09).
@export_range(0.0, 1.0) var stop_threshold: float = AmbientMath.STOP_THRESHOLD

var _time: float = 0.0
var _field: MemoryField
var _sprite: Sprite2D


func _ready() -> void:
	_sprite = get_parent() as Sprite2D
	assert(_sprite != null, "AmbientMotion must be the child of a Sprite2D.")
	assert(not _under_character(), "AmbientMotion must never drive a Character: the greyhush stops the world, not the people in it.")
	# Explicit: a parent ForegroundPiece is ALWAYS, and a prop must still stop under a performance. An explicit mode
	# also escapes a deactivated room's DISABLED; the visibility gate below holds those props (gotchas/an-explicit-process-mode-escapes-a-disabled-ancestor).
	process_mode = Node.PROCESS_MODE_PAUSABLE
	_field = MemoryField.find_in(self)
	if phase < 0.0:
		phase = AmbientMath.phase_for(_sprite.global_position)
	_apply()

func _physics_process(delta: float) -> void:
	if not _sprite.is_visible_in_tree() or not _on_screen():
		return
	var memory := 1.0 if _field == null else _field.sample(_sprite.to_global(sample_offset))
	_time = AmbientMath.advance(_time, delta, memory, stop_threshold)
	_apply()

func _apply() -> void:
	var frame := AmbientMath.frame_at(_time, frames_per_second, _sprite.hframes, phase, sequence)
	if frame != _sprite.frame:
		_sprite.frame = frame

func _on_screen() -> bool:
	var view := _sprite.get_canvas_transform().affine_inverse() * _sprite.get_viewport_rect()
	return view.intersects(_sprite.get_global_transform() * _sprite.get_rect())

func _under_character() -> bool:
	var at := get_parent()
	while at != null:
		if at is Character:
			return true
		at = at.get_parent()
	return false
