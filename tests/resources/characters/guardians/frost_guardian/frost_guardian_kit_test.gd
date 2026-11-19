class_name FrostGuardianKitTest extends GdUnitTestSuite

## The Frost Guardian's GRD-14 kit as data: its strings, what joins at each stage, the stage table and the charge-back
## that only an owned roll allows (systems/guardians, "The Frost Guardian's fight (GRD-14)").

const STATS := preload("res://resources/characters/guardians/frost_guardian/frost_guardian_stats.tres")
const SWIPE := preload("res://resources/characters/guardians/frost_guardian/frost_swipe.tres")
const SWIPE_AGAIN := preload("res://resources/characters/guardians/frost_guardian/frost_swipe_again.tres")
const SLAM := preload("res://resources/characters/guardians/frost_guardian/frost_slam.tres")
const CHARGE := preload("res://resources/characters/guardians/frost_guardian/frost_charge.tres")
const CHARGE_BACK := preload("res://resources/characters/guardians/frost_guardian/frost_charge_back.tres")
const ICICLE_FALL := preload("res://resources/characters/guardians/frost_guardian/frost_icicle_fall.tres")
const BODY_DROP := preload("res://resources/characters/guardians/frost_guardian/frost_body_drop.tres")
const FROST_SCENE := "res://scenes/characters/guardians/frost_guardian/frost_guardian.tscn"
const IVO_SCENE := "res://scenes/characters/ivo/ivo.tscn"
## Px from Ivo to the view's edge: the camera centres him in a 640 px view.
const VIEW_HALF := 320.0
## Px of the golem's drawn half width (fists to 120 px wide; systems/guardians, "Our own art").
const BODY_HALF := 60.0
## Ivo's single jump apex, px: the first guardian may be fought with no double jump.
const JUMP_APEX := 144.0
## Ivo's single jump traced in play: feet height (px) by s after take-off, 1.2 s in the air, read linearly between
## the samples (bugs/the-frost-slam-jump-window-closes-before-the-fists-fall).
const JUMP: Array[Vector2] = [Vector2(0.0, 0.0), Vector2(0.133, 58.9), Vector2(0.167, 71.3), Vector2(0.233, 93.3),
		Vector2(0.267, 102.9), Vector2(0.3, 111.6), Vector2(0.6, 141.5), Vector2(0.9, 115.3), Vector2(0.933, 107.8),
		Vector2(1.2, 0.0)]
## Px from Ivo's feet to the foot of his hurtbox.
const HURT_FOOT := 6.0
## Scaled s a landed Ivo has before a box may reach him: a ground jump's rise past a fist (0.30 s) and a little more.
const LANDED_LEAD := 0.35
## Px of the arena's open height (lake_frost_arena.room: floor row 9 under the ceiling row 0) and of Ivo's body.
const ARENA_HEADROOM := 256.0
const IVO_HEIGHT := 54.0
## Px the pogo reaches below Ivo's feet, and the fall, px, it must leave him to strike the head again before the
## body hurts (about 0.29 s of falling).
const POGO_REACH := 28.0
const POGO_ROOM := 40.0


func test_the_swipe_strings_into_a_second_swipe_and_the_slam() -> void:
	assert_object(_link(SWIPE, 0, 1)).is_same(SWIPE_AGAIN)
	assert_object(_link(SWIPE_AGAIN, 0, 2)).is_same(SLAM)
	assert_object(_link(SLAM, 0, 3)).override_failure_message("the slam ends the string").is_null()
	# Backed off past the slam's 86 px after the second swipe, the string ends.
	assert_object(GuardianRepertoire.next_link(SWIPE_AGAIN, 0, 1.0, 2, 3,
			func(attack: GuardianAttack) -> bool: return attack != SLAM, false, false, func() -> float: return 0.0)).is_null()

func test_later_stages_make_the_swipe_string_certain() -> void:
	var never := func() -> float: return 0.99
	var last := STATS.stages[2]
	assert_object(GuardianRepertoire.next_link(SWIPE, 2, last.chain_scale, 1, last.max_links, _always, false, false,
			never)).is_same(SWIPE_AGAIN)
	assert_object(GuardianRepertoire.next_link(SWIPE_AGAIN, 2, last.chain_scale, 2, last.max_links, _always, false,
			false, never)).is_same(SLAM)

## The second swipe steps in after an Ivo who backed off past the first swipe's reach, stopping where its box lands,
## and stays put when he is already close (playtests/2026-11-18-grd14-frost-feel: 0 of ~80 chained).
func test_the_second_swipe_steps_in_after_a_retreating_ivo() -> void:
	var step := SWIPE_AGAIN.motion as DashMotion
	assert_float(SWIPE_AGAIN.attack_range).is_greater(SWIPE.attack_range)
	var distance := 40.0
	while distance <= SWIPE_AGAIN.attack_range:
		var ctx := _dash_ctx(Vector2(400.0, 400.0), Vector2(400.0 + distance, 400.0))
		ctx.duration = SWIPE_AGAIN.duration
		var left := distance - step.plan(ctx).end_offset().x
		assert_float(left).override_failure_message("from %.0f it ends %.0f px off" % [distance, left]).is_less_equal(SWIPE.attack_range)
		assert_float(left).override_failure_message("from %.0f it steps into him" % distance).is_greater_equal(minf(distance, -step.past))
		distance += 8.0

## The charge teaches the roll and never chains while it does; once the roll is owned, from stage 1, it turns after
## passing Ivo and charges back, wall or not ("Turn after passing Ivo (Recommended)", user, 2026-11-18). The
## charge-back carries no recall, so the charge stays the only move that teaches.
func test_the_owned_charge_turns_back_after_passing_ivo() -> void:
	assert_object(CHARGE.recall).is_not_null()
	assert_object(CHARGE_BACK.recall).is_null()
	for wall: bool in [false, true]:
		assert_object(_charge_link(1, false, wall)).override_failure_message("chained while it teaches the roll").is_null()
		assert_object(_charge_link(0, true, wall)).override_failure_message("chained at stage 0").is_null()
		assert_object(_charge_link(1, true, wall)).override_failure_message("wall %s" % wall).is_same(CHARGE_BACK)
	assert_bool(CHARGE_BACK.body_contact).is_false()
	# Ivo is usually still in the air from jumping the fists when the charge ends: the link must reach him there.
	assert_float(CHARGE_BACK.attack_height).is_greater_equal(JUMP_APEX)

## An Ivo who jumped the charge's fists as late as still clears them has landed, with LANDED_LEAD to spare, before the
## charge-back's box can reach him, from any distance the charge is thrown
## (bugs/the-frost-charge-back-after-a-far-charge-hits-ivo-as-he-lands-from-jumping-it).
func test_an_ivo_who_jumped_the_charge_has_landed_before_the_charge_back() -> void:
	var golem := auto_free(load(FROST_SCENE).instantiate()) as Node
	var opens := _window(_clip(golem, CHARGE_BACK.clip_index)).x
	var rise := _rise_to(100.0)
	var air := JUMP[JUMP.size() - 1].x
	var reach_from := CHARGE.duration + CHARGE_BACK.telegraph + opens
	var distance := 42.0
	while distance <= CHARGE.attack_range:
		var landed := CHARGE.seconds_to_blow(0.0, distance) - rise + air
		assert_float(reach_from - landed).override_failure_message("thrown from %.0f: %.2f s after landing" % [
				distance, reach_from - landed]).is_greater_equal(LANDED_LEAD)
		distance += 8.0

## The charge-back stops past Ivo inside the swipe's reach, at its own speed, so it ends on screen where the golem's
## moves reach him; against a wall it stops short of him instead.
func test_the_charge_back_ends_within_reach_of_ivo() -> void:
	var dash := CHARGE_BACK.motion as DashMotion
	var distance := 40.0
	while distance <= CHARGE_BACK.attack_range:
		var ctx := _dash_ctx(Vector2(400.0, 400.0), Vector2(400.0 + distance, 400.0))
		var end := ctx.feet.x + dash.plan(ctx).end_offset().x
		assert_float(absf(end - ctx.target.x)).override_failure_message("from %.0f" % distance).is_less(SWIPE.attack_range)
		assert_float(dash.planned_speed(ctx)).override_failure_message("sped up from %.0f" % distance).is_less_equal(dash.speed + 0.01)
		distance += 8.0
	var cornered := _dash_ctx(Vector2(1000.0, 400.0), Vector2(1210.0, 400.0))
	assert_float(cornered.feet.x + dash.plan(cornered).end_offset().x).is_equal(1210.0 - dash.past)

## The charge's recall is timed by its lunge: it opens a set lead before the fists reach Ivo, from any distance.
func test_the_charge_recall_opens_a_lead_before_the_fists() -> void:
	assert_float(CHARGE.seconds_to_blow(0.0, 100.0)).is_equal(CHARGE.lunge_delay)
	assert_float(CHARGE.seconds_to_blow(0.5, CHARGE.recall_reach + CHARGE.lunge_speed * 0.2)).is_equal_approx(0.2, 0.001)
	assert_float(CHARGE.seconds_to_blow(0.9, 50.0)).is_equal(0.0)

func test_the_owned_charge_is_an_ordinary_move() -> void:
	assert_float(CHARGE.weight_for(false)).is_equal(0.0)
	assert_float(CHARGE.weight_for(true)).is_equal(0.6)
	assert_int(CHARGE.damage_for(true)).is_equal(1)

## The slam's wave makes Ivo jump: it never follows a string it ended, or it is all he sees.
## The owned charge runs about 300 px past where Ivo stood, where only it reaches him again: it never follows itself.
func test_the_slam_and_the_charge_never_follow_themselves() -> void:
	assert_bool(SLAM.repeats).is_false()
	assert_bool(CHARGE.repeats).is_false()

## A single jump clears the slam ("Jump clears the raised fists (Recommended)", user, 2026-11-18): only the fists on
## the floor hit, and Ivo's traced jump taken any time from the "both fists up" pose to 0.1 s before they fall clears
## them (bugs/the-frost-slam-jump-window-closes-before-the-fists-fall).
func test_a_jump_clears_the_slam() -> void:
	var golem := auto_free(load(FROST_SCENE).instantiate()) as Node
	var clip := _clip(golem, SLAM.clip_index)
	var window := _window(clip)
	var positions := clip.find_track(^"Hitbox/CollisionShape2D:position", Animation.TYPE_VALUE)
	var scales := clip.find_track(^"Hitbox/CollisionShape2D:scale", Animation.TYPE_VALUE)
	var highest := 0.0
	var t := window.x
	while t < window.y:
		var keyed_y: float = (clip.value_track_interpolate(positions, t) as Vector2).y
		var half: float = 10.0 * (clip.value_track_interpolate(scales, t) as Vector2).y
		highest = maxf(highest, -(keyed_y - half))
		t += 1.0 / 60.0
	assert_float(SLAM.attack_height).is_less_equal(highest - HURT_FOOT)
	# The pose: the wind-up's "both fists up" frame (slam 4), in s before the strike.
	var windup := _state_clip(golem, GuardianAnimationResolver.windup_clip_for(SLAM.windup_index))
	var frames := windup.find_track(^"Sprite2D:frame", Animation.TYPE_VALUE)
	var pose := INF
	for key: int in windup.track_get_key_count(frames):
		if int(windup.track_get_key_value(frames, key)) == 4:
			pose = windup.track_get_key_time(frames, key) - SLAM.telegraph
	assert_float(pose).is_less(0.0)
	# The pose shows long enough before the fists for a human to see it and jump.
	assert_float(window.x - 0.1 - pose).is_greater_equal(0.35)
	var take_off := pose
	while take_off <= window.x - 0.1:
		var at := window.x
		while at < window.y:
			assert_float(_feet(at - take_off) + HURT_FOOT).override_failure_message(
					"a jump at %.2f s is under the fists at %.2f s" % [take_off, at]).is_greater(highest)
			at += 1.0 / 60.0
		take_off += 0.01

## The shadow covers every spot the body coming down or its landing box reaches, on both sides
## (playtests/2026-11-18-grd14-frost-feel: the body reached about 20 px past it on its approach side).
func test_the_body_drop_shadow_covers_its_whole_reach() -> void:
	var golem := auto_free(load(FROST_SCENE).instantiate()) as Node
	var ivo := auto_free(load(IVO_SCENE).instantiate()) as Node
	var hurt := _area_shape(ivo, ^"Hurtbox")
	var shadow := auto_free(BODY_DROP.spawns[0].scene.instantiate()) as FloorShadow
	var ivo_half := (hurt.shape as Shape2D).get_rect().size.x * 0.5
	var distance := 60.0
	while distance <= BODY_DROP.attack_range:
		var ctx := MotionContext.new()
		ctx.target = Vector2(distance, 0.0)
		ctx.duration = BODY_DROP.duration
		var path := BODY_DROP.motion.plan(ctx)
		var landing := path.end_offset().x
		var reach := 0.0
		for side: float in [-1.0, 1.0]:
			var off := 0.0
			while off < 200.0 and _drop_touches(golem, path, hurt, landing + side * off):
				off += 2.0
			reach = maxf(reach, off)
		assert_float(shadow.width * 0.5 + ivo_half).override_failure_message("from %.0f the body reaches %.0f px" % [
				distance, reach]).is_greater_equal(reach)
		distance += 20.0

## "O pogo é a brecha" (user, 2026-10-29) holds in the arena: under its ceiling, an Ivo bounced off the golem's head
## falls far enough to strike it again before the contact box reaches him
## (bugs/the-frost-arena-ceiling-leaves-26-px-over-the-golems-head-so-a-pogo-bounce-falls-back-into-contact).
func test_a_pogo_has_room_over_the_head() -> void:
	var golem := auto_free(load(FROST_SCENE).instantiate()) as Node
	var hurt := _area_shape(golem, ^"Hurtbox")
	var contact := _area_shape(golem, ^"ContactHitbox")
	var hurt_top := -(hurt.xform as Transform2D).origin.y + (hurt.shape as Shape2D).get_rect().size.y * 0.5
	var contact_top := -(contact.xform as Transform2D).origin.y + (contact.shape as Shape2D).get_rect().size.y * 0.5
	var highest_feet := minf(ARENA_HEADROOM - IVO_HEIGHT, hurt_top + POGO_REACH)
	var lowest_feet := contact_top - HURT_FOOT
	assert_float(highest_feet).is_greater(hurt_top)
	assert_float(highest_feet - lowest_feet).is_greater_equal(POGO_ROOM)

func test_the_new_moves_join_at_their_stage() -> void:
	assert_int(GuardianRepertoire.available(STATS.attacks, 0).size()).is_equal(3)
	assert_bool(GuardianRepertoire.available(STATS.attacks, 1).has(ICICLE_FALL)).is_true()
	assert_bool(GuardianRepertoire.available(STATS.attacks, 1).has(BODY_DROP)).is_false()
	assert_bool(GuardianRepertoire.available(STATS.attacks, 2).has(BODY_DROP)).is_true()

func test_each_stage_is_harder() -> void:
	assert_int(STATS.stages.size()).is_equal(STATS.cycles_to_restore)
	for i: int in range(1, STATS.stages.size()):
		assert_float(STATS.stages[i].cooldown_scale).is_less(STATS.stages[i - 1].cooldown_scale)
		assert_float(STATS.stages[i].chain_scale).is_greater(STATS.stages[i - 1].chain_scale)

func test_every_move_has_a_wind_up_a_recovery_and_a_short_cooldown() -> void:
	for attack: GuardianAttack in GuardianMoveGraph.moves(STATS):
		var label := attack.resource_path.get_file()
		assert_int(attack.windup_index).override_failure_message("%s has no wind-up" % label).is_greater_equal(0)
		assert_float(attack.recovery).override_failure_message("%s has no recovery" % label).is_greater_equal(0.5)
		assert_float(attack.cooldown).override_failure_message(label).is_between(0.3, 0.9)

## Every move is thrown from where its wind-up is on screen with Ivo centred.
func test_every_move_is_thrown_from_on_screen() -> void:
	for attack: GuardianAttack in GuardianMoveGraph.moves(STATS):
		assert_float(attack.attack_range + BODY_HALF).override_failure_message(attack.resource_path.get_file()) \
				.is_less_equal(VIEW_HALF)

## Each wind-up slot belongs to one kind of move, so each reads as its own pose; the slam and the icicle fall, whose
## answers are opposite (jump in place, keep moving), open on different frames.
func test_each_kind_of_move_winds_up_its_own_way() -> void:
	var owners := {}
	for attack: GuardianAttack in GuardianMoveGraph.moves(STATS):
		var kind := attack.clip_index
		if owners.has(attack.windup_index):
			assert_int(owners[attack.windup_index]).override_failure_message("%s shares a wind-up" % attack.resource_path.get_file()) \
					.is_equal(kind)
		owners[attack.windup_index] = kind
	var golem := auto_free(load(FROST_SCENE).instantiate()) as Node
	var slam := _state_clip(golem, GuardianAnimationResolver.windup_clip_for(SLAM.windup_index))
	var icicles := _state_clip(golem, GuardianAnimationResolver.windup_clip_for(ICICLE_FALL.windup_index))
	assert_bool(_first_look(slam) == _first_look(icicles)).override_failure_message("the slam and the icicle fall open alike").is_false()

## A far Ivo draws the moves that reach him by weight, and the icicle fall was 30-53 % of the later stages' moves
## (playtests/2026-11-18-grd14-frost-feel): it weighs least of the far moves.
func test_the_icicle_fall_weighs_least_of_the_far_moves() -> void:
	for attack: GuardianAttack in GuardianMoveGraph.moves(STATS):
		if attack != ICICLE_FALL and attack.attack_range >= ICICLE_FALL.attack_range and attack.weight_for(true) > 0.0:
			var label := attack.resource_path.get_file()
			assert_float(ICICLE_FALL.weight).override_failure_message(label).is_less(attack.weight_for(true))

## Frost may be the first guardian: everything it sends along the floor is cleared by a single jump.
func test_its_floor_waves_stay_under_a_single_jump() -> void:
	for attack: GuardianAttack in [SLAM, BODY_DROP]:
		for spawn: GuardianSpawn in attack.spawns:
			var kind := auto_free(spawn.scene.instantiate()) as SpawnedAttack
			if kind is FloorRunner:
				assert_float((kind as FloorRunner).height).is_less(JUMP_APEX * 0.5)

## The body drop's shadow marks where it comes down, through its fall, and its shockwave answers the landing.
func test_the_body_drop_marks_its_landing_through_the_fall() -> void:
	var leap := BODY_DROP.motion as LeapMotion
	assert_int(leap.target).is_equal(LeapMotion.Target.IVO_SPOT)
	var shadow := BODY_DROP.spawns[0]
	assert_int(shadow.placement).is_equal(GuardianSpawn.Placement.AT_LANDING)
	var kind := auto_free(shadow.scene.instantiate()) as SpawnedAttack
	assert_float(shadow.at + kind.warn).is_greater_equal(leap.delay + leap.air_time)
	assert_bool(BODY_DROP.spawns[1].on_landing).is_true()

## Whether the body drop's contact or landing box touches an Ivo standing at `x` along `path`, on its way down.
func _drop_touches(golem: Node, path: MotionPath, hurt: Dictionary, x: float) -> bool:
	var contact := _area_shape(golem, ^"ContactHitbox")
	var box := _area_shape(golem, ^"Hitbox")
	var clip := _clip(golem, BODY_DROP.clip_index)
	var window := _window(clip)
	var positions := clip.find_track(^"Hitbox/CollisionShape2D:position", Animation.TYPE_VALUE)
	var scales := clip.find_track(^"Hitbox/CollisionShape2D:scale", Animation.TYPE_VALUE)
	var ivo := Transform2D(0.0, Vector2(x, 0.0)) * (hurt.xform as Transform2D)
	# From the apex on: the way down is what the shadow warns of; the take-off is beside the golem's own feet.
	var leap := BODY_DROP.motion as LeapMotion
	var t := leap.delay + leap.air_time * 0.5
	while t <= BODY_DROP.duration:
		var at := Transform2D(0.0, path.at(t))
		if (contact.shape as Shape2D).collide(at * (contact.xform as Transform2D), hurt.shape, ivo):
			return true
		if t >= window.x and t < window.y:
			var keyed := Transform2D(0.0, clip.value_track_interpolate(scales, t), 0.0, clip.value_track_interpolate(positions, t))
			if (box.shape as Shape2D).collide(at * keyed, hurt.shape, ivo):
				return true
		t += 1.0 / 60.0
	return false

## The texture and frame a clip opens on.
func _first_look(clip: Animation) -> String:
	var texture := clip.find_track(^"Sprite2D:texture", Animation.TYPE_VALUE)
	var frame := clip.find_track(^"Sprite2D:frame", Animation.TYPE_VALUE)
	return "%s/%d" % [(clip.track_get_key_value(texture, 0) as Texture2D).resource_path, clip.track_get_key_value(frame, 0)]

## Feet height, px, `t` s after take-off on the traced jump.
func _feet(t: float) -> float:
	if t <= 0.0 or t >= JUMP[JUMP.size() - 1].x:
		return 0.0
	for i: int in range(1, JUMP.size()):
		if t <= JUMP[i].x:
			return lerpf(JUMP[i - 1].y, JUMP[i].y, (t - JUMP[i - 1].x) / (JUMP[i].x - JUMP[i - 1].x))
	return 0.0

## S after take-off until the foot of Ivo's hurtbox clears `height` px.
func _rise_to(height: float) -> float:
	var t := 0.0
	while _feet(t) + HURT_FOOT <= height:
		t += 0.001
	return t

func _clip(golem: Node, index: int) -> Animation:
	return _state_clip(golem, GuardianAnimationResolver.attack_clip_for(index))

func _state_clip(golem: Node, state: StringName) -> Animation:
	var tree := golem.get_node(^"AnimationTree") as AnimationTree
	var node := (tree.tree_root as AnimationNodeStateMachine).get_node(state) as AnimationNodeAnimation
	return (golem.get_node(^"AnimationPlayer") as AnimationPlayer).get_animation(node.animation)

## When the clip turns the Hitbox on and off, s.
func _window(clip: Animation) -> Vector2:
	var track := clip.find_track(^"Hitbox:monitoring", Animation.TYPE_VALUE)
	var count := clip.track_get_key_count(track)
	for key: int in count:
		if clip.track_get_key_value(track, key) == true:
			var end := clip.track_get_key_time(track, key + 1) if key + 1 < count else clip.length
			return Vector2(clip.track_get_key_time(track, key), end)
	return Vector2(clip.length, clip.length)

## An area's shape and its transform in the root's space.
func _area_shape(root: Node, path: NodePath) -> Dictionary:
	var area := root.get_node(path) as Node2D
	var node := area.get_node(^"CollisionShape2D") as CollisionShape2D
	return {"shape": node.shape, "xform": area.transform * node.transform}

func _charge_link(stage: int, owned: bool, wall: bool) -> GuardianAttack:
	return GuardianRepertoire.next_link(CHARGE, stage, 1.0, 1, 3, _always, wall, false, _no_roll, owned)

func _dash_ctx(feet: Vector2, target: Vector2) -> MotionContext:
	var ctx := MotionContext.new()
	ctx.feet = feet
	ctx.facing = 1
	ctx.target = target
	ctx.arena = Rect2(0.0, 0.0, 1280.0, 400.0)
	ctx.margin = 96.0
	ctx.duration = CHARGE_BACK.duration
	return ctx

func _link(move: GuardianAttack, stage: int, links_done: int) -> GuardianAttack:
	return GuardianRepertoire.next_link(move, stage, 1.0, links_done, GuardianStage.DEFAULT_MAX_LINKS, _always, false,
			false, func() -> float: return 0.0)

func _no_roll() -> float:
	return 0.0

func _always(_attack: GuardianAttack) -> bool:
	return true
