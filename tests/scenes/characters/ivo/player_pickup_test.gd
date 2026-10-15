class_name PlayerPickupTest extends GdUnitTestSuite

## Up takes an item lying in reach once, under the door's gates; a door or a talk in reach wins; without the sword an
## attack does nothing, and after taking it Ivo swings.

const F := preload("res://tests/resources/dialogue/dialogue_fixture.gd")
const IVO := preload("res://scenes/characters/ivo/ivo.tscn")
const DOOR := preload("res://scenes/world/interactables/door/door.tscn")
const TALKABLE := preload("res://scenes/world/interactables/talkable/talkable.tscn")
const PICKUP := preload("res://scenes/world/interactables/item_pickup/item_pickup.tscn")
const SWORD := preload("res://assets/sprites/world/pickups/sword.png")

## Top of the test floor.
const FLOOR_Y := 30.0

var _holder: Node2D
var _ivo: Player
var _pickup: ItemPickup
var _taken: Array[int] = []


func before_test() -> void:
	SaveSystem.begin("", true)
	SaveSystem.set_item_owned(Enums.PlayerItem.SWORD, false)
	_taken.clear()
	_holder = auto_free(Node2D.new()) as Node2D
	add_child(_holder)
	var floor_body := StaticBody2D.new()
	floor_body.collision_layer = 2
	floor_body.position = Vector2(0, FLOOR_Y + 10.0)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(4000, 20)
	shape.shape = rect
	floor_body.add_child(shape)
	_holder.add_child(floor_body)
	_pickup = PICKUP.instantiate() as ItemPickup
	_pickup.texture = SWORD
	_pickup.rest_offset = Vector2(-4, -19)
	_pickup.position = Vector2(0, FLOOR_Y)
	_holder.add_child(_pickup)
	_pickup.taken.connect(func(item: Enums.PlayerItem) -> void: _taken.append(item))
	_ivo = IVO.instantiate() as Player
	_ivo.position = Vector2(0, -60)
	_holder.add_child(_ivo)

func after_test() -> void:
	SaveSystem.begin("", true)

func _player_input() -> PlayerInput:
	return _ivo.get_node("PlayerInput") as PlayerInput

func _frames(count: int) -> void:
	for i: int in count:
		await get_tree().physics_frame

func _land() -> void:
	for i: int in 120:
		await get_tree().physics_frame
		if _ivo.is_on_floor() and _ivo.is_still():
			return
	fail("Ivo never landed on the test floor")

func test_up_takes_the_item_once() -> void:
	await _land()
	_player_input().look_up_pressed.emit()
	await _frames(3)
	assert_bool(SaveSystem.has_item(Enums.PlayerItem.SWORD)).is_true()
	assert_bool(_pickup.is_lying()).is_false()
	_player_input().look_up_pressed.emit()
	await _frames(3)
	assert_array(_taken).is_equal([Enums.PlayerItem.SWORD])

## Inside the reach but airborne: the on-floor gate refuses the press.
func test_up_in_the_air_does_not_take_it() -> void:
	await _land()
	_player_input().jump_pressed.emit()
	await _frames(4)
	assert_bool(_ivo.is_on_floor()).is_false()
	assert_object((_ivo.get_node("Pickups") as PickupComponent).reachable()).is_same(_pickup)
	_player_input().look_up_pressed.emit()
	await _frames(2)
	assert_array(_taken).is_empty()

func test_a_door_in_reach_wins_over_the_item() -> void:
	var door := DOOR.instantiate() as Door
	door.position = Vector2(0, FLOOR_Y)
	_holder.add_child(door)
	var entered: Array[Door] = []
	_ivo.door_entered.connect(func(taken: Door) -> void: entered.append(taken))
	await _land()
	_player_input().look_up_pressed.emit()
	await _frames(3)
	assert_array(entered).contains_exactly([door])
	assert_array(_taken).is_empty()

func test_a_talk_in_reach_wins_over_the_item() -> void:
	var talkable := TALKABLE.instantiate() as Talkable
	talkable.position = Vector2(0, FLOOR_Y)
	var dialogues: Array[Dialogue] = [F.dialogue(&"talk", [F.line("A")])]
	talkable.talk = F.dialogue_set(dialogues)
	_holder.add_child(talkable)
	var started: Array[Talkable] = []
	_ivo.talk_started.connect(func(which: Talkable) -> void: started.append(which))
	await _land()
	_player_input().look_up_pressed.emit()
	await _frames(3)
	assert_array(started).contains_exactly([talkable])
	assert_array(_taken).is_empty()

## STORY-02: the sword is what lets him swing.
func test_without_the_sword_he_cannot_swing_and_after_taking_it_he_can() -> void:
	await _land()
	_player_input().attack_pressed.emit()
	await _frames(3)
	assert_bool(_ivo.is_attacking()).is_false()
	await _frames(20)
	_player_input().look_up_pressed.emit()
	await _frames(3)
	_player_input().attack_pressed.emit()
	await _frames(3)
	assert_bool(_ivo.is_attacking()).is_true()

## A press refused by a roll is spent: the roll ends inside UP_BUFFER, and the item is still not taken after it.
func test_a_press_refused_by_a_roll_is_spent() -> void:
	SaveSystem.unlock_skill(Enums.PlayerSkill.ROLL)
	# Wide enough that the roll never carries him out of reach.
	((_pickup.get_node("CollisionShape2D") as CollisionShape2D).shape as RectangleShape2D).size.x = 1280.0
	await _land()
	_player_input().roll_pressed.emit()
	var roll := _ivo.get_node("Roll")
	for i: int in 60:
		await get_tree().physics_frame
		if _ivo.is_rolling() and float(roll.get("_roll_timer")) < Player.UP_BUFFER * 0.6:
			break
	assert_bool(_ivo.is_rolling()).is_true()
	_player_input().look_up_pressed.emit()
	for i: int in 30:
		await get_tree().physics_frame
		if not _ivo.is_rolling():
			break
	await _frames(10)
	assert_bool(_ivo.is_rolling()).is_false()
	assert_array(_taken).is_empty()

## "Buffer it ~0.1 s" (user, 2026-10-08): a press just short of the item takes it when it comes in reach.
func test_an_early_up_waits_for_the_item() -> void:
	_pickup.position = Vector2(500, FLOOR_Y)
	await _land()
	_player_input().look_up_pressed.emit()
	await _frames(1)
	_pickup.position = Vector2(0, FLOOR_Y)
	await _frames(4)
	assert_array(_taken).is_equal([Enums.PlayerItem.SWORD])

## The prompt shows while he is in reach and hides while he talks, as a Talkable's does.
func test_the_prompt_hides_while_he_talks() -> void:
	await _land()
	await _frames(2)
	var prompt := _pickup.get_node("Prompt") as Control
	assert_bool(prompt.visible).is_true()
	_ivo.begin_talk(Vector2(100, FLOOR_Y))
	await _frames(2)
	assert_bool(prompt.visible).is_false()
	_ivo.end_talk()
	await _frames(2)
	assert_bool(prompt.visible).is_true()
