class_name TalkableTest extends GdUnitTestSuite

## A Talkable has something to say while its set has a current dialogue and it is shown; an auto start is due after its
## delay in reach, fires once, and arms again only after the body leaves.

const F := preload("res://tests/resources/dialogue/dialogue_fixture.gd")
const TALKABLE := preload("res://scenes/world/interactables/talkable/talkable.tscn")

var _talkable: Talkable
var _body: CharacterBody2D


func before_test() -> void:
	SaveSystem.begin("", true)
	_talkable = auto_free(TALKABLE.instantiate()) as Talkable
	var dialogues: Array[Dialogue] = [F.dialogue(&"first", [F.line("A")], true)]
	_talkable.talk = F.dialogue_set(dialogues)
	add_child(_talkable)
	_body = auto_free(CharacterBody2D.new()) as CharacterBody2D
	_body.collision_layer = Seat.PLAYER_BODY
	_body.collision_mask = 0
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(16, 40)
	shape.shape = rect
	_body.add_child(shape)
	_body.position = Vector2(1000, 0)
	add_child(_body)

func after_test() -> void:
	SaveSystem.begin("", true)

func _frames(count: int) -> void:
	for i: int in count:
		await get_tree().physics_frame

func _enter() -> void:
	_body.position = Vector2(0, -20)
	await _frames(3)

func _leave() -> void:
	_body.position = Vector2(1000, 0)
	await _frames(3)

func test_the_zone_rises_from_the_floor_and_the_prompt_stands_over_it() -> void:
	assert_vector(_talkable.size()).is_equal(Vector2(64, 64))
	var prompt := _talkable.get_node("Prompt") as Control
	assert_float(prompt.position.y + prompt.size.y).is_equal(-64.0 - Talkable.PROMPT_GAP)
	assert_float(prompt.position.x + prompt.size.x * 0.5).is_equal(0.0)

func test_it_has_talk_while_a_dialogue_is_current() -> void:
	assert_bool(_talkable.has_talk()).is_true()
	SaveSystem.mark_dialogue_heard(&"first")
	assert_bool(_talkable.has_talk()).is_false()

func test_a_hidden_talkable_has_nothing_to_say() -> void:
	_talkable.hide()
	assert_bool(_talkable.has_talk()).is_false()

func test_an_auto_start_is_due_after_its_delay_and_fires_once_per_visit() -> void:
	_talkable.auto_start = true
	await _enter()
	assert_bool(_talkable.auto_ready()).is_false()
	await await_millis(int(_talkable.auto_delay * 1000.0) + 100)
	assert_bool(_talkable.auto_ready()).is_true()
	_talkable.take_auto()
	assert_bool(_talkable.auto_ready()).is_false()
	await await_millis(500)
	assert_bool(_talkable.auto_ready()).is_false()
	await _leave()
	await _enter()
	await await_millis(int(_talkable.auto_delay * 1000.0) + 100)
	assert_bool(_talkable.auto_ready()).is_true()

func test_an_auto_start_waits_for_an_unheard_dialogue() -> void:
	_talkable.auto_start = true
	SaveSystem.mark_dialogue_heard(&"first")
	await _enter()
	await await_millis(int(_talkable.auto_delay * 1000.0) + 100)
	assert_bool(_talkable.auto_ready()).is_false()

func test_without_auto_start_nothing_is_due() -> void:
	await _enter()
	await await_millis(int(_talkable.auto_delay * 1000.0) + 100)
	assert_bool(_talkable.auto_ready()).is_false()
