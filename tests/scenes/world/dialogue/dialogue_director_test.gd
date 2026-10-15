class_name DialogueDirectorTest extends GdUnitTestSuite

## The director marks a dialogue heard only at its end, records answers, grants items, hands a cue to its beat and
## resumes when Ivo answers, writes nothing once the world is swapped out under a beat, places the box opposite the
## speakers, and an interrupt ends the talk unheard.

const F := preload("res://tests/resources/dialogue/dialogue_fixture.gd")
const TALKABLE := preload("res://scenes/world/interactables/talkable/talkable.tscn")

var _director: DialogueDirector
var _talkable: Talkable
## Every signal the director emitted, in order, as "name" or "name:detail".
var _log: PackedStringArray


func before_test() -> void:
	SaveSystem.begin("", true)
	_log = PackedStringArray()
	_director = auto_free(DialogueDirector.new()) as DialogueDirector
	add_child(_director)
	_director.talk_began.connect(func(_at: Vector2) -> void: _log.append("began"))
	_director.talk_ended.connect(func() -> void: _log.append("ended"))
	_director.line_shown.connect(func(_who: Speaker, key: String) -> void: _log.append("line:" + key))
	_director.choices_shown.connect(func(keys: PackedStringArray) -> void: _log.append("choices:" + ",".join(keys)))
	_director.box_closed.connect(func() -> void: _log.append("closed"))
	_director.talk_paused.connect(func() -> void: _log.append("paused"))
	_director.resume_wanted.connect(func() -> void: _log.append("wanted"))
	_talkable = auto_free(TALKABLE.instantiate()) as Talkable
	add_child(_talkable)

func after_test() -> void:
	SaveSystem.begin("", true)

func _talk(lines: Array[DialogueLine], id: StringName = &"talk") -> void:
	var dialogues: Array[Dialogue] = [F.dialogue(id, lines)]
	_talkable.talk = F.dialogue_set(dialogues)
	_director.start(_talkable)

func test_heard_only_at_the_end() -> void:
	_talk([F.line("A"), F.line("B")])
	assert_bool(_director.is_talking()).is_true()
	assert_array(Array(_log)).is_equal(["began", "line:A"])
	_director.advance()
	assert_bool(SaveSystem.is_dialogue_heard(&"talk")).is_false()
	_director.advance()
	assert_bool(SaveSystem.is_dialogue_heard(&"talk")).is_true()
	assert_bool(_director.is_talking()).is_false()
	assert_array(Array(_log)).is_equal(["began", "line:A", "line:B", "closed", "ended"])

func test_a_question_shows_its_choices_with_it_and_records_the_answer() -> void:
	_talk([F.keep_question(), F.line("Z")])
	assert_array(Array(_log)).is_equal(["began", "line:ASK", "choices:CHOICE_HOLD,CHOICE_LET_GO"])
	# A press on the question is not an answer.
	_director.advance()
	_director.choose(1)
	assert_str(String(SaveSystem.response_to(&"keep"))).is_equal("keep_let_go")
	assert_str(_log[_log.size() - 1]).is_equal("line:REPLY_LET_GO")
	_director.advance()
	_director.advance()
	assert_bool(SaveSystem.is_dialogue_heard(&"talk")).is_true()

func test_an_interrupt_ends_the_talk_unheard() -> void:
	_talk([F.line("A"), F.line("B")])
	_director.interrupt()
	assert_bool(_director.is_talking()).is_false()
	assert_bool(SaveSystem.is_dialogue_heard(&"talk")).is_false()
	assert_array(Array(_log)).is_equal(["began", "line:A", "closed", "ended"])
	_director.advance()
	assert_int(_log.size()).is_equal(4)

func test_a_grant_is_given_as_its_line_shows() -> void:
	SaveSystem.set_item_owned(Enums.PlayerItem.MEMORINA, false)
	var giving := F.line("GIVE")
	giving.grants = F.fact(SaveFact.Kind.ITEM, &"", Enums.PlayerItem.MEMORINA)
	_talk([giving])
	assert_bool(SaveSystem.has_item(Enums.PlayerItem.MEMORINA)).is_true()

func test_a_cue_hands_off_to_its_beat_and_resumes_when_ivo_answers() -> void:
	var beat := auto_free(DialogueBeat.new()) as DialogueBeat
	beat.cue = &"guitar"
	add_child(beat)
	var started: Array[int] = [0]
	beat.started.connect(func() -> void: started[0] += 1)
	var cued := F.line("A")
	cued.cue = &"guitar"
	_talk([cued, F.line("B")])
	_director.advance()
	assert_int(started[0]).is_equal(1)
	assert_array(Array(_log)).is_equal(["began", "line:A", "closed", "paused"])
	# During the beat Ivo is free; a hurt does not end the talk, and a press does nothing.
	_director.interrupt()
	_director.advance()
	beat.finish()
	assert_array(Array(_log)).is_equal(["began", "line:A", "closed", "paused", "wanted"])
	assert_bool(_director.is_talking()).is_true()
	# Nothing goes on until Ivo answers that the start gates hold.
	_director.advance()
	_director.resume()
	assert_array(Array(_log)).is_equal(["began", "line:A", "closed", "paused", "wanted", "began", "line:B"])
	_director.advance()
	assert_bool(SaveSystem.is_dialogue_heard(&"talk")).is_true()

func test_a_beat_freed_with_its_room_waits_for_ivo_then_resumes() -> void:
	var beat := DialogueBeat.new()
	beat.cue = &"guitar"
	add_child(beat)
	_talk([F.cue_line(&"guitar"), F.line("B")])
	beat.free()
	assert_str(_log[_log.size() - 1]).is_equal("wanted")
	_director.resume()
	assert_str(_log[_log.size() - 1]).is_equal("line:B")

## A hurt after the beat, before Ivo is free again, ends the talk unheard.
func test_an_interrupt_while_waiting_to_resume_drops_the_talk() -> void:
	var beat := auto_free(DialogueBeat.new()) as DialogueBeat
	beat.cue = &"guitar"
	add_child(beat)
	_talk([F.cue_line(&"guitar"), F.line("B")])
	beat.finish()
	_director.interrupt()
	assert_bool(_director.is_talking()).is_false()
	assert_str(_log[_log.size() - 1]).is_equal("ended")
	_director.resume()
	assert_str(_log[_log.size() - 1]).is_equal("ended")
	assert_bool(SaveSystem.is_dialogue_heard(&"talk")).is_false()

## A death swaps the world out under a beat after the save is rewound: the director leaves the tree before the beat
## (later siblings first, gotchas/a-removed-subtree-emits-tree-exiting-later-siblings-first) and writes nothing.
func test_a_world_swapped_out_under_a_beat_writes_nothing() -> void:
	SaveSystem.set_item_owned(Enums.PlayerItem.MEMORINA, false)
	# The bench the death rewinds to: a debug new game owns the Memorina.
	SaveSystem.commit()
	var world := Node.new()
	add_child(world)
	var beat := DialogueBeat.new()
	beat.cue = &"guitar"
	world.add_child(beat)
	var director := DialogueDirector.new()
	world.add_child(director)
	var signals: Array[String] = []
	director.talk_began.connect(func(_at: Vector2) -> void: signals.append("began"))
	director.resume_wanted.connect(func() -> void: signals.append("wanted"))
	var giving := F.line("GIVE")
	giving.grants = F.fact(SaveFact.Kind.ITEM, &"", Enums.PlayerItem.MEMORINA)
	var dialogues: Array[Dialogue] = [F.dialogue(&"talk", [F.cue_line(&"guitar"), giving])]
	_talkable.talk = F.dialogue_set(dialogues)
	director.start(_talkable)
	SaveSystem.rewind()
	remove_child(world)
	assert_bool(SaveSystem.has_item(Enums.PlayerItem.MEMORINA)).is_false()
	assert_bool(SaveSystem.is_dialogue_heard(&"talk")).is_false()
	assert_bool(director.is_talking()).is_false()
	assert_array(signals).is_equal(["began"])
	world.free()

## The box opens opposite the speakers on screen; with no listener, at the top.
func test_the_box_is_placed_opposite_the_speakers() -> void:
	var sides: Array[int] = []
	_director.box_placed.connect(func(side: DialogueBoxSide.Side) -> void: sides.append(side))
	_talk([F.line("A")])
	_director.interrupt()
	var height := get_viewport().get_visible_rect().size.y
	var ivo := auto_free(Node2D.new()) as Node2D
	add_child(ivo)
	_director.listener = ivo
	ivo.position = Vector2(0, height * 0.2)
	_talkable.position = Vector2(40, height * 0.2)
	_director.start(_talkable)
	_director.interrupt()
	ivo.position = Vector2(0, height * 0.9)
	_talkable.position = Vector2(40, height * 0.9)
	_director.start(_talkable)
	assert_array(sides).is_equal([DialogueBoxSide.Side.TOP, DialogueBoxSide.Side.BOTTOM, DialogueBoxSide.Side.TOP])

## Ivo faces the speaker beside the Talkable, not its origin.
func test_the_talk_faces_the_speaker_beside_the_talkable() -> void:
	var at: Array[Vector2] = []
	_director.talk_began.connect(func(point: Vector2) -> void: at.append(point))
	_talkable.position = Vector2(100, 30)
	_talkable.speaker_offset = 32.0
	_talk([F.line("A")])
	assert_vector(at[0]).is_equal(Vector2(132, 30))

func test_a_talk_already_running_is_not_restarted() -> void:
	_talk([F.line("A"), F.line("B")])
	_director.start(_talkable)
	assert_array(Array(_log)).is_equal(["began", "line:A"])
