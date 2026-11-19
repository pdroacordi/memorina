class_name MentorKitTest extends GdUnitTestSuite

## The mentor's GRD-17 kit as data: the hardest winter at stages 0 and 1, the spring's moves only at the revelation's
## stage 2, its strings, and the dodges each move leaves (systems/guardians, "The mentor's fight (GRD-17)").

const STATS := preload("res://resources/characters/guardians/mentor/mentor_stats.tres")
const SWEEP := preload("res://resources/characters/guardians/mentor/mentor_sweep.tres")
const GLIDE := preload("res://resources/characters/guardians/mentor/mentor_glide_sweep.tres")
const SLAM := preload("res://resources/characters/guardians/mentor/mentor_slam.tres")
const FROST_WAVE := preload("res://resources/characters/guardians/mentor/mentor_frost_wave.tres")
const ICICLES := preload("res://resources/characters/guardians/mentor/mentor_icicle_fall.tres")
const ICICLES_AGAIN := preload("res://resources/characters/guardians/mentor/mentor_icicle_again.tres")
const THORN_ROW := preload("res://resources/characters/guardians/mentor/mentor_thorn_row.tres")
const POUNCE := preload("res://resources/characters/guardians/mentor/mentor_pounce.tres")
const POUNCE_AGAIN := preload("res://resources/characters/guardians/mentor/mentor_pounce_again.tres")
const SPRING := preload("res://resources/characters/guardians/mentor/mentor_spring.tres")
const MENTOR_SCENE := "res://scenes/characters/guardians/mentor_guardian/mentor_guardian.tscn"
const IVO_SCENE := "res://scenes/characters/ivo/ivo.tscn"
const ARENA_ROOM := "res://scenes/world/rooms/frost_edge/contents/lighthouse_top.room"
## Px from Ivo to the view's edge: the camera centres him in a 640 px view.
const VIEW_HALF := 320.0
## Ivo's single jump traced in play: feet height (px) by s after take-off (frost_guardian_kit_test).
const JUMP: Array[Vector2] = [Vector2(0.0, 0.0), Vector2(0.133, 58.9), Vector2(0.167, 71.3), Vector2(0.233, 93.3),
		Vector2(0.267, 102.9), Vector2(0.3, 111.6), Vector2(0.6, 141.5), Vector2(0.9, 115.3), Vector2(0.933, 107.8),
		Vector2(1.2, 0.0)]
## Px from Ivo's feet to the foot of his hurtbox.
const HURT_FOOT := 6.0
## Scaled s a pose shows before the blow it warns of, at least: time to see it and act.
const REACT := 0.35
const JUMP_APEX := 144.0
const IVO_HEIGHT := 54.0
## Alpha above which a texel counts as drawn.
const DRAWN_ALPHA := 0.06
const WINTER: Array[GuardianAttack] = [SWEEP, GLIDE, SLAM, FROST_WAVE, ICICLES, ICICLES_AGAIN]
const SPRING_MOVES: Array[GuardianAttack] = [THORN_ROW, POUNCE, POUNCE_AGAIN, SPRING]


## Before the revelation only the winter ("só o padrão de Inverno, lento e pesado", design 02 section 5.1); its stage 2
## is the only one after it, and there every move is thrown (the board: "in stage 2 all at once").
func test_the_spring_joins_only_at_the_revelations_stage() -> void:
	for stage: int in [0, 1]:
		for attack: GuardianAttack in GuardianRepertoire.available(STATS.attacks, stage):
			assert_bool(attack in WINTER).override_failure_message("%s at stage %d" % [
					attack.resource_path.get_file(), stage]).is_true()
	assert_array(GuardianRepertoire.available(STATS.attacks, 2)).is_equal(STATS.attacks)
	for attack: GuardianAttack in SPRING_MOVES:
		assert_int(attack.from_stage).override_failure_message(attack.resource_path.get_file()).is_equal(2)
	assert_bool(GuardianRepertoire.available(STATS.attacks, 0).has(ICICLES)).is_true()

## One stage per good answer and one for the revelation, each harder than the last; the last has the longest strings.
func test_each_stage_is_harder() -> void:
	assert_int(STATS.stages.size()).is_equal(STATS.cycles_to_restore + 1)
	for i: int in range(1, STATS.stages.size()):
		assert_float(STATS.stages[i].cooldown_scale).is_less(STATS.stages[i - 1].cooldown_scale)
		assert_float(STATS.stages[i].chain_scale).is_greater(STATS.stages[i - 1].chain_scale)
	assert_int(STATS.stages[2].max_links).is_equal(GuardianRepertoire.MAX_LINKS)
	# Stage 0 walks at the mentor's own heavy pace (design 02 section 5.1); later stages stride in faster.
	assert_float(STATS.stages[0].walk_scale).is_equal(1.0)
	for i: int in range(1, STATS.stages.size()):
		assert_float(STATS.stages[i].walk_scale).is_greater(STATS.stages[i - 1].walk_scale)

func test_the_sweep_strings_into_the_glide_and_the_slam() -> void:
	assert_object(_link(SWEEP, 0, 1)).is_same(GLIDE)
	assert_object(_link(GLIDE, 0, 2)).is_same(SLAM)
	assert_object(_link(SLAM, 0, 3)).override_failure_message("the slam ends the string").is_null()
	var last := STATS.stages[2]
	var never := func() -> float: return 0.99
	assert_object(GuardianRepertoire.next_link(SWEEP, 2, last.chain_scale, 1, last.max_links, _always, false, false,
			never)).is_same(GLIDE)

## The hail falls twice from stage 1, and the pounce comes twice at the revelation's stage.
func test_the_hail_and_the_pounce_come_again_later() -> void:
	assert_object(_link(ICICLES, 0, 1)).is_null()
	assert_object(_link(ICICLES, 1, 1)).is_same(ICICLES_AGAIN)
	assert_object(_link(ICICLES_AGAIN, 1, 2)).is_null()
	assert_object(_link(POUNCE, 2, 1)).is_same(POUNCE_AGAIN)
	assert_object(_link(POUNCE_AGAIN, 2, 2)).is_null()

## The glide steps in after an Ivo who backed off, from as far as it is thrown, and ends where the sweep's box lands;
## closer than that it stays put. It never runs faster than its speed.
func test_the_glide_steps_in_and_ends_inside_the_sweep() -> void:
	var dash := GLIDE.motion as DashMotion
	var distance := 40.0
	while distance <= GLIDE.attack_range:
		var ctx := _dash_ctx(Vector2(400.0, 400.0), Vector2(400.0 + distance, 400.0))
		var left := distance - dash.plan(ctx).end_offset().x
		assert_float(left).override_failure_message("from %.0f it ends %.0f px off" % [distance, left]).is_less_equal(SWEEP.attack_range)
		assert_float(left).override_failure_message("from %.0f it steps into him" % distance).is_greater_equal(minf(distance, -dash.past))
		assert_float(dash.planned_speed(ctx)).override_failure_message("sped up from %.0f" % distance).is_less_equal(dash.speed + 0.01)
		distance += 8.0

## A single jump clears the slam: only the hands on the floor hit, and a jump taken any time from the raised-arm pose to
## 0.1 s before they fall is over them (the Frost slam's rule, bugs/the-frost-slam-jump-window-closes-before-the-fists-fall).
func test_a_jump_clears_the_slam() -> void:
	var mentor := auto_free(load(MENTOR_SCENE).instantiate()) as Node
	var clip := _clip(mentor, SLAM.clip_index)
	var window := _window(clip)
	var highest := 0.0
	var t := window.x
	while t < window.y:
		highest = maxf(highest, -_box_at(clip, t).position.y)
		t += 1.0 / 60.0
	assert_float(SLAM.attack_height).is_less_equal(highest - HURT_FOOT)
	var windup := _state_clip(mentor, GuardianAnimationResolver.windup_clip_for(SLAM.windup_index))
	var frames := windup.find_track(^"Sprite2D:frame", Animation.TYPE_VALUE)
	var pose := windup.track_get_key_time(frames, windup.track_get_key_count(frames) - 1) - SLAM.telegraph
	assert_float(window.x - 0.1 - pose).is_greater_equal(REACT)
	var take_off := pose
	while take_off <= window.x - 0.1:
		var at := window.x
		while at < window.y:
			assert_float(_feet(at - take_off) + HURT_FOOT).override_failure_message(
					"a jump at %.2f s is under the hands at %.2f s" % [take_off, at]).is_greater(highest)
			at += 1.0 / 60.0
		take_off += 0.01

## The pounce is dodged as the Bloom stag's is: an Ivo under the middle of its arc is touched by neither its body nor
## its landing box, from the comfort distance out to its range, and it lands past him.
func test_the_pounce_can_be_walked_under() -> void:
	var mentor := auto_free(load(MENTOR_SCENE).instantiate()) as Node
	var ivo := auto_free(load(IVO_SCENE).instantiate()) as Node
	var hurt := _area_shape(ivo, ^"Hurtbox")
	var contact := _area_shape(mentor, ^"ContactHitbox")
	var box := _area_shape(mentor, ^"Hitbox")
	var leap := POUNCE.motion as LeapMotion
	for move: GuardianAttack in [POUNCE, POUNCE_AGAIN]:
		var clip := _clip(mentor, move.clip_index)
		var window := _window(clip)
		var distance := STATS.comfort_distance
		while distance <= move.attack_range:
			var ctx := MotionContext.new()
			ctx.target = Vector2(distance, 0.0)
			ctx.duration = move.duration
			var path := move.motion.plan(ctx)
			var under := Transform2D(0.0, Vector2(path.at(leap.delay + leap.air_time * 0.5).x, 0.0)) * (hurt.xform as Transform2D)
			var t := 0.0
			while t <= move.duration:
				var at := Transform2D(0.0, path.at(t))
				assert_bool((contact.shape as Shape2D).collide(at * (contact.xform as Transform2D), hurt.shape, under)) \
						.override_failure_message("from %.0f its body hits an Ivo under it at %.2f s" % [distance, t]).is_false()
				if t >= window.x and t < window.y:
					var rect := _box_at(clip, t)
					var keyed := Transform2D(0.0, rect.get_center()) * Transform2D.IDENTITY.scaled(rect.size / 20.0)
					assert_bool((box.shape as Shape2D).collide(at * keyed, hurt.shape, under)).override_failure_message(
							"from %.0f its landing hits an Ivo under it at %.2f s" % [distance, t]).is_false()
				t += 1.0 / 60.0
			assert_float(path.end_offset().x).is_greater(distance)
			distance += 8.0

## The pounce's shadow marks where it comes down through the whole flight, and covers every spot its body coming down
## or its landing box reaches, on both sides (the Frost body drop's rule).
func test_the_pounce_shadow_covers_its_reach() -> void:
	var mentor := auto_free(load(MENTOR_SCENE).instantiate()) as Node
	var ivo := auto_free(load(IVO_SCENE).instantiate()) as Node
	var hurt := _area_shape(ivo, ^"Hurtbox")
	var ivo_half := (hurt.shape as Shape2D).get_rect().size.x * 0.5
	var leap := POUNCE.motion as LeapMotion
	for move: GuardianAttack in [POUNCE, POUNCE_AGAIN]:
		var spawn := move.spawns[0]
		assert_int(spawn.placement).is_equal(GuardianSpawn.Placement.AT_LANDING)
		var shadow := auto_free(spawn.scene.instantiate()) as FloorShadow
		assert_float(spawn.at + shadow.warn).is_greater_equal(leap.delay + leap.air_time)
		var distance := STATS.comfort_distance
		while distance <= move.attack_range:
			var ctx := MotionContext.new()
			ctx.target = Vector2(distance, 0.0)
			ctx.duration = move.duration
			var path := move.motion.plan(ctx)
			var landing := path.end_offset().x
			var reach := 0.0
			for side: float in [-1.0, 1.0]:
				var off := 0.0
				while off < 200.0 and _pounce_touches(mentor, move, path, hurt, landing + side * off):
					off += 2.0
				reach = maxf(reach, off)
			assert_float(shadow.width * 0.5 + ivo_half).override_failure_message("from %.0f the pounce reaches %.0f px" % [
					distance, reach]).is_greater_equal(reach)
			distance += 20.0

## Moves whose dodge crosses the floor wait while the spring's thorns burn: the pounce is walked under, the hail is
## walked out of. The seeds burn the floor from the moment they leave the hand.
func test_the_floor_moves_wait_for_the_thorns() -> void:
	for attack: GuardianAttack in [POUNCE, POUNCE_AGAIN, ICICLES, ICICLES_AGAIN]:
		assert_bool(attack.waits_for_floor).override_failure_message(attack.resource_path.get_file()).is_true()
	for attack: GuardianAttack in [SWEEP, GLIDE, SLAM, FROST_WAVE, THORN_ROW, SPRING]:
		assert_bool(attack.waits_for_floor).override_failure_message(attack.resource_path.get_file()).is_false()
	var pod := auto_free(SPRING.spawns[0].scene.instantiate()) as Lob
	pod.set(&"_t", pod.warn + pod.live * 0.5)
	assert_bool(pod.burns_floor()).is_true()

## Everything the mentor sends along the floor is cleared by a single jump.
func test_its_floor_runners_stay_under_a_single_jump() -> void:
	for attack: GuardianAttack in [SLAM, FROST_WAVE, THORN_ROW]:
		for spawn: GuardianSpawn in attack.spawns:
			var kind := auto_free(spawn.scene.instantiate()) as FloorRunner
			assert_object(kind).is_not_null()
			assert_float(kind.height).is_less(JUMP_APEX * 0.5)

## Every move is thrown from where its whole wind-up is on screen with Ivo centred.
func test_every_move_is_thrown_from_on_screen() -> void:
	var mentor := auto_free(load(MENTOR_SCENE).instantiate()) as Node
	for attack: GuardianAttack in GuardianMoveGraph.moves(STATS):
		var back := _drawn_back(_state_clip(mentor, GuardianAnimationResolver.windup_clip_for(attack.windup_index)))
		assert_float(attack.attack_range + back).override_failure_message("%s: %.0f + %.0f" % [
				attack.resource_path.get_file(), attack.attack_range, back]).is_less_equal(VIEW_HALF)

func test_every_move_has_a_wind_up_a_recovery_and_a_short_cooldown() -> void:
	for attack: GuardianAttack in GuardianMoveGraph.moves(STATS):
		var label := attack.resource_path.get_file()
		assert_int(attack.windup_index).override_failure_message("%s has no wind-up" % label).is_greater_equal(0)
		assert_float(attack.recovery).override_failure_message("%s has no recovery" % label).is_greater_equal(0.4)
		assert_float(attack.cooldown).override_failure_message(label).is_between(0.3, 0.9)
		assert_float(attack.telegraph).override_failure_message("%s winds up too fast" % label).is_greater_equal(0.3)
		assert_int(attack.damage).override_failure_message(label).is_equal(1)

## Each wind-up slot belongs to one kind of move, and every root opens on its own frame: the slam (jump in place), the
## hail (keep moving), the thorn row (jump) and the seeds (stand between) read apart.
func test_each_kind_of_move_winds_up_its_own_way() -> void:
	var owners := {}
	for attack: GuardianAttack in GuardianMoveGraph.moves(STATS):
		if owners.has(attack.windup_index):
			assert_int(owners[attack.windup_index]).override_failure_message("%s shares a wind-up" % attack.resource_path.get_file()) \
					.is_equal(attack.clip_index)
		owners[attack.windup_index] = attack.clip_index
	var mentor := auto_free(load(MENTOR_SCENE).instantiate()) as Node
	var looks: Array[String] = []
	for attack: GuardianAttack in STATS.attacks:
		var look := _first_look(_state_clip(mentor, GuardianAnimationResolver.windup_clip_for(attack.windup_index)))
		assert_bool(looks.has(look)).override_failure_message("%s opens like another move" % attack.resource_path.get_file()).is_false()
		looks.append(look)

func test_the_mentor_has_no_recall() -> void:
	for attack: GuardianAttack in GuardianMoveGraph.moves(STATS):
		assert_object(attack.recall).override_failure_message(attack.resource_path.get_file()).is_null()
	assert_int(STATS.recall_after_attacks).is_equal(0)

## A move that leaves Ivo where only it reaches him, or that makes him jump into the overhead pick, never follows itself.
func test_a_move_that_strands_or_loops_never_follows_itself() -> void:
	for attack: GuardianAttack in [SLAM, FROST_WAVE, ICICLES, SPRING]:
		assert_bool(attack.repeats).override_failure_message(attack.resource_path.get_file()).is_false()

## Ivo standing on the lantern's 32 px west step is below every move's reach up, so a pick there is an ordinary one: an
## overhead pick (the tallest move, ties by array order) cycled the hail, the thorn row and the pounce 9 times running
## against a driver on the step (playtests/2026-11-19-grd17-mentor-fight, the fix round).
func test_the_west_step_is_below_every_reach() -> void:
	for attack: GuardianAttack in GuardianMoveGraph.moves(STATS):
		assert_float(attack.attack_height).override_failure_message(attack.resource_path.get_file()).is_greater(32.0)

## Nothing the mentor throws is unanswerable at a wall: every column between the lantern's west wall and its FightWall
## has a single jump's height and Ivo's of air over it.
func test_the_lantern_leaves_room_to_jump() -> void:
	var text := FileAccess.get_file_as_string(ARENA_ROOM)
	var grid := text.substr(text.find("[grid]") + 7).split("\n[")[0].strip_edges().split("\n")
	# The FightWall stands on the floor: its row is the one above the floor.
	var floor_row := -1
	for row: int in grid.size():
		if grid[row].contains("I"):
			floor_row = row + 1
			break
	assert_int(floor_row).is_greater(0)
	var wall := grid[floor_row - 1].find("I")
	assert_int(wall).is_greater(0)
	var rows_needed := ceili((JUMP_APEX + IVO_HEIGHT) / RoomMap.CELL_PX)
	var col := wall - 1
	while col >= 0 and grid[floor_row - 1][col] == ".":
		for row: int in range(floor_row - rows_needed, floor_row):
			assert_str(grid[row][col]).override_failure_message("cell (%d,%d) caps a jump" % [col, row]).is_equal(".")
		col -= 1

## Whether the pounce's contact or landing box touches an Ivo standing at `x` along `path`, from the apex down.
func _pounce_touches(mentor: Node, move: GuardianAttack, path: MotionPath, hurt: Dictionary, x: float) -> bool:
	var contact := _area_shape(mentor, ^"ContactHitbox")
	var box := _area_shape(mentor, ^"Hitbox")
	var clip := _clip(mentor, move.clip_index)
	var window := _window(clip)
	var ivo := Transform2D(0.0, Vector2(x, 0.0)) * (hurt.xform as Transform2D)
	var leap := move.motion as LeapMotion
	var t := leap.delay + leap.air_time * 0.5
	while t <= move.duration:
		var at := Transform2D(0.0, path.at(t))
		if (contact.shape as Shape2D).collide(at * (contact.xform as Transform2D), hurt.shape, ivo):
			return true
		if t >= window.x and t < window.y:
			var rect := _box_at(clip, t)
			var keyed := Transform2D(0.0, rect.get_center()) * Transform2D.IDENTITY.scaled(rect.size / 20.0)
			if (box.shape as Shape2D).collide(at * keyed, hurt.shape, ivo):
				return true
		t += 1.0 / 60.0
	return false

## Px the clip's frames draw behind the feet: the sprite is authored facing west and flipped east.
func _drawn_back(clip: Animation) -> float:
	var texture_track := clip.find_track(^"Sprite2D:texture", Animation.TYPE_VALUE)
	var hframes_track := clip.find_track(^"Sprite2D:hframes", Animation.TYPE_VALUE)
	var frame_track := clip.find_track(^"Sprite2D:frame", Animation.TYPE_VALUE)
	var back := 0.0
	for key: int in clip.track_get_key_count(frame_track):
		var at := clip.track_get_key_time(frame_track, key)
		var image := (clip.value_track_interpolate(texture_track, at) as Texture2D).get_image()
		var width := image.get_width() / int(clip.value_track_interpolate(hframes_track, at))
		var frame := int(clip.track_get_key_value(frame_track, key))
		var right := -1
		for x: int in width:
			for y: int in image.get_height():
				if image.get_pixel(frame * width + x, y).a > DRAWN_ALPHA:
					right = x
					break
		back = maxf(back, (right + 1 - width / 2.0) * 2.0)
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

## The keyed hit box at `t` s, in the guardian's space facing east.
func _box_at(clip: Animation, t: float) -> Rect2:
	var positions := clip.find_track(^"Hitbox/CollisionShape2D:position", Animation.TYPE_VALUE)
	var scales := clip.find_track(^"Hitbox/CollisionShape2D:scale", Animation.TYPE_VALUE)
	var centre := clip.value_track_interpolate(positions, t) as Vector2
	var half := (clip.value_track_interpolate(scales, t) as Vector2) * 10.0
	return Rect2(centre - half, half * 2.0)

func _clip(root: Node, index: int) -> Animation:
	return _state_clip(root, GuardianAnimationResolver.attack_clip_for(index))

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

func _dash_ctx(feet: Vector2, target: Vector2) -> MotionContext:
	var ctx := MotionContext.new()
	ctx.feet = feet
	ctx.facing = 1
	ctx.target = target
	ctx.arena = Rect2(0.0, 0.0, 1152.0, 768.0)
	ctx.margin = 96.0
	ctx.duration = GLIDE.duration
	return ctx

func _link(move: GuardianAttack, stage: int, links_done: int) -> GuardianAttack:
	return GuardianRepertoire.next_link(move, stage, 1.0, links_done, GuardianStage.DEFAULT_MAX_LINKS, _always, false,
			false, func() -> float: return 0.0)

func _always(_attack: GuardianAttack) -> bool:
	return true

## The winter has three moves that reach a far Ivo (the glide, the frost wave, the hail), so a far pick is not a
## two-move alternation between the walk-ins (the fix round: glide and hail alternated five times running with two).
func test_the_winter_has_three_far_moves() -> void:
	var far := 0
	for attack: GuardianAttack in GuardianRepertoire.available(STATS.attacks, 0):
		if attack.attack_range >= STATS.comfort_distance * GuardianAI.COMFORT_FAR and attack.weight > 0.0:
			far += 1
	assert_int(far).is_greater_equal(3)
