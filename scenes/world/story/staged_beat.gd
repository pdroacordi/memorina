class_name StagedBeat
extends DialogueBeat
## A beat that shows and sounds something for `duration` scaled seconds, then gives the talk back (systems/story): stand-ins,
## a sound or a hummed melody, and an optional pulse that acts on nothing, all on the pausable clock.

## FactStaging path to the child it stands in, until that staging's stage changes.
@export var stand_ins: Dictionary[NodePath, StringName] = {}
## The stand-ins give way to their staging's picked stage when the beat ends.
@export var release_stand_ins: bool = false
## Played as the beat starts; null for none.
@export var stream: AudioStream
## Played note by note through a MelodyPlayer child instead of `stream`; null for none.
@export var melody: Melody
## Notes of `melody` played; negative plays them all.
@export var melody_count: int = -1
## One voice per Enums.Note for `melody`.
@export var voices: Array[AudioStream] = []
## The song whose colours a pulse shows; null for no pulse. The pulse never acts (`song_acts` false).
@export var pulse_song: Song
@export var pulse_stats: PulseStats
## Where the pulse opens; empty opens it at this beat's parent.
@export var pulse_at: NodePath
## Scaled seconds before the beat ends; at least the melody's length when there is one.
@export var duration: float = 1.0

var _left: float = 0.0
var _running: bool = false

@onready var _voice: AudioStreamPlayer = _make_voice()
@onready var _melody_player: MelodyPlayer = _make_melody_player()
@onready var _pulses: PulseEmitter = get_node_or_null(^"PulseEmitter") as PulseEmitter


func _process(delta: float) -> void:
	if not _running:
		return
	_left -= delta
	if _left <= 0.0:
		_running = false
		if release_stand_ins:
			for path: NodePath in stand_ins:
				(get_node(path) as FactStaging).release(stand_ins[path])
		finish()

func start() -> void:
	for path: NodePath in stand_ins:
		var staging := get_node_or_null(path) as FactStaging
		assert(staging != null, "%s: no FactStaging at %s" % [name, path])
		staging.stand_in(stand_ins[path])
	_left = duration
	if melody != null:
		_melody_player.voices = voices
		_melody_player.play(melody, melody_count)
		_left = maxf(duration, melody.duration(melody_count))
	elif stream != null:
		_voice.stream = stream
		_voice.play()
	if pulse_song != null and _pulses != null:
		_pulses.spawn_pulse(pulse_song, _pulse_point(), pulse_stats)
	_running = true
	super()

func is_running() -> bool:
	return _running

func _pulse_point() -> Vector2:
	var at := get_node_or_null(pulse_at) as Node2D if not pulse_at.is_empty() else null
	if at == null:
		at = get_parent() as Node2D
	return at.global_position if at != null else Vector2.ZERO

func _make_voice() -> AudioStreamPlayer:
	var made := AudioStreamPlayer.new()
	add_child(made)
	return made

func _make_melody_player() -> MelodyPlayer:
	var made := MelodyPlayer.new()
	add_child(made)
	return made
