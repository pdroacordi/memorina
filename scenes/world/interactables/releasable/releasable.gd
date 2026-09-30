class_name Releasable extends Node

## Makes its parent something Soltar (Enums.Song.RELEASE) lets go of: a load
## on a rope, a counterweight, a drawbridge, a curtain of leaves. It turns a
## SongReceiver sibling into two signals, `released` and `restored`, following
## ReleaseState - the grey gives the old state back when the pulse has gone,
## held back while something holds the released thing (hold / let_go).
## What "let go" means is the parent's business; this only decides when.

signal released
signal restored

@export var receiver_path: NodePath = ^"../ReleaseReceiver"

var _state := ReleaseState.new()

@onready var _receiver: SongReceiver = get_node(receiver_path)

func _ready() -> void:
	assert(_receiver.reacts_to == Enums.Song.RELEASE, "%s: a Releasable listens for RELEASE" % get_parent().name)
	_receiver.song_entered.connect(func(_song: Song, _origin: Vector2) -> void: _emit(_state.lit()))
	_receiver.song_left.connect(func(_song: Song) -> void: _emit(_state.unlit(_receiver.is_lit())))

func is_released() -> bool:
	return _state.is_released()

## Something is holding the released thing; it will not return until let go.
func hold() -> void:
	_state.hold()

func let_go() -> void:
	_emit(_state.let_go())

func _emit(event: ReleaseState.Event) -> void:
	match event:
		ReleaseState.Event.RELEASED:
			released.emit()
		ReleaseState.Event.RESTORED:
			restored.emit()
