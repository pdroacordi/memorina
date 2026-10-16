class_name DialogueDirector
extends Node
## Runs a talk: steps a DialogueRunner, tells the box what to show and Ivo when to listen, and writes what the talk
## leaves in the save: grants, answers, and heard at the end (systems/dialogue).

## Ivo hears no input and faces `at` until `talk_paused` or `talk_ended`.
signal talk_began(at: Vector2)
## A cue handed the talk to a beat: Ivo is held as `hold` says (DialogueBeat.Hold), holds `pose` (DialogueBeat.Pose) and
## faces `at`, still in the talk, until `talk_began` or `talk_ended`.
signal talk_paused(hold: int, pose: int, at: Vector2)
## The beat is over; Ivo answers with `resume()` once the start gates hold.
signal resume_wanted
signal talk_ended
## The camera holds the speaker at `at` and Ivo at `zoom` until `talk_unframed` (Dialogue.zoom).
signal talk_framed(at: Vector2, zoom: float)
signal talk_unframed
## Where the box opens for this talk; held until the talk ends or resumes.
signal box_placed(side: DialogueBoxSide.Side)
signal line_shown(speaker: Speaker, text_key: String)
## The asking line's choice text keys, in order; `silent` for a gesture, a line with no question.
signal choices_shown(keys: PackedStringArray, silent: bool)
signal box_closed
## The current beat's phrase, relayed to the PhraseSheet.
signal phrase_shown(notes: Array[Enums.Note], count: int, glyph_set: Enums.GlyphSet)
signal phrase_lit(index: int)
signal phrase_closed

@export var catalog: DialogueCatalog
## Ivo: with the speaker, where he stands on screen decides the box's side.
@export var listener: Node2D

## Null while no talk runs.
var _runner: DialogueRunner
## Where the speaker stands; the box is placed from it.
var _at: Vector2
## What Ivo faces when the talk begins or resumes: the speaker, until a beat turns him to its `face` for the rest of the
## talk ("Ivo walks to it. The elder, behind him", design 05).
var _facing: Vector2
## The beat a cue handed the talk to; null while none plays.
var _beat: DialogueBeat
## The beat is over and the talk waits for `resume()`.
var _waiting: bool = false
## The talk holds the camera's frame.
var _framed: bool = false


func _ready() -> void:
	if OS.is_debug_build() and catalog != null:
		var problems := catalog.validate()
		assert(problems.is_empty(), "Dialogue catalog: %s" % "; ".join(problems))

## A talk runs: its box open, handed to a beat, or waiting to resume.
func is_talking() -> bool:
	return _runner != null

func start(talkable: Talkable) -> void:
	start_dialogue(talkable.current(SaveSystem.player_data), talkable.speaker_position())

## Runs `dialogue` spoken from `at` (a Talkable, or a cutscene's CutsceneTalk); false when a talk already runs or there is
## nothing to say.
func start_dialogue(dialogue: Dialogue, at: Vector2) -> bool:
	if _runner != null or dialogue == null:
		return false
	_runner = DialogueRunner.new(dialogue, SaveSystem.player_data)
	_at = at
	_facing = _at
	if dialogue.zoom > 0.0:
		_framed = true
		talk_framed.emit(at, dialogue.zoom)
	_begin()
	return true

## Ivo is free on the floor again after a beat: the talk goes on.
func resume() -> void:
	if _runner == null or not _waiting:
		return
	_waiting = false
	_begin()

## The box's press on a typed line.
func advance() -> void:
	if _runner == null or _beat != null or _waiting or _runner.step() != DialogueRunner.Step.LINE:
		return
	_step()

func choose(index: int) -> void:
	if _runner == null or _beat != null or _waiting or _runner.step() != DialogueRunner.Step.CHOICES:
		return
	var ask := _runner.ask_id()
	var picked := _runner.choose(index)
	SaveSystem.record_response(ask, picked.id)
	_step()

## A note input from Ivo while a beat holds NOTES; dropped otherwise.
func hear_note(note: Enums.Note, glyph_set: Enums.GlyphSet) -> void:
	if _beat != null and _beat.hold == DialogueBeat.Hold.NOTES:
		_beat.receive_note(note, glyph_set)

## A hurt or a hazard ends the talk unheard. A beat is not interrupted: the talk is in its hands.
func interrupt() -> void:
	if _runner == null or _beat != null:
		return
	if not _waiting:
		box_closed.emit()
	_drop()
	_unframe()
	talk_ended.emit()

func _begin() -> void:
	box_placed.emit(_side())
	talk_began.emit(_facing)
	_step()

## Opposite the speakers on screen (DialogueBoxSide); the top when Ivo is unknown.
func _side() -> DialogueBoxSide.Side:
	if listener == null or not listener.is_inside_tree():
		return DialogueBoxSide.Side.TOP
	var canvas := listener.get_canvas_transform()
	var ys := PackedFloat32Array([(canvas * _at).y, (canvas * listener.global_position).y])
	return DialogueBoxSide.opposite(ys, listener.get_viewport_rect().size.y)

func _step() -> void:
	match _runner.advance():
		DialogueRunner.Step.LINE:
			_apply_grant()
			line_shown.emit(_runner.speaker(), _runner.text_key())
			# A question's choices come with it; the box shows them once it is typed.
			if _runner.asks():
				_step()
		DialogueRunner.Step.CHOICES:
			var keys := PackedStringArray()
			for answer: DialogueChoice in _runner.choices():
				keys.append(answer.text_key)
			choices_shown.emit(keys, _runner.silent())
		DialogueRunner.Step.CUE:
			_play(_runner.cue())
		DialogueRunner.Step.END:
			var heard := _runner.dialogue().id
			_drop()
			SaveSystem.mark_dialogue_heard(heard)
			box_closed.emit()
			_unframe()
			talk_ended.emit()

func _play(cue: StringName) -> void:
	# A cue-only line's grant lands as its beat starts: the mentor's hand opens as the beat begins.
	_apply_grant()
	var beat := DialogueBeat.find(get_tree(), cue)
	if beat == null:
		push_error("No DialogueBeat for cue '%s'; the talk goes on" % cue)
		_step()
		return
	box_closed.emit()
	_beat = beat
	beat.finished.connect(_on_beat_over)
	# A beat freed with its room must not leave the talk waiting for ever.
	beat.tree_exiting.connect(_on_beat_over)
	beat.phrase_shown.connect(phrase_shown.emit)
	beat.phrase_lit.connect(phrase_lit.emit)
	beat.phrase_closed.connect(phrase_closed.emit)
	_facing = beat.face_point(_facing)
	talk_paused.emit(beat.hold, beat.pose, _facing)
	beat.start()

func _apply_grant() -> void:
	var grant := _runner.grant()
	if grant != null:
		SaveSystem.set_item_owned(grant.index as Enums.PlayerItem, true)

func _on_beat_over() -> void:
	if _beat == null:
		return
	_facing = _beat.face_after(_facing)
	_beat.finished.disconnect(_on_beat_over)
	_beat.tree_exiting.disconnect(_on_beat_over)
	_beat.phrase_shown.disconnect(phrase_shown.emit)
	_beat.phrase_lit.disconnect(phrase_lit.emit)
	_beat.phrase_closed.disconnect(phrase_closed.emit)
	phrase_closed.emit()
	_beat = null
	# The world is being swapped out (a death or quit): the save is already rewound, so the talk writes nothing more
	# (gotchas/a-removed-subtree-emits-tree-exiting-later-siblings-first).
	if not is_inside_tree():
		_drop()
		return
	_waiting = true
	resume_wanted.emit()

func _unframe() -> void:
	if _framed:
		_framed = false
		talk_unframed.emit()

func _drop() -> void:
	_runner = null
	_beat = null
	_waiting = false
