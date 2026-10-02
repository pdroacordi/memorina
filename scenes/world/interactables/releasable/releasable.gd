class_name Releasable extends Node

## Applies Soltar state to a parent; see docs/design/02_canções.md section 7.1.
## Signals are deferred because physics-flush callbacks cannot safely change body state.

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

func hold() -> void:
	_state.hold()

func let_go() -> void:
	_emit(_state.let_go())

func _emit(event: ReleaseState.Event) -> void:
	match event:
		ReleaseState.Event.RELEASED:
			released.emit.call_deferred()
		ReleaseState.Event.RESTORED:
			restored.emit.call_deferred()
