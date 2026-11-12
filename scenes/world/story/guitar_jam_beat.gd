class_name GuitarJamBeat
extends DialogueBeat
## Ivo jams on the guitar beside her song (flashback 1, systems/story): GuitarJam decides each press, this node sounds it
## detuned, stands in her laugh at the mismatch it names, and ends after its presses or a silence.

@export var setup: GuitarJamSetup
## One string per Enums.Note (UP, DOWN, LEFT, RIGHT).
@export var strings: Array[AudioStream] = []
## FactStaging path to the child it stands in while she laughs (empty: nothing), released after `setup.laugh_seconds`.
@export var laugh_stand_ins: Dictionary[NodePath, StringName] = {}

var _jam: GuitarJam
## Scaled seconds since the last press that sounded, or since the start.
var _since_press: float = 0.0
## Scaled seconds the laugh has left; 0 when none shows.
var _laugh_left: float = 0.0
var _running: bool = false

@onready var _voice: AudioStreamPlayer = _make_voice()


func _init() -> void:
	hold = Hold.NOTES
	pose = Pose.GUITAR

func _process(delta: float) -> void:
	if not _running:
		return
	_since_press += delta
	if _laugh_left > 0.0:
		_laugh_left -= delta
		if _laugh_left <= 0.0:
			_release_laugh()
	var silence := setup.end_after_silence if _jam.presses() > 0 else setup.end_before_first
	if _jam.is_over() or _since_press >= silence:
		_end()

func start() -> void:
	_jam = GuitarJam.new(setup)
	_since_press = 0.0
	_laugh_left = 0.0
	_running = true
	note_received.connect(_on_note)
	super()

func is_running() -> bool:
	return _running

## The laugh stand-in shows.
func is_laughing() -> bool:
	return _laugh_left > 0.0

func _on_note(note: Enums.Note, _glyph_set: Enums.GlyphSet) -> void:
	if not _running or _jam.is_over() or (_jam.presses() > 0 and _since_press < setup.min_gap):
		return
	_since_press = 0.0
	var index := _jam.presses()
	_jam.press(note)
	_sound(strings[note] if note < strings.size() else null, _jam.pitch_scale(index))
	if _jam.laughs():
		_laugh()

func _laugh() -> void:
	_laugh_left = setup.laugh_seconds
	for path: NodePath in laugh_stand_ins:
		var staging := get_node_or_null(path) as FactStaging
		assert(staging != null, "%s: no FactStaging at %s" % [name, path])
		staging.stand_in(laugh_stand_ins[path])

func _release_laugh() -> void:
	_laugh_left = 0.0
	for path: NodePath in laugh_stand_ins:
		var staging := get_node_or_null(path) as FactStaging
		if staging != null:
			staging.release(laugh_stand_ins[path])

func _end() -> void:
	_running = false
	_release_laugh()
	note_received.disconnect(_on_note)
	finish()

func _sound(stream: AudioStream, pitch: float) -> void:
	if stream == null:
		return
	_voice.stream = stream
	_voice.pitch_scale = pitch
	_voice.play()

func _make_voice() -> AudioStreamPlayer:
	var made := AudioStreamPlayer.new()
	made.max_polyphony = 4
	made.bus = AudioBuses.NOTES
	add_child(made)
	return made
