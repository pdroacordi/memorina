class_name SeatGateTest extends GdUnitTestSuite

## A SeatGate opens its seat while its gates hold: a closed seat refuses Down and hides its prompt, and the pick follows
## the save (architecture/story-07-epilogue).

const BENCH := preload("res://scenes/world/interactables/bench/bench.tscn")
const GROUND := preload("res://scenes/world/interactables/bench/ground_seat.tscn")
const IVO := preload("res://scenes/characters/ivo/ivo.tscn")
const D := preload("res://tests/resources/dialogue/dialogue_fixture.gd")
const FLOOR_Y := 30.0

var _holder: Node2D
var _ivo: Player


func before_test() -> void:
	SaveSystem.begin("", true)
	_holder = auto_free(Node2D.new()) as Node2D
	add_child(_holder)
	var floor_body := StaticBody2D.new()
	floor_body.collision_layer = 2
	floor_body.position = Vector2(0, FLOOR_Y + 10.0)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(2000, 20)
	shape.shape = rect
	floor_body.add_child(shape)
	_holder.add_child(floor_body)

func after_test() -> void:
	SaveSystem.begin("", true)

func _bench_gated_on_memorina() -> Bench:
	var bench := BENCH.instantiate() as Bench
	bench.bench_id = &"gated_bench"
	bench.position = Vector2(0, FLOOR_Y)
	_holder.add_child(bench)
	var gate := SeatGate.new()
	gate.seat = bench.get_node("Seat") as Seat
	gate.when = [D.fact(SaveFact.Kind.ITEM, &"", Enums.PlayerItem.MEMORINA)]
	_holder.add_child(gate)
	return bench

func _land_ivo() -> void:
	_ivo = IVO.instantiate() as Player
	_ivo.position = Vector2(0, FLOOR_Y - 30.0)
	_holder.add_child(_ivo)
	for frame: int in range(0, 20):
		await get_tree().physics_frame

func _press_down() -> void:
	(_ivo.get_node("PlayerInput") as PlayerInput).look_down_pressed.emit()
	for frame: int in range(0, 4):
		await get_tree().physics_frame

func test_a_closed_seat_refuses_down_and_hides_its_prompt() -> void:
	var bench := _bench_gated_on_memorina()
	var seat := bench.get_node("Seat") as Seat
	assert_bool(seat.open).is_false()
	await _land_ivo()
	assert_bool(seat.has_body_in_reach()).is_true()
	assert_bool((bench.get_node("Prompt") as CanvasItem).visible).is_false()
	await _press_down()
	assert_bool(seat.is_occupied()).is_false()
	SaveSystem.set_item_owned(Enums.PlayerItem.MEMORINA, true)
	assert_bool(seat.open).is_true()
	assert_bool((bench.get_node("Prompt") as CanvasItem).visible).is_true()
	await _press_down()
	assert_bool(seat.is_occupied()).is_true()

func test_two_seats_on_one_spot_sit_him_on_the_open_one() -> void:
	var bench := _bench_gated_on_memorina()
	var stone := GROUND.instantiate() as GroundSeat
	stone.ground = false
	stone.position = Vector2(0, FLOOR_Y)
	_holder.add_child(stone)
	var gate := SeatGate.new()
	gate.seat = stone.seat()
	gate.unless = [D.fact(SaveFact.Kind.ITEM, &"", Enums.PlayerItem.MEMORINA)]
	_holder.add_child(gate)
	await _land_ivo()
	assert_bool(stone.seat().ground).is_false()
	await _press_down()
	assert_bool(stone.seat().is_occupied()).is_true()
	assert_bool(_ivo.sits_on_ground()).is_false()
	assert_bool((bench.get_node("Seat") as Seat).is_occupied()).is_false()

## Seated on one seat of a shared spot, another that opens there shows no prompt until he stands (the garden's stone
## after the epilogue).
func test_a_seat_beside_the_one_he_sits_on_shows_no_prompt() -> void:
	var bench := _bench_gated_on_memorina()
	var prompt := bench.get_node("Prompt") as CanvasItem
	var stone := GROUND.instantiate() as GroundSeat
	stone.ground = false
	stone.position = Vector2(0, FLOOR_Y)
	_holder.add_child(stone)
	await _land_ivo()
	await _press_down()
	assert_bool(stone.seat().is_occupied()).is_true()
	SaveSystem.set_item_owned(Enums.PlayerItem.MEMORINA, true)
	assert_bool(prompt.visible).is_false()
	(_ivo.get_node("Sit") as SitComponent).stand()
	await get_tree().physics_frame
	assert_bool(prompt.visible).is_true()
