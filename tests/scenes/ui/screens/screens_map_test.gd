class_name ScreensMapTest extends GdUnitTestSuite

## The map opens only while Ivo stands on the ground, blocks him without holding the world,
## closes on its toggle, back, pause, a hit or a death, and owns Z and X only while open.

const SCREENS := preload("res://scenes/ui/screens/screens.tscn")
const IVO := preload("res://scenes/characters/ivo/ivo.tscn")

var _holder: Node2D
var _screens: Screens
var _menu_input: MenuInput
var _map: MapScreen
var _ivo: Player
var _requests: Array[String] = []


func before_test() -> void:
	_requests.clear()
	_holder = auto_free(Node2D.new()) as Node2D
	add_child(_holder)
	var floor_body := StaticBody2D.new()
	floor_body.collision_layer = 2
	floor_body.position = Vector2(0, 40)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(4000, 20)
	shape.shape = rect
	floor_body.add_child(shape)
	_holder.add_child(floor_body)
	_ivo = IVO.instantiate() as Player
	_ivo.position = Vector2(0, -60)
	_holder.add_child(_ivo)
	_screens = auto_free(SCREENS.instantiate()) as Screens
	add_child(_screens)
	_menu_input = _screens.get_node("MenuInput") as MenuInput
	_map = _screens.get_node("MapScreen") as MapScreen
	_screens.set_map_subject(_ivo)
	for request: String in ["hold", "release", "block", "unblock"]:
		_screens.get(request + "_requested").connect(func() -> void: _requests.append(request))
	_screens.block_requested.connect(_ivo.block_input)
	_screens.unblock_requested.connect(_ivo.unblock_input)

func test_the_map_is_refused_in_mid_air() -> void:
	assert_bool(_ivo.can_open_map()).is_false()
	_menu_input.map_pressed.emit()
	assert_int(_screens.showing()).is_equal(ScreenRouter.Kind.NONE)
	assert_bool(_map.visible).is_false()
	assert_array(_requests).is_empty()

func test_on_the_ground_the_map_opens_and_blocks_without_holding() -> void:
	await _land()
	_menu_input.map_pressed.emit()
	assert_int(_screens.showing()).is_equal(ScreenRouter.Kind.MAP)
	assert_bool(_map.visible).is_true()
	assert_array(_requests).contains_exactly(["block"])
	assert_bool(get_tree().paused).is_false()
	assert_bool((_screens.get_node("Dim") as CanvasItem).visible).is_false()
	assert_bool((_ivo.get_node("PlayerInput") as PlayerInput).blocked).is_true()

## "Toggle": M or LB closes it; Esc and B close it too, and Esc does not open the pause.
func test_its_toggle_back_and_pause_all_close_it() -> void:
	await _land()
	for close: Signal in [_menu_input.map_pressed, _menu_input.back_pressed, _menu_input.pause_pressed]:
		_menu_input.map_pressed.emit()
		close.emit()
		assert_int(_screens.showing()).override_failure_message(close.get_name()).is_equal(ScreenRouter.Kind.NONE)
	assert_array(_requests).contains_exactly(["block", "unblock", "block", "unblock", "block", "unblock"])
	assert_bool((_ivo.get_node("PlayerInput") as PlayerInput).blocked).is_false()

func test_a_hit_closes_the_map() -> void:
	await _land()
	_menu_input.map_pressed.emit()
	_screens.close_map()
	assert_int(_screens.showing()).is_equal(ScreenRouter.Kind.NONE)
	assert_array(_requests).contains_exactly(["block", "unblock"])

## A hit with the pause open (it cannot happen: the world is held) leaves the pause alone.
func test_close_map_leaves_other_screens_alone() -> void:
	_menu_input.pause_pressed.emit()
	_screens.close_map()
	assert_int(_screens.showing()).is_equal(ScreenRouter.Kind.PAUSE)

func test_a_death_closes_the_map_and_refuses_it() -> void:
	await _land()
	_menu_input.map_pressed.emit()
	_screens.lock()
	assert_int(_screens.showing()).is_equal(ScreenRouter.Kind.NONE)
	_menu_input.map_pressed.emit()
	assert_int(_screens.showing()).is_equal(ScreenRouter.Kind.NONE)
	assert_array(_requests).contains_exactly(["block", "unblock"])

func test_zoom_steps_only_while_the_map_is_open() -> void:
	await _land()
	_menu_input.zoom_pressed.emit(1)
	assert_int(_map.cell_px()).is_equal(MapScreen.CELL_PX_STEPS[MapScreen.OPEN_STEP])
	_menu_input.map_pressed.emit()
	_menu_input.zoom_pressed.emit(1)
	assert_int(_map.cell_px()).is_equal(8)
	_menu_input.zoom_pressed.emit(-1)
	_menu_input.zoom_pressed.emit(-1)
	assert_int(_map.cell_px()).is_equal(2)

## Reopening starts again at the open zoom.
func test_reopening_resets_the_zoom() -> void:
	await _land()
	_menu_input.map_pressed.emit()
	_menu_input.zoom_pressed.emit(-1)
	_menu_input.map_pressed.emit()
	_menu_input.map_pressed.emit()
	assert_int(_map.cell_px()).is_equal(MapScreen.CELL_PX_STEPS[MapScreen.OPEN_STEP])

## User decision 2026-10-06, "Refuse": no map with the Memorina drawn.
func test_the_map_is_refused_with_the_memorina_drawn() -> void:
	await _land()
	_player_input().draw_memorina_pressed.emit()
	for i: int in 30:
		await get_tree().physics_frame
		if _ivo.is_memorina_drawn():
			break
	assert_bool(_ivo.is_memorina_drawn()).is_true()
	_menu_input.map_pressed.emit()
	assert_int(_screens.showing()).is_equal(ScreenRouter.Kind.NONE)
	assert_array(_requests).is_empty()

## A jump pressed in the frame the map opens is dropped, not done under the map.
func test_a_jump_buffered_before_the_open_does_not_fire() -> void:
	await _land()
	_player_input().jump_pressed.emit()
	_menu_input.map_pressed.emit()
	for i: int in 10:
		await get_tree().physics_frame
	assert_bool(_ivo.is_jumping()).is_false()
	assert_bool(_ivo.is_on_floor()).is_true()

func test_an_attack_buffered_before_the_open_does_not_fire() -> void:
	await _land()
	_player_input().attack_pressed.emit()
	_menu_input.map_pressed.emit()
	for i: int in 10:
		await get_tree().physics_frame
	assert_bool(_ivo.is_attacking()).is_false()

## The control: without the map the same buffered press does jump, so the test above can fail.
func test_without_the_map_a_buffered_jump_fires() -> void:
	await _land()
	_player_input().jump_pressed.emit()
	for i: int in 10:
		await get_tree().physics_frame
		if _ivo.is_jumping():
			break
	assert_bool(_ivo.is_jumping()).is_true()

func _player_input() -> PlayerInput:
	return _ivo.get_node("PlayerInput") as PlayerInput

func _land() -> void:
	for i: int in 120:
		await get_tree().physics_frame
		if _ivo.can_open_map():
			return
	fail("Ivo never landed on the test floor")
