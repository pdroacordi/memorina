class_name GroundSeatTest extends GdUnitTestSuite

## A ground seat sits Ivo on the ground (`sit_ground`), facing its way, and plays its scene only while its gates hold and
## the scene is unseen (systems/life-benches-death).

const SEAT := preload("res://scenes/world/interactables/bench/ground_seat.tscn")
const IVO := preload("res://scenes/characters/ivo/ivo.tscn")
const C := preload("res://tests/resources/cutscene/cutscene_fixture.gd")
const D := preload("res://tests/resources/dialogue/dialogue_fixture.gd")


func before_test() -> void:
	SaveSystem.begin("", true)

func after_test() -> void:
	SaveSystem.begin("", true)

func test_it_seats_him_on_the_ground() -> void:
	var seat := auto_free(SEAT.instantiate()) as GroundSeat
	seat.facing = -1
	add_child(seat)
	var ivo := auto_free(IVO.instantiate()) as Player
	add_child(ivo)
	await get_tree().physics_frame
	assert_bool(seat.seat().ground).is_true()
	assert_str(String(seat.seat().bench_id)).is_empty()
	ivo.sit(seat.seat())
	assert_bool(ivo.sits_on_ground()).is_true()
	assert_int(ivo.facing).is_equal(-1)
	assert_str(String((ivo.get_node("AnimationResolver") as AnimationResolver).resolve())).is_equal(
			String(PlayerAnimationResolver.SIT_GROUND))

## STORY-07: on the stone a scene's MEMORINA pose raises the flute seated, and ending the pose lowers it.
func test_seated_on_a_stone_the_memorina_pose_plays_and_lowers_the_flute_seated() -> void:
	var seat := auto_free(SEAT.instantiate()) as GroundSeat
	seat.ground = false
	add_child(seat)
	var ivo := auto_free(IVO.instantiate()) as Player
	add_child(ivo)
	await get_tree().physics_frame
	ivo.sit(seat.seat())
	var resolver := ivo.get_node("AnimationResolver") as AnimationResolver
	var driver := ivo.get_node("AnimationDriver") as AnimationDriver
	assert_str(String(resolver.resolve())).is_equal(String(PlayerAnimationResolver.SIT))
	ivo.stage_pose(DialogueBeat.Pose.MEMORINA)
	assert_str(String(resolver.resolve())).is_equal(String(PlayerAnimationResolver.SIT_MEMORINA_RAISE))
	driver.play(PlayerAnimationResolver.SIT_MEMORINA)
	assert_str(String(resolver.resolve())).is_equal(String(PlayerAnimationResolver.SIT_MEMORINA))
	ivo.stage_pose(DialogueBeat.Pose.NONE)
	assert_bool(ivo.is_sitting()).is_true()
	assert_str(String(resolver.resolve())).is_equal(String(PlayerAnimationResolver.SIT_MEMORINA_LOWER))

## A pose that ends mid-raise lowers the flute from where it is instead of cutting to the rest.
func test_a_pose_ended_mid_raise_lowers_the_flute() -> void:
	var seat := auto_free(SEAT.instantiate()) as GroundSeat
	seat.ground = false
	add_child(seat)
	var ivo := auto_free(IVO.instantiate()) as Player
	add_child(ivo)
	await get_tree().physics_frame
	ivo.sit(seat.seat())
	var resolver := ivo.get_node("AnimationResolver") as AnimationResolver
	var driver := ivo.get_node("AnimationDriver") as AnimationDriver
	ivo.stage_pose(DialogueBeat.Pose.MEMORINA)
	driver.play(resolver.resolve())
	assert_str(String(driver.current)).is_equal(String(PlayerAnimationResolver.SIT_MEMORINA_RAISE))
	ivo.stage_pose(DialogueBeat.Pose.NONE)
	assert_str(String(resolver.resolve())).is_equal(String(PlayerAnimationResolver.SIT_MEMORINA_LOWER))

func test_it_wants_its_scene_only_while_gated_and_unseen() -> void:
	var seat := auto_free(SEAT.instantiate()) as GroundSeat
	seat.cutscene = C.scene(&"seat_scene", [C.wait(0.1)])
	seat.when = [D.fact(SaveFact.Kind.ITEM, &"", Enums.PlayerItem.MEMORINA)]
	add_child(seat)
	assert_bool(seat.wants(SaveSystem.player_data)).is_false()
	SaveSystem.set_item_owned(Enums.PlayerItem.MEMORINA, true)
	assert_bool(seat.wants(SaveSystem.player_data)).is_true()
	SaveSystem.mark_scene_seen(&"seat_scene")
	assert_bool(seat.wants(SaveSystem.player_data)).is_false()
