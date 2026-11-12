class_name SongBloom
extends Node
## Grows a MemoryBloom with a song while Ivo walks: as Music plays `song` from `from` to `to` seconds, the RECT widens from
## `size_from` to `size_to` and its strength rises 0..1 (flashback 5's crossing; design drafts/camada_pessoal.md §2, "5").
## It never shrinks while the song plays, and rests when the song stops.

@export var bloom: MemoryBloom
@export var song: MusicCue
## Seconds into `song`.
@export var from: float = 0.0
@export var to: float = 1.0
## Px of the RECT, centred on the bloom's node, at `from` and at `to`.
@export var size_from: Vector2 = Vector2(64.0, 384.0)
@export var size_to: Vector2 = Vector2(2600.0, 900.0)
## The leading ring (0..1) at `from`; 0 at `to`.
@export var ring_from: float = 0.8

## The furthest progress reached, 0..1; -1 at rest.
var _reached: float = -1.0


func _physics_process(_delta: float) -> void:
	if bloom == null:
		return
	var request := Music.playing()
	if request == null or request.cue != song:
		if _reached >= 0.0:
			bloom.reset()
			_reached = -1.0
		return
	var t := maxf(_reached, SongProgress.at(Music.position(), from, to))
	if t == _reached:
		return
	_reached = t
	var eased := smoothstep(0.0, 1.0, t)
	bloom.bloom_to(MemoryFieldMath.Shape.RECT, size_from.lerp(size_to, eased), 0.0, bloom.global_position, eased,
			lerpf(ring_from, 0.0, t), 0.0)

## The furthest progress reached, 0..1; -1 at rest.
func progress() -> float:
	return _reached
