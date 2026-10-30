class_name FightWallTest extends GdUnitTestSuite

## A fight wall closes once a guardian fights Ivo and his body is clear of it, stays closed for the fight, and opens when
## the guardian is restored ("Parede de cinza", user, 2026-10-30; GRD-05).

const WALL := preload("res://scenes/world/interactables/fight_wall/fight_wall.tscn")
const FROST := preload("res://scenes/characters/guardians/frost_guardian/frost_guardian.tscn")
const IVO := preload("res://scenes/characters/ivo/ivo.tscn")

## Top of the test floor.
const FLOOR_Y := 30.0

var _holder: Node2D
var _ivo: Player
var _wall: FightWall


func before_test() -> void:
	SaveSystem.begin("", true)
	_holder = auto_free(Node2D.new()) as Node2D
	add_child(_holder)
	var floor_body := StaticBody2D.new()
	floor_body.collision_layer = GroundCollision.COLLISION_LAYER | 2
	floor_body.position = Vector2(0, FLOOR_Y + 10.0)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(4000, 20)
	shape.shape = rect
	floor_body.add_child(shape)
	_holder.add_child(floor_body)
	_wall = WALL.instantiate() as FightWall
	_wall.position = Vector2(-300, FLOOR_Y)
	_holder.add_child(_wall)
	_ivo = IVO.instantiate() as Player
	_ivo.position = Vector2(-300, FLOOR_Y - 30.0)
	_holder.add_child(_ivo)

func after_test() -> void:
	SaveSystem.begin("", true)

func test_it_closes_only_when_fighting_and_clear_and_holds_while_fighting() -> void:
	assert_bool(FightWall.closes(false, false, true)).is_false()
	assert_bool(FightWall.closes(false, true, false)).is_false()
	assert_bool(FightWall.closes(false, true, true)).is_true()
	assert_bool(FightWall.closes(true, true, false)).is_true()
	assert_bool(FightWall.closes(true, false, true)).is_false()

func test_it_waits_for_ivo_to_clear_it_then_holds_until_the_guardian_is_restored() -> void:
	# No Arena: the guardian fights everywhere, so the wall and Ivo both stand in its fight.
	var guardian := FROST.instantiate() as Guardian
	guardian.position = Vector2(400, FLOOR_Y)
	_holder.add_child(guardian)
	await _frames(4)
	assert_bool(_wall.is_closed()).is_false()
	guardian.call(&"_on_player_entered")
	assert_int(guardian.phase()).is_equal(GuardianFight.Phase.PRESSURE)
	await _frames(4)
	assert_bool(_wall.is_closed()).override_failure_message("closed on Ivo standing in it").is_false()
	_ivo.teleport(Vector2(-200, FLOOR_Y - 30.0))
	await _frames(4)
	assert_bool(_wall.is_closed()).is_true()
	assert_bool((_wall.get_node(^"CollisionShape2D") as CollisionShape2D).disabled).is_false()
	# The cure itself is GuardianFight's; here only its end matters.
	(guardian.get(&"_fight") as GuardianFight).call(&"_transition", GuardianFight.Phase.RESTORED)
	await _frames(4)
	assert_bool(_wall.is_closed()).is_false()
	assert_bool((_wall.get_node(^"CollisionShape2D") as CollisionShape2D).disabled).is_true()

func test_its_body_and_curtain_are_its_cells_tall() -> void:
	var tall := WALL.instantiate() as FightWall
	tall.cells = 3
	_holder.add_child(tall)
	assert_vector(tall.body_rect().size).is_equal(Vector2(32, 96))
	assert_vector((tall.get_node(^"Curtain") as ColorRect).size).is_equal(Vector2(32, 96))

## A ceiling wall grows east from its cell, one cell tall.
func test_an_across_wall_grows_east_from_its_cell() -> void:
	var ceiling := WALL.instantiate() as FightWall
	ceiling.cells = 1
	ceiling.across = 8
	ceiling.position = Vector2(1000, 32)
	_holder.add_child(ceiling)
	assert_object(ceiling.body_rect()).is_equal(Rect2(984, 0, 256, 32))
	var shape := ceiling.get_node(^"CollisionShape2D") as CollisionShape2D
	assert_vector(shape.position).is_equal(Vector2(112, -16))

func _frames(count: int) -> void:
	for i: int in count:
		await get_tree().physics_frame
