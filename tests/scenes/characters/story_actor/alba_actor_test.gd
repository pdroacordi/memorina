class_name AlbaActorTest extends GdUnitTestSuite

## Alba's actor has every clip its resolver names, cut whole from her strips; her figure shows each clip with the same
## frames and pace, so a staging child hands over to the actor as a cut; her edge draws plain art until a fray.

const ACTOR := preload("res://scenes/characters/story_actor/alba/alba_actor.tscn")
const FIGURE := preload("res://scenes/characters/story_actor/alba/alba_figure.tscn")
const FLOOR_Y := 288.0
const SPRITE_TRACKS: Array[String] = ["texture", "hframes", "frame", "offset", "position"]

var _holder: Node2D
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
	_actor = ACTOR.instantiate() as StoryActor
	_holder.add_child(_actor)

func after_test() -> void:
	SaveSystem.begin("", true)

func _player() -> AnimationPlayer:
	return _actor.get_node("AnimationPlayer") as AnimationPlayer

func _sprite() -> Sprite2D:
	return _actor.get_node("Sprite2D") as Sprite2D

func _key(animation: Animation, prop: String, index: int = 0) -> Variant:
	var track := animation.find_track(NodePath("Sprite2D:" + prop), Animation.TYPE_VALUE)
	return animation.track_get_key_value(track, index)

func _stage(child: Node2D) -> FactStaging:
	var staging := FactStaging.new()
	var stage := FactStage.new()
	stage.show = child.name
	staging.stages = [stage]
	staging.add_child(child)
	_holder.add_child(staging)
	_actor.stands_for = _actor.get_path_to(staging)
	return staging

func test_every_clip_is_cut_whole_from_a_strip() -> void:
	for clip: StringName in AlbaAnimationResolver.CLIPS:
		assert_bool(_player().has_animation(clip)).override_failure_message(String(clip)).is_true()
		var animation := _player().get_animation(clip)
		for prop: String in SPRITE_TRACKS:
			assert_int(animation.find_track(NodePath("Sprite2D:" + prop), Animation.TYPE_VALUE)) \
					.override_failure_message("%s keys no %s" % [clip, prop]).is_not_equal(-1)
		var texture := _key(animation, "texture") as Texture2D
		var hframes := int(_key(animation, "hframes"))
		var frame_width := texture.get_width() / hframes
		assert_int(frame_width * hframes).override_failure_message(String(clip)).is_equal(texture.get_width())
		assert_int(texture.get_height()).is_equal(64)
		assert_vector(_key(animation, "offset") as Vector2).is_equal(Vector2(-frame_width / 2.0, -62.0))
		var frames := animation.find_track(^"Sprite2D:frame", Animation.TYPE_VALUE)
		for index: int in animation.track_get_key_count(frames):
			assert_int(int(animation.track_get_key_value(frames, index))).is_less(hframes)

func test_every_rest_clip_loops_and_every_one_shot_settles_on_a_loop() -> void:
	for clip: StringName in AlbaAnimationResolver.RESTS:
		assert_int(_player().get_animation(clip).loop_mode).override_failure_message(String(clip)) \
				.is_equal(Animation.LOOP_LINEAR)
	for clip: StringName in AlbaAnimationResolver.SETTLES:
		assert_int(_player().get_animation(clip).loop_mode).is_equal(Animation.LOOP_NONE)
		var settle: StringName = AlbaAnimationResolver.SETTLES[clip]
		assert_int(_player().get_animation(settle).loop_mode).is_equal(Animation.LOOP_LINEAR)

## A staging child is the figure in the clip named like it: the same frames at the same pace as the actor's clip.
func test_the_figure_shows_every_clip_as_the_actor_does() -> void:
	var figure := auto_free(FIGURE.instantiate()) as AnimatedSprite2D
	var frames := figure.sprite_frames
	for clip: StringName in AlbaAnimationResolver.CLIPS:
		assert_bool(frames.has_animation(clip)).override_failure_message(String(clip)).is_true()
		var animation := _player().get_animation(clip)
		var texture := _key(animation, "texture") as Texture2D
		var width := texture.get_width() / int(_key(animation, "hframes"))
		var track := animation.find_track(^"Sprite2D:frame", Animation.TYPE_VALUE)
		assert_int(frames.get_frame_count(clip)).override_failure_message(String(clip)) \
				.is_equal(animation.track_get_key_count(track))
		assert_bool(frames.get_animation_loop(clip)).is_equal(animation.loop_mode == Animation.LOOP_LINEAR)
		for index: int in frames.get_frame_count(clip):
			var atlas := frames.get_frame_texture(clip, index) as AtlasTexture
			assert_object(atlas.atlas).is_same(texture)
			var frame := int(animation.track_get_key_value(track, index))
			assert_that(atlas.region).override_failure_message("%s %d" % [clip, index]) \
					.is_equal(Rect2(frame * width, 0, width, 64))
		if animation.track_get_key_count(track) > 1:
			var step := animation.track_get_key_time(track, 1)
			assert_float(frames.get_animation_speed(clip)).is_equal_approx(1.0 / step, 0.001)
	assert_bool(figure.centered).is_true()
	assert_vector(figure.offset).is_equal(Vector2(0, -30))

## Her figure flipped faces west, so the actor entering on it faces west too, in the clip named like the child.
func test_it_enters_on_a_flipped_figure_facing_its_way() -> void:
	var stone := FIGURE.instantiate() as StagedStrip
	stone.name = "Stone"
	stone.loop = AlbaAnimationResolver.STONE
	stone.flip_h = true
	stone.position = Vector2(200, FLOOR_Y)
	var staging := _stage(stone)
	_actor.enter()
	assert_bool(staging.visible).is_false()
	assert_vector(_actor.global_position).is_equal(Vector2(200, FLOOR_Y))
	assert_int(_actor.facing).is_equal(-1)
	assert_bool(_sprite().flip_h).is_true()
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert_str(String((_actor.get_node("AnimationDriver") as AnimationDriver).current)).is_equal("stone")

func test_a_turn_settles_turned() -> void:
	var standing := Sprite2D.new()
	standing.name = "PoolBack"
	standing.position = Vector2(200, FLOOR_Y)
	_stage(standing)
	_actor.enter()
	_actor.gesture(AlbaAnimationResolver.TURN)
	for i: int in 180:
		await get_tree().physics_frame
		if _actor.is_settled():
			break
	assert_str(String((_actor.get_node("AnimationDriver") as AnimationDriver).current)).is_equal("turned")

## Her edge stays in the root canvas: plain art at rest, the edge material only while a fray agitates it.
func test_her_edge_carries_its_material_only_while_agitated() -> void:
	var edge := _actor.get_node("CorruptionEdge") as CorruptionEdge
	assert_bool(edge.creature_pass).is_false()
	assert_float(edge.rest_fray).is_equal(0.0)
	assert_object(_sprite().material).is_null()
	edge.agitate(true)
	assert_object(_sprite().material).is_instanceof(ShaderMaterial)
	edge.agitate(false)
	assert_object(_sprite().material).is_null()
