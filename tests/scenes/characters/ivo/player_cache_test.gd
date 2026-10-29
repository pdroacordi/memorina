class_name PlayerCacheTest extends GdUnitTestSuite

## Up takes a season seed in reach once, after a door, a talk, an item and a found piece, under the pickups' gates; a
## refused press is spent (systems/seeds-and-the-seller).

const F := preload("res://tests/resources/dialogue/dialogue_fixture.gd")
const IVO := preload("res://scenes/characters/ivo/ivo.tscn")
const CACHE := preload("res://scenes/world/interactables/cache_pickup/cache_pickup.tscn")
const DOOR := preload("res://scenes/world/interactables/door/door.tscn")
const TALKABLE := preload("res://scenes/world/interactables/talkable/talkable.tscn")
const ITEM := preload("res://scenes/world/interactables/item_pickup/item_pickup.tscn")
const FOUND := preload("res://scenes/world/interactables/found_pickup/found_pickup.tscn")
const SWORD := preload("res://assets/sprites/world/pickups/sword.png")
const LETTER := preload("res://assets/sprites/world/pickups/letter.png")
const SLOT := &"threshold_ravine_cache"

## Top of the test floor.
const FLOOR_Y := 30.0

var _holder: Node2D
var _ivo: Player
var _cache: CachePickup


func before_test() -> void:
	SaveSystem.begin("", true)
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
	_cache = CACHE.instantiate() as CachePickup
	_cache.slot_id = SLOT
	_cache.position = Vector2(0, FLOOR_Y)
	_holder.add_child(_cache)

func after_test() -> void:
	SaveSystem.begin("", true)

func _add_ivo() -> void:
	_ivo = IVO.instantiate() as Player
	_ivo.position = Vector2(0, -60)
	_holder.add_child(_ivo)

func _player_input() -> PlayerInput:
	return _ivo.get_node("PlayerInput") as PlayerInput

func _press_up() -> void:
	_player_input().look_up_pressed.emit()
	await _frames(3)

func _frames(count: int) -> void:
	for i: int in count:
		await get_tree().physics_frame

func _land() -> void:
	for i: int in 120:
		await get_tree().physics_frame
		if _ivo.is_on_floor() and _ivo.is_still():
			return
	fail("Ivo never landed on the test floor")

func test_up_takes_a_seed_once() -> void:
	_add_ivo()
	var taken: Array[StringName] = []
	_cache.taken.connect(func(slot_id: StringName) -> void: taken.append(slot_id))
	await _land()
	await _press_up()
	assert_bool(SaveSystem.has_cache(SLOT)).is_true()
	assert_bool(_cache.is_lying()).is_false()
	await _press_up()
	assert_array(taken).is_equal([SLOT])
	assert_array(SaveSystem.player_data.caches_taken).has_size(1)

func test_a_door_in_reach_wins() -> void:
	var door := DOOR.instantiate() as Door
	door.position = Vector2(0, FLOOR_Y)
	_holder.add_child(door)
	_add_ivo()
	var entered: Array[Door] = []
	_ivo.door_entered.connect(func(which: Door) -> void: entered.append(which))
	await _land()
	await _press_up()
	assert_array(entered).contains_exactly([door])
	assert_bool(SaveSystem.has_cache(SLOT)).is_false()

func test_a_talk_in_reach_wins() -> void:
	var talkable := TALKABLE.instantiate() as Talkable
	talkable.position = Vector2(0, FLOOR_Y)
	var dialogues: Array[Dialogue] = [F.dialogue(&"talk", [F.line("A")])]
	talkable.talk = F.dialogue_set(dialogues)
	_holder.add_child(talkable)
	_add_ivo()
	var started: Array[Talkable] = []
	_ivo.talk_started.connect(func(which: Talkable) -> void: started.append(which))
	await _land()
	await _press_up()
	assert_array(started).contains_exactly([talkable])
	assert_bool(SaveSystem.has_cache(SLOT)).is_false()

func test_an_item_in_reach_wins() -> void:
	SaveSystem.set_item_owned(Enums.PlayerItem.SWORD, false)
	var item := ITEM.instantiate() as ItemPickup
	item.texture = SWORD
	item.position = Vector2(0, FLOOR_Y)
	_holder.add_child(item)
	_add_ivo()
	await _land()
	await _press_up()
	assert_bool(SaveSystem.has_item(Enums.PlayerItem.SWORD)).is_true()
	assert_bool(SaveSystem.has_cache(SLOT)).is_false()

func test_a_found_piece_in_reach_wins() -> void:
	var piece := FoundPiece.new()
	piece.slot_id = &"woods_hut_letter"
	piece.texture = LETTER
	var found := FOUND.instantiate() as FoundPickup
	found.piece = piece
	found.position = Vector2(0, FLOOR_Y)
	_holder.add_child(found)
	_add_ivo()
	await _land()
	await _press_up()
	assert_bool(SaveSystem.has_found(&"woods_hut_letter")).is_true()
	assert_bool(SaveSystem.has_cache(SLOT)).is_false()

func test_up_in_the_air_does_not_take_it() -> void:
	_add_ivo()
	await _land()
	_player_input().jump_pressed.emit()
	await _frames(4)
	assert_bool(_ivo.is_on_floor()).is_false()
	await _press_up()
	assert_bool(SaveSystem.has_cache(SLOT)).is_false()

func test_up_in_a_story_does_not_take_it() -> void:
	_add_ivo()
	await _land()
	_ivo.begin_talk(Vector2(100, FLOOR_Y))
	await _press_up()
	_ivo.end_talk()
	await _frames(3)
	assert_bool(SaveSystem.has_cache(SLOT)).is_false()

## A press refused by a roll is spent: the roll ends inside UP_BUFFER, and the seed is still not taken after it.
func test_a_press_refused_by_a_roll_is_spent() -> void:
	SaveSystem.unlock_skill(Enums.PlayerSkill.ROLL)
	# Wide enough that the roll never carries him out of reach.
	((_cache.get_node("CollisionShape2D") as CollisionShape2D).shape as RectangleShape2D).size.x = 1280.0
	_add_ivo()
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
	assert_bool(SaveSystem.has_cache(SLOT)).is_false()

## The prompt shows exactly where Up would take the seed, across its edge (both read the door sensor).
func test_the_prompt_and_the_reach_agree_at_the_edge() -> void:
	_add_ivo()
	await _land()
	var prompt := _cache.get_node("Prompt") as CanvasItem
	var pickups := _ivo.get_node("Pickups") as PickupComponent
	var shown := 0
	for x: int in range(20, 56, 2):
		_ivo.teleport(Vector2(x, FLOOR_Y))
		await _frames(3)
		var reached := pickups.reachable_cache() == _cache
		assert_bool(prompt.visible).override_failure_message("x %d: prompt %s, reach %s" % [x, prompt.visible, reached]).is_equal(reached)
		shown += 1 if reached else 0
	assert_int(shown).is_between(1, 17)
