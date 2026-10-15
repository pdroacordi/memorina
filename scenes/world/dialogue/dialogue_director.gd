class_name DialogueDirector
extends Node
## Runs a talk: steps a DialogueRunner, tells the box what to show and Ivo when to listen, and writes what the talk
## leaves in the save: grants, answers, and heard at the end (systems/dialogue).

## Ivo hears no input and faces `at` until `talk_paused` or `talk_ended`.
signal talk_began(at: Vector2)
## A cue handed the talk to a beat: Ivo is free, still in the talk, until `talk_began` or `talk_ended`.
signal talk_paused
## The beat is over; Ivo answers with `resume()` once the start gates hold.
signal resume_wanted
signal talk_ended
## Where the box opens for this talk; held until the talk ends or resumes.
signal box_placed(side: DialogueBoxSide.Side)
signal line_shown(speaker: Speaker, text_key: String)
## The asking line's choice text keys, in order.
signal choices_shown(keys: PackedStringArray)
signal box_closed

@export var catalog: DialogueCatalog
## Ivo: with the speaker, where he stands on screen decides the box's side.
@export var listener: Node2D

## Null while no talk runs.
var _runner: DialogueRunner
## Where the speaker stands; Ivo faces it.
var _at: Vector2
## The beat a cue handed the talk to; null while none plays.
var _beat: DialogueBeat
## The beat is over and the talk waits for `resume()`.
var _waiting: bool = false


func _ready() -> void:
	if OS.is_debug_build() and catalog != null:
		var problems := catalog.validate()
		assert(problems.is_empty(), "Dialogue catalog: %s" % "; ".join(problems))

## A talk runs: its box open, handed to a beat, or waiting to resume.
func is_talking() -> bool:
	return _runner != null

func start(talkable: Talkable) -> void:
	if _runner != null:
		return
	var dialogue := talkable.current(SaveSystem.player_data)
	if dialogue == null:
		return
	_runner = DialogueRunner.new(dialogue, SaveSystem.player_data)
	_at = talkable.speaker_position()
	_begin()

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

## A hurt or a hazard ends the talk unheard. A beat is not interrupted: the talk is in its hands.
func interrupt() -> void:
	if _runner == null or _beat != null:
		return
	if not _waiting:
		box_closed.emit()
	_drop()
	talk_ended.emit()

func _begin() -> void:
	box_placed.emit(_side())
	talk_began.emit(_at)
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
			var grant := _runner.grant()
			if grant != null:
				SaveSystem.set_item_owned(grant.index as Enums.PlayerItem, true)
			line_shown.emit(_runner.speaker(), _runner.text_key())
			# A question's choices come with it; the box shows them once it is typed.
			if _runner.asks():
				_step()
		DialogueRunner.Step.CHOICES:
			var keys := PackedStringArray()
			for answer: DialogueChoice in _runner.choices():
				keys.append(answer.text_key)
			choices_shown.emit(keys)
		DialogueRunner.Step.CUE:
			_play(_runner.cue())
		DialogueRunner.Step.END:
			var heard := _runner.dialogue().id
			_drop()
			SaveSystem.mark_dialogue_heard(heard)
			box_closed.emit()
			talk_ended.emit()

func _play(cue: StringName) -> void:
	var beat := DialogueBeat.find(get_tree(), cue)
	if beat == null:
		push_error("No DialogueBeat for cue '%s'; the talk goes on" % cue)
		_step()
		return
	box_closed.emit()
	talk_paused.emit()
	_beat = beat
	beat.finished.connect(_on_beat_over)
	# A beat freed with its room must not leave the talk waiting for ever.
	beat.tree_exiting.connect(_on_beat_over)
	beat.start()

func _on_beat_over() -> void:
	if _beat == null:
		return
	_beat.finished.disconnect(_on_beat_over)
	_beat.tree_exiting.disconnect(_on_beat_over)
	_beat = null
	# The world is being swapped out (a death or quit): the save is already rewound, so the talk writes nothing more
	# (gotchas/a-removed-subtree-emits-tree-exiting-later-siblings-first).
	if not is_inside_tree():
		_drop()
		return
	_waiting = true
	resume_wanted.emit()

func _drop() -> void:
	_runner = null
	_beat = null
	_waiting = false
