class_name SummerGuardianKitTest extends GdUnitTestSuite

## The Sun Guardian's GRD-16 kit as data: its claw string, the charge's wall bounce, the embers, the sun shafts' order
## and the pounce slam's shadow (systems/guardians, "The Sun Guardian's fight (GRD-16)").

const STATS := preload("res://resources/characters/guardians/summer_guardian/summer_guardian_stats.tres")
const CLAW := preload("res://resources/characters/guardians/summer_guardian/summer_claw.tres")
const CLAW_AGAIN := preload("res://resources/characters/guardians/summer_guardian/summer_claw_again.tres")
const BITE := preload("res://resources/characters/guardians/summer_guardian/summer_bite_lunge.tres")
const CHARGE := preload("res://resources/characters/guardians/summer_guardian/summer_charge.tres")
const CHARGE_BACK := preload("res://resources/characters/guardians/summer_guardian/summer_charge_back.tres")
const ROAR := preload("res://resources/characters/guardians/summer_guardian/summer_roar.tres")
const EMBER_SPIT := preload("res://resources/characters/guardians/summer_guardian/summer_ember_spit.tres")
const SUN_SHAFTS := preload("res://resources/characters/guardians/summer_guardian/summer_sun_shafts.tres")
const POUNCE := preload("res://resources/characters/guardians/summer_guardian/summer_pounce_slam.tres")
const SUN_SCENE := "res://scenes/characters/guardians/summer_guardian/summer_guardian.tscn"
const IVO_SCENE := "res://scenes/characters/ivo/ivo.tscn"
const ARENA_ROOM := "res://scenes/world/rooms/summer_caldera/contents/caldera_arena.room"
## Px from Ivo to the view's edge: the camera centres him in a 640 px view.
const VIEW_HALF := 320.0
## Ivo's single jump traced in play: feet height (px) by s after take-off (frost_guardian_kit_test).
const JUMP: Array[Vector2] = [Vector2(0.0, 0.0), Vector2(0.133, 58.9), Vector2(0.167, 71.3), Vector2(0.233, 93.3),
		Vector2(0.267, 102.9), Vector2(0.3, 111.6), Vector2(0.6, 141.5), Vector2(0.9, 115.3), Vector2(0.933, 107.8),
		Vector2(1.2, 0.0)]
## Px from Ivo's feet to the foot of his hurtbox.
const HURT_FOOT := 6.0
## Scaled s a human needs to read a tell and act on it.
const REACT := 0.35
## Ivo's single jump apex and body height, px.
const JUMP_APEX := 144.0
const IVO_HEIGHT := 54.0
## S before the charge's box arrives that a Lake-kit Ivo rolls toward the lion (playtests/2026-11-19-grd16-sun-feel).
const ROLL_LEAD := 0.12
## Px of a sprite pixel's alpha, 0..1, that counts as drawn.
const DRAWN_ALPHA := 0.06


func test_the_claw_strings_into_a_second_claw_and_the_bite_lunge() -> void:
	assert_object(_link(CLAW, 0, 1)).is_same(CLAW_AGAIN)
	assert_object(_link(CLAW_AGAIN, 0, 2)).is_same(BITE)
	assert_object(_link(BITE, 0, 3)).override_failure_message("the bite ends the string").is_null()
	# Backed off past the bite's reach after the second claw, the string ends.
	assert_object(GuardianRepertoire.next_link(CLAW_AGAIN, 0, 1.0, 2, 3,
			func(attack: GuardianAttack) -> bool: return attack != BITE, false, false, func() -> float: return 0.0)).is_null()

## The claws are jumped low; the bite lunges in at head height after an Ivo who backed off, from a crouch the claws do
## not open with.
func test_the_bite_reaches_further_and_higher_than_the_claws() -> void:
	assert_float(BITE.attack_range).is_greater(CLAW.attack_range)
	assert_float(BITE.attack_height).is_greater(CLAW.attack_height)
	assert_float(BITE.attack_height + HURT_FOOT).is_less(JUMP_APEX)
	var sun := auto_free(load(SUN_SCENE).instantiate()) as Node
	assert_str(_first_look(_state_clip(sun, GuardianAnimationResolver.windup_clip_for(CLAW.windup_index)))) \
			.is_not_equal(_first_look(_state_clip(sun, GuardianAnimationResolver.windup_clip_for(BITE.windup_index))))

## From stage 1 the charge comes back, off a wall it hits or turning after it ran past Ivo ("Turn after passing Ivo
## (Recommended)", user, 2026-11-19); against a wall the return turns from the wall, not to Ivo, so a pinned Ivo the lion
## ran into the wall is behind it.
func test_the_charge_comes_back_from_stage_one_wall_or_not() -> void:
	for wall: bool in [false, true]:
		assert_object(_charge_link(0, wall)).override_failure_message("came back at stage 0").is_null()
		assert_object(_charge_link(1, wall)).override_failure_message("wall %s" % wall).is_same(CHARGE_BACK)
	assert_bool(CHARGE_BACK.turns_from_wall).is_true()
	assert_bool(CHARGE.body_contact).is_false()
	assert_bool(CHARGE_BACK.body_contact).is_false()
	# Ivo is usually still in the air from jumping the charge when it hits the wall: the bounce must reach him there.
	assert_float(CHARGE_BACK.attack_height).is_greater_equal(JUMP_APEX)

## An Ivo who jumped the charge as late as still clears its box has landed, with REACT to spare, before the bounce's box
## can reach him, from any distance the charge is thrown (bugs/the-frost-charge-back-after-a-far-charge-hits-ivo-as-he-
## lands-from-jumping-it).
func test_an_ivo_who_jumped_the_charge_has_landed_before_the_bounce() -> void:
	var sun := auto_free(load(SUN_SCENE).instantiate()) as Node
	var clip := _clip(sun, CHARGE.clip_index)
	var box := _box_at(clip, CHARGE.lunge_delay)
	var front := box.end.x
	var rise := _rise_to(-box.position.y)
	var air := JUMP[JUMP.size() - 1].x
	var reach_from := CHARGE.duration + CHARGE_BACK.telegraph + _window(_clip(sun, CHARGE_BACK.clip_index)).x
	var distance := 74.0
	while distance <= CHARGE.attack_range:
		var arrives := CHARGE.lunge_delay + maxf(distance - front, 0.0) / CHARGE.lunge_speed
		var landed := arrives - rise + air
		assert_float(reach_from - landed).override_failure_message("thrown from %.0f: %.2f s after landing" % [
				distance, reach_from - landed]).is_greater_equal(REACT)
		distance += 8.0

## A single jump clears the charge from every distance it is thrown, with a take-off window of at least 0.5 s: the box
## tops out under a jump's height for as long as it takes to pass Ivo.
func test_a_single_jump_clears_the_charge() -> void:
	var sun := auto_free(load(SUN_SCENE).instantiate()) as Node
	var clip := _clip(sun, CHARGE.clip_index)
	var window := _window(clip)
	var distance := 74.0
	while distance <= CHARGE.attack_range:
		var widest := 0.0
		var run := 0.0
		# From the wind-up's start: a jump taken as the lion leans in is an answer too.
		var take_off := -CHARGE.telegraph
		while take_off <= CHARGE.duration:
			var clear := true
			var t := window.x
			while t < window.y and clear:
				var box := _box_at(clip, t)
				var front := box.end.x + CHARGE.lunge_speed * (t - CHARGE.lunge_delay)
				var back := box.position.x + CHARGE.lunge_speed * (t - CHARGE.lunge_delay)
				# Ivo's hurtbox (8 px either side) overlaps the box in x, and its foot is under the box's top.
				if front >= distance - 8.0 and back <= distance + 8.0 and _feet(t - take_off) + HURT_FOOT < -box.position.y:
					clear = false
				t += 1.0 / 60.0
			run = run + 0.01 if clear else 0.0
			widest = maxf(widest, run)
			take_off += 0.01
		assert_float(widest).override_failure_message("thrown from %.0f: a %.2f s take-off window" % [distance, widest]) \
				.is_greater_equal(0.5)
		distance += 8.0

## The charge stops `lunge_past` beyond Ivo's live position, so it ends within its return's range of him from every
## distance it is thrown, whether he jumped it in place (Orchard kit) or rolled through it toward the lion (Lake kit),
## and the return follows every stage-1 charge for both kits ("Turn after passing Ivo (Recommended)", user, 2026-11-19;
## bugs/a-roll-through-the-sun-charge-always-skips-its-stage-1-return).
func test_the_charge_ends_within_reach_of_its_return_for_both_kits() -> void:
	var sun := auto_free(load(SUN_SCENE).instantiate()) as Node
	var front := _box_at(_clip(sun, CHARGE.clip_index), CHARGE.lunge_delay).end.x
	var roll := load("res://resources/characters/ivo/ivo_roll_stats.tres") as RollStats
	var distance := 74.0
	while distance <= CHARGE.attack_range:
		for rolls: bool in [false, true]:
			var arrives := CHARGE.lunge_delay + maxf(distance - front, 0.0) / CHARGE.lunge_speed
			var gap := _charge_end_gap(distance, rolls, arrives - ROLL_LEAD, roll)
			assert_float(gap).override_failure_message("thrown from %.0f, %s: ends %.0f px from Ivo" % [
					distance, "rolled" if rolls else "jumped", gap]).is_less_equal(CHARGE_BACK.attack_range)
			# It has run past him: he is behind it, where the return turns to.
			assert_float(gap).is_greater(0.0)
		distance += 8.0

## The second claw steps in after an Ivo who backed off past the first, to the middle of its box, or stays put when he
## is already close: the claw string chains against a dodger who backs off, and a jump still clears it (as the Frost's
## second swipe).
func test_the_second_claw_steps_in_after_a_retreating_ivo() -> void:
	var step := CLAW_AGAIN.motion as DashMotion
	assert_object(step).is_not_null()
	assert_float(CLAW_AGAIN.attack_range).is_greater(CLAW.attack_range)
	assert_float(CLAW_AGAIN.attack_height + HURT_FOOT).is_less(JUMP_APEX)
	var distance := 74.0
	while distance <= CLAW_AGAIN.attack_range:
		var ctx := _dash_ctx(Vector2(400.0, 288.0), Vector2(400.0 + distance, 288.0), 1)
		ctx.duration = CLAW_AGAIN.duration
		var left := distance - step.plan(ctx).end_offset().x
		assert_float(left).override_failure_message("from %.0f it ends %.0f px off" % [distance, left]).is_less_equal(CLAW.attack_range)
		assert_float(left).override_failure_message("from %.0f it steps into him" % distance).is_greater_equal(minf(distance, -step.past))
		assert_float(step.planned_speed(ctx)).is_less_equal(step.speed + 0.01)
		distance += 8.0

## The bounce runs past Ivo at its own speed and stops on screen; it never runs back into the wall it left.
func test_the_bounce_ends_past_ivo_on_screen() -> void:
	var dash := CHARGE_BACK.motion as DashMotion
	var distance := 74.0
	while distance <= CHARGE_BACK.attack_range:
		var ctx := _dash_ctx(Vector2(1182.0, 288.0), Vector2(1182.0 - distance, 288.0), -1)
		var end := ctx.feet.x + dash.plan(ctx).end_offset().x
		assert_float(end).override_failure_message("from %.0f it stops short of Ivo" % distance).is_less(ctx.target.x)
		assert_float(ctx.target.x - end).is_less_equal(dash.past + 0.01)
		assert_float(dash.planned_speed(ctx)).override_failure_message("sped up from %.0f" % distance).is_less_equal(dash.speed + 0.01)
		distance += 8.0
	# A pinned Ivo behind the lion at the wall: turned from the wall, the bounce does not run back at him.
	var pinned := _dash_ctx(Vector2(1182.0, 288.0), Vector2(1240.0, 288.0), -1)
	assert_float(dash.plan(pinned).end_offset().x).is_less_equal(0.0)

## The bounce is thrown from the wall: the lion's far side is the wall, so it is on screen while Ivo is within its
## range plus its body's half width of it.
func test_the_bounce_is_thrown_from_on_screen() -> void:
	var sun := auto_free(load(SUN_SCENE).instantiate()) as Guardian
	assert_float(CHARGE_BACK.attack_range + sun.body_rect().size.x * 0.5).is_less_equal(VIEW_HALF)

## Every move is thrown from where its whole wind-up, the lion's tail included, is on screen with Ivo centred.
func test_every_move_is_thrown_from_on_screen() -> void:
	var sun := auto_free(load(SUN_SCENE).instantiate()) as Node
	for attack: GuardianAttack in GuardianMoveGraph.moves(STATS):
		var back := _drawn_back(_state_clip(sun, GuardianAnimationResolver.windup_clip_for(attack.windup_index)))
		assert_float(attack.attack_range + back).override_failure_message("%s: %.0f + %.0f" % [
				attack.resource_path.get_file(), attack.attack_range, back]).is_less_equal(VIEW_HALF)

## The embers fall in a spread round Ivo, harmless in flight, and each burns its spot for 1.5 s (the board).
func test_the_embers_burn_where_they_land() -> void:
	var spawn := EMBER_SPIT.spawns[0]
	assert_int(spawn.count).is_equal(3)
	assert_int(spawn.placement).is_equal(GuardianSpawn.Placement.AROUND_IVO)
	var ember := auto_free(spawn.scene.instantiate()) as Lob
	assert_bool(ember.is_live(ember.warn + ember.live * 0.5)).is_false()
	var patch := auto_free(ember.patch.instantiate()) as FloorPatch
	assert_float(patch.live).is_equal(1.5)
	# Ivo fits between two patches.
	assert_float(spawn.spacing - patch.width).is_greater_equal(24.0)

## The sun shafts burn one at a time, each lit REACT first, ordered away from the lion; between two burns there is time
## to walk out of the next one, and the first stands clear of the lion's body, so an Ivo at its nose is safe.
func test_the_sun_shafts_burn_in_a_readable_order() -> void:
	var spawn := SUN_SHAFTS.spawns[0]
	assert_int(spawn.placement).is_equal(GuardianSpawn.Placement.FRONT)
	var shaft := auto_free(spawn.scene.instantiate()) as LightColumn
	assert_float(shaft.warn).is_greater_equal(REACT)
	var ivo := auto_free(load(IVO_SCENE).instantiate()) as Node
	var hurt := _area_shape(ivo, ^"Hurtbox")
	var ivo_half := (hurt.shape as Shape2D).get_rect().size.x * 0.5
	var walk := ((ivo.get_node(^"Locomotion") as Node).get(&"stats") as LocomotionStats).move_speed
	var out_time := (shaft.width * 0.5 + ivo_half) / walk
	assert_float(spawn.interval - shaft.live).override_failure_message("no time to step between two burns") \
			.is_greater_equal(out_time + 0.1)
	assert_float(spawn.spacing).is_less_equal(shaft.width + ivo_half)
	var sun := auto_free(load(SUN_SCENE).instantiate()) as Guardian
	var nose := sun.body_rect().size.x * 0.5 + ivo_half
	assert_float(spawn.offset.x - shaft.width * 0.5 - nose).is_greater_equal(2.0 * ivo_half)
	# Every shaft lies inside Ivo's view from wherever the move is thrown.
	var farthest := spawn.offset.x + spawn.spacing * (spawn.count - 1) + shaft.width * 0.5
	assert_float(farthest - nose).is_less_equal(VIEW_HALF)
	# The lion rears until the last shaft has burned out, so no other move is thrown into the sequence.
	assert_float(spawn.at + spawn.interval * (spawn.count - 1) + shaft.warn + shaft.live).is_less_equal(SUN_SHAFTS.duration)
	# The shafts' arena is open to its ceiling: a shaft is the room's height.
	assert_float(shaft.height).is_less_equal(_open_height())

## Pinned against a wall 81-88 px from the lion, where the roar is thrown, a single jump with the direction held toward
## the lion from the press carries Ivo over it and lands him behind it, untouched, with a take-off window of at least
## 0.25 s that holds a press at REACT (bugs/a-pinned-ivo-jumps-the-roaring-lion-only-in-a-frame-tight-window).
func test_a_pinned_ivo_jumps_over_the_roar() -> void:
	assert_bool(ROAR.body_contact).is_false()
	var sun := auto_free(load(SUN_SCENE).instantiate()) as Guardian
	var ivo := auto_free(load(IVO_SCENE).instantiate()) as Node
	var hurt := _area_shape(ivo, ^"Hurtbox")
	var box := _area_shape(sun, ^"Hitbox")
	var stats := (ivo.get_node(^"Locomotion") as Node).get(&"stats") as LocomotionStats
	var clip := _clip(sun, ROAR.clip_index)
	var window := _window(clip)
	var positions := clip.find_track(^"Hitbox/CollisionShape2D:position", Animation.TYPE_VALUE)
	var scales := clip.find_track(^"Hitbox/CollisionShape2D:scale", Animation.TYPE_VALUE)
	var body_out := sun.body_rect().size.x * 0.5 + (hurt.shape as Shape2D).get_rect().size.x * 0.5
	for start: float in [81.0, 84.0, 88.0]:
		var widest := 0.0
		var run := 0.0
		var holds_react := false
		var press := 0.0
		while press <= ROAR.telegraph:
			var clear := true
			var x := start
			var vx := 0.0
			var t := press
			while t <= ROAR.telegraph + ROAR.duration and clear:
				var strike := t - ROAR.telegraph
				if strike >= window.x and strike < window.y:
					var keyed := Transform2D(0.0, clip.value_track_interpolate(scales, strike), 0.0, clip.value_track_interpolate(positions, strike))
					var at := Transform2D(0.0, Vector2(x, -_feet(t - press))) * (hurt.xform as Transform2D)
					clear = not (box.shape as Shape2D).collide(keyed, hurt.shape, at)
				vx = move_toward(vx, -stats.move_speed, stats.acceleration * stats.air_control / 60.0)
				x += vx / 60.0
				t += 1.0 / 60.0
			# Landed behind the body, out of its contact.
			var landed := start - stats.move_speed * JUMP[JUMP.size() - 1].x + stats.move_speed * stats.move_speed / (2.0 * stats.acceleration * stats.air_control)
			clear = clear and landed <= -body_out
			run = run + 0.01 if clear else 0.0
			widest = maxf(widest, run)
			holds_react = holds_react or (clear and absf(press - REACT) < 0.005)
			press += 0.01
		assert_float(widest).override_failure_message("from %.0f: a %.2f s window" % [start, widest]).is_greater_equal(0.25)
		assert_bool(holds_react).override_failure_message("from %.0f a press at %.2f s is hit" % [start, REACT]).is_true()

## The roar keeps today's reach: it rears 150 px high and slams, and it winds up from a crouch the shafts' rear does not.
func test_the_roar_rears_and_the_shafts_open_otherwise() -> void:
	assert_float(ROAR.attack_height).is_equal(150.0)
	var sun := auto_free(load(SUN_SCENE).instantiate()) as Node
	assert_str(_first_look(_state_clip(sun, GuardianAnimationResolver.windup_clip_for(ROAR.windup_index)))) \
			.is_not_equal(_first_look(_state_clip(sun, GuardianAnimationResolver.windup_clip_for(SUN_SHAFTS.windup_index))))

## The pounce slam's shadow is down from the strike's start, covers every spot the body coming down or its landing box
## reaches, and an Ivo walking away from the lion from the landing spot is never touched.
func test_the_pounce_shadow_covers_its_reach_and_can_be_walked_out_of() -> void:
	var sun := auto_free(load(SUN_SCENE).instantiate()) as Node
	var ivo := auto_free(load(IVO_SCENE).instantiate()) as Node
	var hurt := _area_shape(ivo, ^"Hurtbox")
	var shadow_spawn := POUNCE.spawns[0]
	assert_int(shadow_spawn.placement).is_equal(GuardianSpawn.Placement.AT_LANDING)
	assert_bool(POUNCE.spawns[1].on_landing).is_true()
	var shadow := auto_free(shadow_spawn.scene.instantiate()) as FloorShadow
	var leap := POUNCE.motion as LeapMotion
	assert_int(leap.target).is_equal(LeapMotion.Target.IVO_SPOT)
	assert_float(shadow_spawn.at + shadow.warn).is_greater_equal(leap.delay + leap.air_time)
	var ivo_half := (hurt.shape as Shape2D).get_rect().size.x * 0.5
	var walk := ((ivo.get_node(^"Locomotion") as Node).get(&"stats") as LocomotionStats).move_speed
	var distance := STATS.comfort_distance
	while distance <= POUNCE.attack_range:
		var path := POUNCE.motion.plan(_leap_ctx(distance, Rect2()))
		var landing := path.end_offset().x
		assert_float(landing).is_equal(distance)
		var reach := 0.0
		for side: float in [-1.0, 1.0]:
			var off := 0.0
			while off < 240.0 and _pounce_touches(sun, path, hurt, func(_t: float) -> float: return landing + side * off):
				off += 2.0
			reach = maxf(reach, off)
		assert_float(shadow.width * 0.5 + ivo_half).override_failure_message("from %.0f the pounce reaches %.0f px" % [
				distance, reach]).is_greater_equal(reach)
		var walks_away := func(t: float) -> float: return landing + walk * maxf(t - REACT, 0.0)
		assert_bool(_pounce_touches(sun, path, hurt, walks_away)).override_failure_message(
				"from %.0f an Ivo walking away after %.2f s is caught" % [distance, REACT]).is_false()
		distance += 8.0

## Pinned against the FightWall, the landing is clamped off the wall and the lion comes down clear of him.
func test_a_pinned_ivo_is_clear_of_the_pounce() -> void:
	var sun := auto_free(load(SUN_SCENE).instantiate()) as Guardian
	var ivo := auto_free(load(IVO_SCENE).instantiate()) as Node
	var hurt := _area_shape(ivo, ^"Hurtbox")
	var arena := Rect2(0.0, -384.0, 1280.0, 384.0)
	var wall_face := RoomMap.CELL_PX
	var ivo_x := wall_face + (hurt.shape as Shape2D).get_rect().size.x * 0.5
	var from := ivo_x + 24.0
	while from - ivo_x <= POUNCE.attack_range:
		var ctx := _leap_ctx(ivo_x - from, arena)
		ctx.feet = Vector2(from, 0.0)
		ctx.target = Vector2(ivo_x, 0.0)
		ctx.margin = sun.lucidity_leap_margin
		ctx.facing = -1
		var path := POUNCE.motion.plan(ctx)
		var moved := func(_t: float) -> float: return ivo_x - from
		assert_bool(_pounce_touches(sun, path, hurt, moved)).override_failure_message("from %.0f" % from).is_false()
		from += 16.0

## Nothing the lion throws needs the double jump at a wall: every column between the FightWalls has a single jump's
## height and Ivo's of air over it.
func test_the_arena_leaves_room_to_jump() -> void:
	var grid := _grid()
	var floor_row := _floor_row(grid)
	var walls: Array[int] = []
	for col: int in grid[floor_row - 1].length():
		if grid[floor_row - 1][col] == "I":
			walls.append(col)
	assert_array(walls).has_size(2)
	var rows_needed := ceili((JUMP_APEX + IVO_HEIGHT) / RoomMap.CELL_PX)
	for col: int in range(walls[0] + 1, walls[1]):
		for row: int in range(floor_row - rows_needed, floor_row):
			assert_str(grid[row][col]).override_failure_message("cell (%d,%d) caps a jump" % [col, row]).is_equal(".")

## The ember spit leaves Ivo boxed between burning patches: the moves whose dodge crosses the floor (the pounce's walk
## out of its shadow, the roar's back-off, the step into a burnt shaft) wait until the patches have burned out, and an
## ember counts from the moment it leaves the mouth (bugs/a-pounce-slam-thrown-after-an-ember-spit-cannot-be-walked-out-of).
func test_the_floor_moves_wait_for_the_embers_to_burn_out() -> void:
	for attack: GuardianAttack in [POUNCE, ROAR, SUN_SHAFTS]:
		assert_bool(attack.waits_for_floor).override_failure_message(attack.resource_path.get_file()).is_true()
	for attack: GuardianAttack in [CLAW, CHARGE, EMBER_SPIT]:
		assert_bool(attack.waits_for_floor).override_failure_message(attack.resource_path.get_file()).is_false()
	var ember := auto_free(EMBER_SPIT.spawns[0].scene.instantiate()) as Lob
	ember.set(&"_t", ember.warn + ember.live * 0.5)
	assert_bool(ember.burns_floor()).override_failure_message("an ember in flight").is_true()
	var patch := auto_free(ember.patch.instantiate()) as FloorPatch
	patch.set(&"_t", patch.warn + patch.live * 0.5)
	assert_bool(patch.burns_floor()).is_true()
	patch.set(&"_t", patch.warn + patch.live + 0.01)
	assert_bool(patch.burns_floor()).override_failure_message("a patch that has burned out").is_false()

func test_the_sun_has_no_recall() -> void:
	for attack: GuardianAttack in GuardianMoveGraph.moves(STATS):
		assert_object(attack.recall).override_failure_message(attack.resource_path.get_file()).is_null()
	assert_int(STATS.recall_after_attacks).is_equal(0)

func test_a_move_that_strands_or_loops_never_follows_itself() -> void:
	for attack: GuardianAttack in [CHARGE, ROAR, EMBER_SPIT, SUN_SHAFTS, POUNCE]:
		assert_bool(attack.repeats).override_failure_message(attack.resource_path.get_file()).is_false()

func test_the_new_moves_join_at_their_stage() -> void:
	var zero := GuardianRepertoire.available(STATS.attacks, 0)
	assert_bool(zero.has(EMBER_SPIT)).is_true()
	assert_bool(zero.has(SUN_SHAFTS)).is_false()
	assert_bool(zero.has(POUNCE)).is_false()
	var one := GuardianRepertoire.available(STATS.attacks, 1)
	assert_bool(one.has(SUN_SHAFTS)).is_true()
	assert_bool(one.has(POUNCE)).is_true()

func test_each_stage_is_harder() -> void:
	assert_int(STATS.stages.size()).is_equal(STATS.cycles_to_restore)
	for i: int in range(1, STATS.stages.size()):
		assert_float(STATS.stages[i].cooldown_scale).is_less(STATS.stages[i - 1].cooldown_scale)
		assert_float(STATS.stages[i].chain_scale).is_greater(STATS.stages[i - 1].chain_scale)

func test_every_move_has_a_wind_up_a_recovery_and_a_short_cooldown() -> void:
	for attack: GuardianAttack in GuardianMoveGraph.moves(STATS):
		var label := attack.resource_path.get_file()
		assert_int(attack.windup_index).override_failure_message("%s has no wind-up" % label).is_greater_equal(0)
		assert_float(attack.recovery).override_failure_message("%s has no recovery" % label).is_greater_equal(0.4)
		assert_float(attack.cooldown).override_failure_message(label).is_between(0.3, 0.9)
		assert_float(attack.telegraph).override_failure_message("%s winds up too fast" % label).is_greater_equal(0.3)

## Each wind-up slot belongs to one kind of move, and every root and the bite open on their own frame.
func test_each_kind_of_move_winds_up_its_own_way() -> void:
	var owners := {}
	for attack: GuardianAttack in GuardianMoveGraph.moves(STATS):
		if owners.has(attack.windup_index):
			assert_int(owners[attack.windup_index]).override_failure_message("%s shares a wind-up" % attack.resource_path.get_file()) \
					.is_equal(attack.clip_index)
		owners[attack.windup_index] = attack.clip_index
	var sun := auto_free(load(SUN_SCENE).instantiate()) as Node
	var looks: Array[String] = []
	for attack: GuardianAttack in [CLAW, BITE, CHARGE, CHARGE_BACK, ROAR, EMBER_SPIT, SUN_SHAFTS, POUNCE]:
		var look := _first_look(_state_clip(sun, GuardianAnimationResolver.windup_clip_for(attack.windup_index)))
		assert_bool(looks.has(look)).override_failure_message("%s opens like another move" % attack.resource_path.get_file()).is_false()
		looks.append(look)

## Whether the pounce's contact or landing box touches an Ivo at `x_at(t)` along `path`, on its way down and after.
func _pounce_touches(sun: Node, path: MotionPath, hurt: Dictionary, x_at: Callable) -> bool:
	var contact := _area_shape(sun, ^"ContactHitbox")
	var box := _area_shape(sun, ^"Hitbox")
	var clip := _clip(sun, POUNCE.clip_index)
	var window := _window(clip)
	var positions := clip.find_track(^"Hitbox/CollisionShape2D:position", Animation.TYPE_VALUE)
	var scales := clip.find_track(^"Hitbox/CollisionShape2D:scale", Animation.TYPE_VALUE)
	var leap := POUNCE.motion as LeapMotion
	# From the apex on: the take-off is beside the lion's own feet, where its body already was.
	var t := leap.delay + leap.air_time * 0.5
	while t <= POUNCE.duration:
		var ivo := Transform2D(0.0, Vector2(float(x_at.call(t)), 0.0)) * (hurt.xform as Transform2D)
		var at := Transform2D(0.0, path.at(t))
		if (contact.shape as Shape2D).collide(at * (contact.xform as Transform2D), hurt.shape, ivo):
			return true
		if t >= window.x and t < window.y:
			var keyed := Transform2D(0.0, clip.value_track_interpolate(scales, t), 0.0, clip.value_track_interpolate(positions, t))
			if (box.shape as Shape2D).collide(at * keyed, hurt.shape, ivo):
				return true
		t += 1.0 / 60.0
	return false

## Px from the lion to Ivo, signed along the charge (positive: he is behind it), when the charge's strike ends: the
## lion lunges from 0 at an Ivo `distance` ahead and stops `lunge_past` beyond his live x; a rolling Ivo rolls toward it
## from `roll_at` s into the strike, at the roll's speed for its time, then slides to a stop over its recovery.
func _charge_end_gap(distance: float, rolls: bool, roll_at: float, roll: RollStats) -> float:
	var lion := 0.0
	var ivo := distance
	var speed := roll.roll_distance / roll.roll_time
	var stopped := false
	var t := 0.0
	while t < CHARGE.duration:
		if rolls and t >= roll_at:
			var into := t - roll_at
			var v := speed if into < roll.roll_time else maxf(speed * (1.0 - (into - roll.roll_time) / roll.roll_recovery_time), 0.0)
			ivo -= v / 60.0
		if t >= CHARGE.lunge_delay and not stopped:
			stopped = lion - ivo >= CHARGE.lunge_past
			if not stopped:
				lion += CHARGE.lunge_speed / 60.0
		t += 1.0 / 60.0
	return lion - ivo

## Px the clip's frames draw behind the feet, the tail included: the sprite is authored facing west and flipped east.
func _drawn_back(clip: Animation) -> float:
	var texture_track := clip.find_track(^"Sprite2D:texture", Animation.TYPE_VALUE)
	var frame_track := clip.find_track(^"Sprite2D:frame", Animation.TYPE_VALUE)
	var back := 0.0
	for key: int in clip.track_get_key_count(frame_track):
		var at := clip.track_get_key_time(frame_track, key)
		var texture := clip.value_track_interpolate(texture_track, at) as Texture2D
		var image := texture.get_image()
		var size := image.get_height()
		var frame := int(clip.track_get_key_value(frame_track, key))
		var right := -1
		for x: int in size * 2:
			for y: int in size:
				if image.get_pixel(frame * size * 2 + x, y).a > DRAWN_ALPHA:
					right = x
					break
		back = maxf(back, (right + 1 - size) * 2.0)
	return back

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

## The keyed hit box at `t` s, in the guardian's space facing east.
func _box_at(clip: Animation, t: float) -> Rect2:
	var positions := clip.find_track(^"Hitbox/CollisionShape2D:position", Animation.TYPE_VALUE)
	var scales := clip.find_track(^"Hitbox/CollisionShape2D:scale", Animation.TYPE_VALUE)
	var centre := clip.value_track_interpolate(positions, t) as Vector2
	var half := (clip.value_track_interpolate(scales, t) as Vector2) * 10.0
	return Rect2(centre - half, half * 2.0)

func _grid() -> PackedStringArray:
	var text := FileAccess.get_file_as_string(ARENA_ROOM)
	return text.substr(text.find("[grid]") + 7).split("\n[")[0].strip_edges().split("\n")

## The first row of solid ground under the open arena.
func _floor_row(grid: PackedStringArray) -> int:
	for row: int in range(1, grid.size()):
		if grid[row].count("S") == grid[row].length() and grid[row - 1].count(".") > 0:
			return row
	return -1

## Px of air between the arena's ceiling and its floor.
func _open_height() -> float:
	var grid := _grid()
	var floor_row := _floor_row(grid)
	var col := grid[floor_row].length() / 2
	var rows := 0
	while floor_row - rows - 1 >= 0 and grid[floor_row - rows - 1][col] == ".":
		rows += 1
	return rows * RoomMap.CELL_PX

func _clip(sun: Node, index: int) -> Animation:
	return _state_clip(sun, GuardianAnimationResolver.attack_clip_for(index))

func _state_clip(root: Node, state: StringName) -> Animation:
	var tree := root.get_node(^"AnimationTree") as AnimationTree
	var node := (tree.tree_root as AnimationNodeStateMachine).get_node(state) as AnimationNodeAnimation
	return (root.get_node(^"AnimationPlayer") as AnimationPlayer).get_animation(node.animation)

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

func _leap_ctx(distance: float, arena: Rect2) -> MotionContext:
	var ctx := MotionContext.new()
	ctx.target = Vector2(distance, 0.0)
	ctx.duration = POUNCE.duration
	ctx.arena = arena
	return ctx

func _dash_ctx(feet: Vector2, target: Vector2, facing: int) -> MotionContext:
	var ctx := MotionContext.new()
	ctx.feet = feet
	ctx.target = target
	ctx.facing = facing
	ctx.arena = Rect2(0.0, 0.0, 1280.0, 384.0)
	ctx.duration = CHARGE_BACK.duration
	return ctx

func _charge_link(stage: int, wall: bool) -> GuardianAttack:
	return GuardianRepertoire.next_link(CHARGE, stage, 1.0, 1, GuardianStage.DEFAULT_MAX_LINKS, _always, wall, false,
			func() -> float: return 0.0)

func _link(move: GuardianAttack, stage: int, links_done: int) -> GuardianAttack:
	return GuardianRepertoire.next_link(move, stage, 1.0, links_done, GuardianStage.DEFAULT_MAX_LINKS, _always, false,
			false, func() -> float: return 0.0)

func _always(_attack: GuardianAttack) -> bool:
	return true
