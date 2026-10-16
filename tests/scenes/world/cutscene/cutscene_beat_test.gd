class_name CutsceneBeatTest extends GdUnitTestSuite

## A talk's cue hands the talk to a CutsceneBeat: the scene plays while the talk waits, and when the scene ends the talk
## asks to resume and then reaches its end.

const C := preload("res://tests/resources/cutscene/cutscene_fixture.gd")
const D := preload("res://tests/resources/dialogue/dialogue_fixture.gd")
const TALKABLE := preload("res://scenes/world/interactables/talkable/talkable.tscn")
const IVO := preload("res://scenes/characters/ivo/ivo.tscn")

var _holder: Node2D
var _dialogue: DialogueDirector
var _cutscenes: CutsceneDirector
var _talkable: Talkable
var _beat: CutsceneBeat
var _log: PackedStringArray


func before_test() -> void:
	SaveSystem.begin("", true)
	_log = PackedStringArray()
	_holder = auto_free(Node2D.new()) as Node2D
	add_child(_holder)
	var ivo := IVO.instantiate() as Player
	_holder.add_child(ivo)
	_dialogue = DialogueDirector.new()
	_holder.add_child(_dialogue)
	_cutscenes = CutsceneDirector.new()
	_cutscenes.ivo = ivo
	_cutscenes.dialogue = _dialogue
	_holder.add_child(_cutscenes)
	_beat = CutsceneBeat.new()
	_beat.cue = &"to_bed"
	_beat.cutscene = C.scene(&"to_bed", [C.wait(0.2)])
	_holder.add_child(_beat)
	_beat.owner = _holder
	_talkable = TALKABLE.instantiate() as Talkable
	_holder.add_child(_talkable)
	_dialogue.talk_paused.connect(func(_hold: int, _pose: int, _at: Vector2) -> void: _log.append("paused"))
	_dialogue.resume_wanted.connect(func() -> void:
		_log.append("wanted")
		_dialogue.resume())
	_dialogue.talk_ended.connect(func() -> void: _log.append("ended"))
	_cutscenes.scene_began.connect(func(_scene: Cutscene) -> void: _log.append("scene"))
	_cutscenes.scene_ended.connect(func(_scene: Cutscene) -> void: _log.append("scene_end"))

func after_test() -> void:
	SaveSystem.begin("", true)

func test_the_talk_resumes_after_its_scene() -> void:
	var dialogues: Array[Dialogue] = [D.dialogue(&"song", [D.cue_line(&"to_bed")])]
	_talkable.talk = D.dialogue_set(dialogues)
	_dialogue.start(_talkable)
	assert_array(Array(_log)).is_equal(["paused", "scene"])
	assert_bool(_cutscenes.is_playing()).is_true()
	for i: int in 60:
		await get_tree().physics_frame
		if _log.has("ended"):
			break
	assert_array(Array(_log)).is_equal(["paused", "scene", "scene_end", "wanted", "ended"])
	assert_bool(SaveSystem.is_scene_seen(&"to_bed")).is_true()
	assert_bool(SaveSystem.is_dialogue_heard(&"song")).is_true()

## A face the scene gives Ivo holds when the talk resumes and to its end (bugs/look-at-the-painting-turns-ivo-the-way-he-already-faces).
func test_a_face_the_scene_gives_ivo_holds_to_the_talks_end() -> void:
	var ivo := _cutscenes.ivo
	ivo.position = Vector2(0, 0)
	_talkable.position = Vector2(-200, 0)
	_dialogue.talk_began.connect(ivo.begin_talk)
	_dialogue.talk_paused.connect(ivo.pause_talk)
	_dialogue.talk_ended.connect(ivo.end_talk)
	var turn := CutsceneFace.new()
	turn.actor = CutsceneStep.IVO
	turn.side = 1
	_beat.cutscene = C.scene(&"turns", [turn, C.wait(0.1)])
	var dialogues: Array[Dialogue] = [D.dialogue(&"turning", [D.line("A"), D.cue_line(&"to_bed"), D.line("B")])]
	_talkable.talk = D.dialogue_set(dialogues)
	_dialogue.start(_talkable)
	assert_int(ivo.facing).is_equal(-1)
	_dialogue.advance()
	for i: int in 30:
		await get_tree().physics_frame
		if _log.has("wanted"):
			break
	await get_tree().physics_frame
	assert_bool(_dialogue.is_talking()).is_true()
	assert_int(ivo.facing).is_equal(1)
