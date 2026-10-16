class_name EmoteBubble
extends Node2D
## A word-less bubble over a head ("…", "♪", "!"), drawn in the world so it greys with the place ("default, 2026-10-16").
## It follows its target on the pausable clock and frees itself after its scaled seconds.

const PAPER := Color(0.96, 0.9, 0.72)
const INK := Color(0.32, 0.2, 0.25)
## Px of one art pixel (the world's 2x density).
const PX := 2.0
## Art px of the bubble.
const SIZE := Vector2(9.0, 6.0)

var emote: CutsceneEmote.Emote = CutsceneEmote.Emote.ELLIPSIS
var _target: Node2D
## Px above the target's feet.
var _height: float = 0.0
var _left: float = 0.0


func _physics_process(delta: float) -> void:
	_left -= delta
	if _left <= 0.0 or not is_instance_valid(_target):
		queue_free()
		return
	_follow()

func _draw() -> void:
	var body := Rect2(Vector2(-SIZE.x * 0.5, -SIZE.y - 2.0) * PX, SIZE * PX)
	draw_rect(body.grow_individual(-PX, 0.0, -PX, 0.0), PAPER)
	draw_rect(body.grow_individual(0.0, -PX, 0.0, -PX), PAPER)
	draw_rect(Rect2(Vector2(-PX, -2.0 * PX), Vector2(PX, PX)), PAPER)
	draw_rect(Rect2(Vector2(-PX, -PX), Vector2(PX, PX)), PAPER)
	var at := body.position + Vector2(PX, 2.0 * PX)
	match emote:
		CutsceneEmote.Emote.ELLIPSIS:
			for i: int in 3:
				_dot(at + Vector2(PX * (1.0 + i * 2.0), PX))
		CutsceneEmote.Emote.NOTE:
			_dot(at + Vector2(2.0 * PX, 2.0 * PX))
			_dot(at + Vector2(3.0 * PX, 2.0 * PX))
			for y: int in 3:
				_dot(at + Vector2(4.0 * PX, (y - 1.0) * PX))
			_dot(at + Vector2(5.0 * PX, -PX))
		CutsceneEmote.Emote.EXCLAIM:
			for y: int in 2:
				_dot(at + Vector2(3.0 * PX, (y - 1.0) * PX))
			_dot(at + Vector2(3.0 * PX, 2.0 * PX))

## Shows `shown` over `target`'s feet, `height` px up, for `seconds` scaled seconds.
func show_over(target: Node2D, height: float, shown: CutsceneEmote.Emote, seconds: float) -> void:
	_target = target
	_height = height
	emote = shown
	_left = seconds
	_follow()
	queue_redraw()

func _follow() -> void:
	if is_instance_valid(_target):
		global_position = (_target.global_position + Vector2(0.0, -_height)).round()

func _dot(point: Vector2) -> void:
	draw_rect(Rect2(point, Vector2(PX, PX)), INK)
