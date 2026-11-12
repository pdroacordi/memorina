class_name SongTint
extends Node
## Tints a light overlay with a song: as Music plays `song` from `from` to `to` seconds, the target's `property` moves
## from `rest` to `full` and never back while the song plays (flashback 5's twilight darkening along the lullaby).

@export var target: CanvasItem
## The Color property written: `modulate` on an overlay, `color` on a CanvasModulate.
@export var property: StringName = &"modulate"
@export var song: MusicCue
## Seconds into `song`.
@export var from: float = 0.0
@export var to: float = 1.0
## White leaves a multiply overlay or a CanvasModulate clear; black leaves an additive one clear.
@export var rest: Color = Color.WHITE
@export var full: Color = Color.WHITE

## The furthest progress reached, 0..1.
var _reached: float = 0.0


func _ready() -> void:
	if target != null:
		target.set(property, rest)

func _physics_process(_delta: float) -> void:
	if target == null:
		return
	var request := Music.playing()
	if request == null or request.cue != song:
		return
	_reached = maxf(_reached, SongProgress.at(Music.position(), from, to))
	target.set(property, rest.lerp(full, _reached))

## The furthest progress reached, 0..1.
func progress() -> float:
	return _reached
