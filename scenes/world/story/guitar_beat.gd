class_name GuitarBeat
extends DialogueBeat
## Ivo plays the morning song on the guitar and the next note is not there (systems/story): GuitarPhrase decides each
## press, this node sounds it, lights the sheet and ends the beat once the strings have given up.

@export var attempt: GuitarAttempt
## One string per Enums.Note (UP, DOWN, LEFT, RIGHT).
@export var strings: Array[AudioStream] = []
## A press at the gap: the string muted under the hand.
@export var muted: AudioStream
## FactStaging path to the child it stands in while the beat plays, until the staging's stage changes.
@export var stand_ins: Dictionary[NodePath, StringName] = {}

var _phrase: GuitarPhrase
## Scaled seconds since the last press that sounded.
var _since_press: float = 0.0
## Scaled seconds of silence since the phrase reached its gap.
var _silence: float = 0.0
var _running: bool = false

@onready var _voice: AudioStreamPlayer = _make_voice()


func _init() -> void:
	hold = Hold.NOTES
	pose = Pose.GUITAR

func _process(delta: float) -> void:
	if not _running:
		return
	_since_press += delta
	if not _phrase.at_gap():
		return
	_silence += delta
	if _silence >= attempt.end_after_silence or _phrase.dead_presses() >= attempt.end_after_dead_presses:
		_end()

func start() -> void:
	_phrase = GuitarPhrase.new(attempt)
	_since_press = attempt.min_gap
	_silence = 0.0
	_running = true
	for path: NodePath in stand_ins:
		var staging := get_node_or_null(path) as FactStaging
		assert(staging != null, "%s: no FactStaging at %s" % [name, path])
		staging.stand_in(stand_ins[path])
	note_received.connect(_on_note)
	phrase_shown.emit(attempt.melody.notes, _phrase.gap_index(), InputDevice.glyph_set)
	super()

func is_running() -> bool:
	return _running

func _on_note(note: Enums.Note, _glyph_set: Enums.GlyphSet) -> void:
	if not _running or _since_press < attempt.min_gap:
		return
	_since_press = 0.0
	_silence = 0.0
	match _phrase.press(note):
		GuitarPhrase.Press.PLAYED:
			_sound(strings[note] if note < strings.size() else null)
			phrase_lit.emit(_phrase.played() - 1)
		GuitarPhrase.Press.MISSED:
			_sound(strings[note] if note < strings.size() else null)
		GuitarPhrase.Press.DEAD:
			_sound(muted)

func _end() -> void:
	_running = false
	note_received.disconnect(_on_note)
	finish()

func _sound(stream: AudioStream) -> void:
	if stream == null:
		return
	_voice.stream = stream
	_voice.play()

func _make_voice() -> AudioStreamPlayer:
	var made := AudioStreamPlayer.new()
	made.max_polyphony = 4
	add_child(made)
	return made
