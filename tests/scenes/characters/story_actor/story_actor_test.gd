class_name StoryActorTest extends GdUnitTestSuite

## An actor enters on its staging's shown child's feet in the clip named like it, walks to a mark and stops exactly on
## it, holds a one-shot on its settle clip, and leaves hidden and disabled.

const DAUGHTER := preload("res://scenes/characters/story_actor/daughter/daughter_actor.tscn")
const FLOOR_Y := 288.0

var _holder: Node2D
var _staging: FactStaging
var _actor: StoryActor


func before_test() -> void:
	SaveSystem.begin("", true)
	_holder = auto_free(Node2D.new()) as Node2D
	add_child(_holder)
	var floor_body := StaticBody2D.new()
	floor_body.collision_layer = GroundCollision.COLLISION_LAYER
	floor_body.position = Vector2(0, FLOOR_Y + 10.0)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(4000, 20)
	shape.shape = rect
	floor_body.add_child(shape)
	_holder.add_child(floor_body)
	_staging = FactStaging.new()
	_staging.name = "Daughter"
	var stage := FactStage.new()
	stage.show = &"Standing"
	_staging.stages = [stage]
	var standing := Sprite2D.new()
	standing.name = "Standing"
	standing.position = Vector2(90, FLOOR_Y)
	_staging.add_child(standing)
	_holder.add_child(_staging)
	_actor = DAUGHTER.instantiate() as StoryActor
	_holder.add_child(_actor)
	_actor.stands_for = _actor.get_path_to(_staging)

func after_test() -> void:
	SaveSystem.begin("", true)

func _frames(count: int) -> void:
	for i: int in count:
		await get_tree().physics_frame

func _driver() -> AnimationDriver:
	return _actor.get_node("AnimationDriver") as AnimationDriver

func test_it_is_hidden_and_still_until_it_enters() -> void:
	assert_bool(_actor.visible).is_false()
	assert_int(_actor.process_mode).is_equal(Node.PROCESS_MODE_DISABLED)
	assert_int(_actor.collision_layer).is_equal(0)

func test_it_enters_on_the_shown_childs_feet_in_its_clip() -> void:
	_actor.enter()
	assert_bool(_actor.visible).is_true()
	assert_bool(_staging.visible).is_false()
	assert_vector(_actor.global_position).is_equal(Vector2(90, FLOOR_Y))
	await _frames(2)
	assert_str(String(_driver().current)).is_equal(String(DaughterAnimationResolver.STANDING))
	assert_int(_actor.facing).is_equal(1)

func test_a_walk_stops_exactly_on_its_mark() -> void:
	_actor.enter()
	_actor.walk_to(58.0, 0.5)
	await _frames(2)
	assert_str(String(_driver().current)).is_equal(String(DaughterAnimationResolver.WALK))
	assert_int(_actor.facing).is_equal(-1)
	for i: int in 240:
		await get_tree().physics_frame
		if not _actor.is_walking():
			break
	assert_bool(_actor.is_walking()).is_false()
	assert_float(_actor.global_position.x).is_equal(58.0)
	assert_float(_actor.global_position.y).is_equal_approx(FLOOR_Y, 0.5)

func test_a_one_shot_settles_on_its_held_clip() -> void:
	_actor.enter()
	_actor.gesture(DaughterAnimationResolver.LIE_DOWN)
	await _frames(2)
	assert_bool(_actor.is_settled()).is_false()
	for i: int in 120:
		await get_tree().physics_frame
		if _actor.is_settled():
			break
	assert_str(String(_driver().current)).is_equal(String(DaughterAnimationResolver.IN_BED_TURNED))

func test_a_landed_gesture_shows_its_settle_at_once() -> void:
	_actor.enter()
	_actor.land_gesture(DaughterAnimationResolver.SIT)
	await _frames(2)
	assert_str(String(_driver().current)).is_equal(String(DaughterAnimationResolver.SEATED))

func test_it_leaves_hidden_and_disabled() -> void:
	_actor.enter()
	await _frames(1)
	_actor.leave()
	assert_bool(_actor.visible).is_false()
	await _frames(1)
	assert_int(_actor.process_mode).is_equal(Node.PROCESS_MODE_DISABLED)

## The hand-over is a cut only if every rest child it can stand for has a clip of the same name.
func test_every_rest_clip_matches_a_house_staging_child() -> void:
	var house := (load("res://scenes/world/rooms/home_village/contents/village_house_contents.tscn") as PackedScene).instantiate()
	var staging := house.get_node("Props/Daughter") as FactStaging
	for child: Node in staging.get_children():
		var clip := StringName(String(child.name).to_snake_case())
		assert_bool(DaughterAnimationResolver.CLIPS.has(clip)).override_failure_message(String(child.name)).is_true()
	house.free()
