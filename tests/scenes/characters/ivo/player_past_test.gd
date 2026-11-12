class_name PlayerPastTest extends GdUnitTestSuite

## In the past (Region.past, copied by Game to Player.in_past) Ivo carries no song, sword, map or life notes and notices
## wait; his items stay owned and scenes still start (architecture/story-05-playable-flashbacks).

const IVO := preload("res://scenes/characters/ivo/ivo.tscn")
const HUD := preload("res://scenes/ui/life_hud/life_hud.tscn")
const PAST := "res://scenes/world/rooms/past.tscn"
const VILLAGE := "res://scenes/world/rooms/home_village.tscn"
const FLOOR_Y := 30.0

var _holder: Node2D
var _ivo: Player


func before_test() -> void:
	SaveSystem.begin("", true)
	SaveSystem.set_item_owned(Enums.PlayerItem.MEMORINA, true)
	SaveSystem.set_item_owned(Enums.PlayerItem.SWORD, true)
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
	_ivo = IVO.instantiate() as Player
	_ivo.position = Vector2(0, -60)
	_holder.add_child(_ivo)

func after_test() -> void:
	SaveSystem.begin("", true)

func _player_input() -> PlayerInput:
	return _ivo.get_node("PlayerInput") as PlayerInput

func _land() -> void:
	for i: int in 120:
		await get_tree().physics_frame
		if _ivo.is_on_floor() and _ivo.is_still():
			return
	fail("Ivo never landed on the test floor")

func _frames(count: int) -> void:
	for i: int in count:
		await get_tree().physics_frame

func test_the_memorina_is_refused_and_still_owned() -> void:
	_ivo.in_past = true
	await _land()
	_player_input().draw_memorina_pressed.emit()
	await _frames(3)
	assert_bool(_ivo.is_memorina_drawn()).is_false()
	assert_bool(SaveSystem.player_data.owned_items[Enums.PlayerItem.MEMORINA]).is_true()
	_ivo.in_past = false
	_player_input().draw_memorina_pressed.emit()
	await _frames(3)
	assert_bool(_ivo.is_memorina_drawn()).is_true()

func test_the_map_is_refused_and_scenes_still_start() -> void:
	await _land()
	assert_bool(_ivo.can_open_map()).is_true()
	_ivo.in_past = true
	assert_bool(_ivo.can_open_map()).is_false()
	assert_bool(_ivo.can_begin_scene()).is_true()

func test_notices_wait_in_the_past() -> void:
	await _land()
	assert_bool(NoticeHold.applies(_ivo)).is_false()
	_ivo.in_past = true
	assert_bool(NoticeHold.applies(_ivo)).is_true()

func _first_room(path: String) -> Array:
	var region := (load(path) as PackedScene).instantiate() as Region
	for child: Node in region.get_children():
		if child is Room:
			return [region, child]
	return [region, null]

## The past's rooms are calm (no sword) and past; the village's street is neither.
func test_the_past_is_calm_and_past() -> void:
	var past: Array = _first_room(PAST)
	var village: Array = _first_room(VILLAGE)
	assert_bool((past[1] as Room).is_past()).is_true()
	assert_bool((past[1] as Room).is_calm()).is_true()
	assert_bool((village[1] as Room).is_past()).is_false()
	(past[0] as Node).free()
	(village[0] as Node).free()

## "Esconder no passado" (user, 2026-11-11): the life notes hide in the past and come back in the present.
func test_the_life_notes_hide_in_the_past() -> void:
	var hud := auto_free(HUD.instantiate()) as LifeHud
	add_child(hud)
	var past: Array = _first_room(PAST)
	var village: Array = _first_room(VILLAGE)
	hud.on_room_changed(past[1] as Room)
	assert_bool(hud.visible).is_false()
	hud.on_room_changed(village[1] as Room)
	assert_bool(hud.visible).is_true()
	(past[0] as Node).free()
	(village[0] as Node).free()
