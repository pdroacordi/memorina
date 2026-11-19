class_name AutumnGuardianKitTest extends GdUnitTestSuite

## The Leaf Guardian's GRD-15 kit as data: its strings, what joins at each stage, the blades' dodge, the dive's shadow,
## the scatter's tell and the gust that keeps its recall (systems/guardians, "The Leaf Guardian's fight (GRD-15)").

const STATS := preload("res://resources/characters/guardians/autumn_guardian/autumn_guardian_stats.tres")
const SWEEP := preload("res://resources/characters/guardians/autumn_guardian/autumn_sweep.tres")
const SWEEP_AGAIN := preload("res://resources/characters/guardians/autumn_guardian/autumn_sweep_again.tres")
const CLAW := preload("res://resources/characters/guardians/autumn_guardian/autumn_overhead_claw.tres")
const HOP := preload("res://resources/characters/guardians/autumn_guardian/autumn_hop.tres")
const GUST := preload("res://resources/characters/guardians/autumn_guardian/autumn_gust.tres")
const BLADES := preload("res://resources/characters/guardians/autumn_guardian/autumn_leaf_blades.tres")
const DIVE := preload("res://resources/characters/guardians/autumn_guardian/autumn_dive.tres")
const SCATTER := preload("res://resources/characters/guardians/autumn_guardian/autumn_scatter.tres")
const LEAF_SCENE := "res://scenes/characters/guardians/autumn_guardian/autumn_guardian.tscn"
const IVO_SCENE := "res://scenes/characters/ivo/ivo.tscn"
const ARENA_ROOM := "res://scenes/world/rooms/wind_orchards/contents/orchard_arena.room"
## Px from Ivo to the view's edge: the camera centres him in a 640 px view.
const VIEW_HALF := 320.0
## Px of the scarecrow's drawn half width on its far side (idle art, x -64; systems/guardians, GRD-04).
const BODY_HALF := 64.0
## Ivo's single jump traced in play: feet height (px) by s after take-off (frost_guardian_kit_test).
const JUMP: Array[Vector2] = [Vector2(0.0, 0.0), Vector2(0.133, 58.9), Vector2(0.167, 71.3), Vector2(0.233, 93.3),
		Vector2(0.267, 102.9), Vector2(0.3, 111.6), Vector2(0.6, 141.5), Vector2(0.9, 115.3), Vector2(0.933, 107.8),
		Vector2(1.2, 0.0)]
## Scaled s a human needs to read a tell and act on it.
const REACT := 0.35
## Scaled s of take-off window, at the least, in which a jump clears the blades.
const JUMP_WINDOW := 0.2
## Px of Ivo's body (capsule h54).
const IVO_HEIGHT := 54.0
## Px of the orchard arena's room width (orchard_arena.room, 40 cells), past its Arena's 1184.
const ARENA_WIDTH := 1280.0


func test_the_sweep_strings_into_a_second_sweep_and_the_overhead_claw() -> void:
	assert_object(_link(SWEEP, 0, 1)).is_same(SWEEP_AGAIN)
	assert_object(_link(SWEEP_AGAIN, 0, 2)).is_same(CLAW)
	assert_object(_link(CLAW, 0, 3)).override_failure_message("the claw ends the string").is_null()
	# Backed off past the claw's 104 px after the second sweep, the string ends.
	assert_object(GuardianRepertoire.next_link(SWEEP_AGAIN, 0, 1.0, 2, 3,
			func(attack: GuardianAttack) -> bool: return attack != CLAW, false, false, func() -> float: return 0.0)).is_null()

func test_the_last_stage_makes_the_sweep_string_certain() -> void:
	var never := func() -> float: return 0.99
	var last := STATS.stages[2]
	assert_object(GuardianRepertoire.next_link(SWEEP, 2, last.chain_scale, 1, last.max_links, _always, false, false,
			never)).is_same(SWEEP_AGAIN)
	assert_object(GuardianRepertoire.next_link(SWEEP_AGAIN, 2, last.chain_scale, 2, last.max_links, _always, false,
			false, never)).is_same(CLAW)

## The sweeps are jumped and the claw is not: the claw reaches up past a jump, the sweeps only a hop's height, and the
## claw winds up from the raised arm (attack_1 9), unlike either sweep.
func test_the_claw_reaches_a_jumper_the_sweeps_do_not() -> void:
	assert_float(CLAW.attack_height).is_greater(SWEEP.attack_height + 100.0)
	assert_float(SWEEP_AGAIN.attack_height).is_equal(SWEEP.attack_height)
	var leaf := auto_free(load(LEAF_SCENE).instantiate()) as Node
	for sweep: GuardianAttack in [SWEEP, SWEEP_AGAIN]:
		var a := _first_look(_state_clip(leaf, GuardianAnimationResolver.windup_clip_for(sweep.windup_index)))
		var b := _first_look(_state_clip(leaf, GuardianAnimationResolver.windup_clip_for(CLAW.windup_index)))
		assert_str(a).override_failure_message("a sweep and the claw open alike").is_not_equal(b)

## Each wind-up slot belongs to one kind of move; the dive and the hop (move out of the shadow, walk under) and the
## blades (stay down, then jump) open on different frames.
func test_each_kind_of_move_winds_up_its_own_way() -> void:
	var owners := {}
	for attack: GuardianAttack in GuardianMoveGraph.moves(STATS):
		if owners.has(attack.windup_index):
			assert_int(owners[attack.windup_index]).override_failure_message("%s shares a wind-up" % attack.resource_path.get_file()) \
					.is_equal(attack.clip_index)
		owners[attack.windup_index] = attack.clip_index
	var leaf := auto_free(load(LEAF_SCENE).instantiate()) as Node
	var looks: Array[String] = []
	for attack: GuardianAttack in [HOP, BLADES, DIVE, SCATTER, GUST]:
		var look := _first_look(_state_clip(leaf, GuardianAnimationResolver.windup_clip_for(attack.windup_index)))
		assert_bool(looks.has(look)).override_failure_message("%s opens like another move" % attack.resource_path.get_file()).is_false()
		looks.append(look)

## Three blades fly out above a standing Ivo and come back low: from every distance they are thrown, a single jump
## taken after the last has passed over him and before the first comes back clears them all, with JUMP_WINDOW to spare.
func test_a_jump_between_the_blades_out_and_back_clears_them() -> void:
	var ivo := auto_free(load(IVO_SCENE).instantiate()) as Node
	var hurt := _area_shape(ivo, ^"Hurtbox")
	var distance := 40.0
	while distance <= BLADES.attack_range:
		var best := _widest_jump_window(_blade_samples(BLADES.spawns[0], distance, Rect2()), hurt, distance)
		assert_float(best).override_failure_message("thrown at %.0f: the widest jump window is %.2f s" % [distance, best]) \
				.is_greater_equal(JUMP_WINDOW)
		distance += 8.0

## Pinned with the arena's wall right behind him, Ivo still has a jump window: a blade turns half its `past` beyond him,
## into the wall, rather than on top of him.
func test_a_pinned_ivo_can_still_jump_the_blades() -> void:
	var ivo := auto_free(load(IVO_SCENE).instantiate()) as Node
	var hurt := _area_shape(ivo, ^"Hurtbox")
	var distance := 40.0
	while distance <= BLADES.attack_range:
		var wall := Rect2(-500.0, -400.0, 500.0 + distance + 8.0, 400.0)
		var best := _widest_jump_window(_blade_samples(BLADES.spawns[0], distance, wall), hurt, distance)
		assert_float(best).override_failure_message("pinned at %.0f: the widest jump window is %.2f s" % [distance, best]) \
				.is_greater_equal(JUMP_WINDOW)
		distance += 8.0

## A standing Ivo is never touched by a blade on its way out; one on its way back touches him at every distance.
func test_the_blades_pass_over_a_standing_ivo_and_come_back_low() -> void:
	var blade := auto_free(BLADES.spawns[0].scene.instantiate()) as Boomerang
	var ivo := auto_free(load(IVO_SCENE).instantiate()) as Node
	var hurt := _area_shape(ivo, ^"Hurtbox")
	var top: float = -((hurt.xform as Transform2D).origin.y - (hurt.shape as Shape2D).get_rect().size.y * 0.5)
	assert_float(blade.height - blade.size.y * 0.5).override_failure_message("the way out is not over his head").is_greater(top)
	assert_float(blade.return_height + blade.size.y * 0.5).override_failure_message("the way back is over his feet") \
			.is_greater(-(hurt.xform as Transform2D).origin.y - (hurt.shape as Shape2D).get_rect().size.y * 0.5)

## The dive's shadow is down from the strike's start and covers every spot the diving body or its landing box reaches.
func test_the_dive_shadow_covers_its_whole_reach() -> void:
	var leaf := auto_free(load(LEAF_SCENE).instantiate()) as Node
	var ivo := auto_free(load(IVO_SCENE).instantiate()) as Node
	var hurt := _area_shape(ivo, ^"Hurtbox")
	var shadow_spawn := DIVE.spawns[0]
	assert_int(shadow_spawn.placement).is_equal(GuardianSpawn.Placement.AT_LANDING)
	var shadow := auto_free(shadow_spawn.scene.instantiate()) as FloorShadow
	var dive := DIVE.motion as DiveMotion
	var dive_starts := dive.delay + dive.rise_time + dive.hang
	assert_float(shadow_spawn.at + shadow.warn).override_failure_message("the shadow is gone before the landing") \
			.is_greater_equal(dive_starts + dive.dive_time)
	assert_float(dive_starts - shadow_spawn.at).is_greater_equal(REACT)
	var ivo_half := (hurt.shape as Shape2D).get_rect().size.x * 0.5
	var distance := 40.0
	while distance <= DIVE.attack_range:
		var ctx := MotionContext.new()
		ctx.target = Vector2(distance, 0.0)
		ctx.duration = DIVE.duration
		var path := DIVE.motion.plan(ctx)
		var landing := path.end_offset().x
		assert_float(landing).is_equal(distance)
		var reach := 0.0
		for side: float in [-1.0, 1.0]:
			var off := 0.0
			while off < 240.0 and _dive_touches(leaf, path, hurt, landing + side * off, dive_starts):
				off += 2.0
			reach = maxf(reach, off)
		assert_float(shadow.width * 0.5 + ivo_half).override_failure_message("from %.0f the dive reaches %.0f px" % [
				distance, reach]).is_greater_equal(reach)
		distance += 10.0

## The scatter reforms behind Ivo and always sweeps; its swirl marks the spot from the start of the strike, and the body is
## back REACT before the sweep can hit.
func test_the_scatter_shows_where_it_reforms_before_it_sweeps() -> void:
	assert_object(_link(SCATTER, 2, 1)).is_same(SWEEP)
	var blink := SCATTER.motion as BlinkMotion
	var swirl_spawn := SCATTER.spawns[0]
	assert_int(swirl_spawn.placement).is_equal(GuardianSpawn.Placement.AT_LANDING)
	var swirl := auto_free(swirl_spawn.scene.instantiate()) as SpawnedAttack
	var back := blink.at + blink.fade
	assert_float(swirl_spawn.at + swirl.warn).override_failure_message("the swirl is gone before the body is back") \
			.is_greater_equal(back)
	var leaf := auto_free(load(LEAF_SCENE).instantiate()) as Node
	var opens := _window(_state_clip(leaf, GuardianAnimationResolver.attack_clip_for(SWEEP.clip_index))).x
	assert_float(SCATTER.duration - back + SWEEP.telegraph + opens).is_greater_equal(REACT)
	assert_float(SCATTER.duration - swirl_spawn.at + SWEEP.telegraph + opens).is_greater_equal(2.0 * REACT)
	# The body is hidden exactly while nothing can hit it.
	var clip := _state_clip(leaf, GuardianAnimationResolver.attack_clip_for(SCATTER.clip_index))
	var shown := clip.find_track(^"Sprite2D:visible", Animation.TYPE_VALUE)
	assert_bool(clip.value_track_interpolate(shown, blink.at) as bool).is_false()
	assert_bool(clip.value_track_interpolate(shown, back + 0.01) as bool).is_true()
	# Nor can it be struck: no hit-stop, shake or pogo bounce off the empty air
	# (bugs/the-scattered-leaf-guardian-still-takes-sword-contact-so-a-pogo-bounces-off-thin-air).
	var struck := clip.find_track(^"Hurtbox:monitorable", Animation.TYPE_VALUE)
	assert_bool(clip.value_track_interpolate(struck, blink.at - blink.fade + 0.01) as bool).is_false()
	assert_bool(clip.value_track_interpolate(struck, blink.at) as bool).is_false()
	assert_bool(clip.value_track_interpolate(struck, back + 0.01) as bool).is_true()

## The gust keeps its recall ("as today"): unpicked while wall climb is missing, opened only at a wall, and its push
## crosses the whole arena before its own floor box opens. Once the climb is owned it is an ordinary, rarer move.
func test_the_gust_keeps_its_wall_climb_recall() -> void:
	assert_object(GUST.recall).is_not_null()
	assert_bool(GUST.recall.wall_cue).is_true()
	assert_int(GUST.recall.skill).is_equal(Enums.PlayerSkill.WALL_CLIMB)
	assert_float(GUST.weight_for(false)).is_equal(0.0)
	assert_float(GUST.weight_for(true)).is_greater(0.0)
	assert_float(GUST.weight_for(true)).is_less(SWEEP.weight)
	assert_int(GUST.damage_for(true)).is_equal(1)
	var leaf := auto_free(load(LEAF_SCENE).instantiate()) as Node
	var blow := _window(_state_clip(leaf, GuardianAnimationResolver.attack_clip_for(GUST.clip_index))).x
	assert_float(ARENA_WIDTH / GUST.push_speed + REACT).is_less_equal(blow)
	# Its floor is marked before the blow lands, at the blow's own time.
	var stream := leaf.get_node(^"GustStream") as GustStream
	assert_float(stream.blow_at).is_equal_approx(blow, 0.001)
	assert_float(stream.warn_time).is_greater_equal(REACT)
	# The recalled climb would leave the arena by the east wall without the FightWall that closes the top.
	assert_str(FileAccess.get_file_as_string(ARENA_ROOM)).contains("30,0 = {\"across\": 9, \"cells\": 1}")

## The hop is walked under: an Ivo under the middle of its arc is touched by neither its body nor its landing box, from
## its comfort distance out to its range, and a still Ivo is caught by the landing
## (as the Bloom pounce, bugs/the-bloom-pounce-cannot-be-walked-under-or-jumped).
func test_the_hop_can_be_walked_under() -> void:
	var leaf := auto_free(load(LEAF_SCENE).instantiate()) as Node
	var ivo := auto_free(load(IVO_SCENE).instantiate()) as Node
	var hurt := _area_shape(ivo, ^"Hurtbox")
	var contact := _area_shape(leaf, ^"ContactHitbox")
	var box := _area_shape(leaf, ^"Hitbox")
	var clip := _state_clip(leaf, GuardianAnimationResolver.attack_clip_for(HOP.clip_index))
	var window := _window(clip)
	var positions := clip.find_track(^"Hitbox/CollisionShape2D:position", Animation.TYPE_VALUE)
	var scales := clip.find_track(^"Hitbox/CollisionShape2D:scale", Animation.TYPE_VALUE)
	var leap := HOP.motion as LeapMotion
	var distance := STATS.comfort_distance
	while distance <= HOP.attack_range:
		var ctx := MotionContext.new()
		ctx.target = Vector2(distance, 0.0)
		ctx.duration = HOP.duration
		var path := HOP.motion.plan(ctx)
		var under := path.at(leap.delay + leap.air_time * 0.5).x
		var still_hit := false
		var t := 0.0
		while t <= HOP.duration:
			var at := Transform2D(0.0, path.at(t))
			for x: float in [under, distance]:
				var standing := Transform2D(0.0, Vector2(x, 0.0)) * (hurt.xform as Transform2D)
				var touched := (contact.shape as Shape2D).collide(at * (contact.xform as Transform2D), hurt.shape, standing)
				if t >= window.x and t < window.y:
					var keyed := Transform2D(0.0, clip.value_track_interpolate(scales, t), 0.0, clip.value_track_interpolate(positions, t))
					touched = touched or (box.shape as Shape2D).collide(at * keyed, hurt.shape, standing)
				if x == under:
					assert_bool(touched).override_failure_message("from %.0f it hits an Ivo under it at %.2f s" % [distance, t]).is_false()
				else:
					still_hit = still_hit or touched
			t += 1.0 / 60.0
		assert_bool(still_hit).override_failure_message("from %.0f it misses a still Ivo" % distance).is_true()
		distance += 8.0

## Every column of the fight's floor, between its FightWalls, has the claw's reach up plus Ivo's height of air over it,
## so the pinned answer (a double jump over the claw) is possible everywhere Ivo can stand
## (bugs/the-orchard-arenas-west-lintel-caps-ivos-jump-at-74-px-so-the-leaf-claw-cannot-be-dodged-there).
func test_the_arena_leaves_room_to_jump_the_claw() -> void:
	var text := FileAccess.get_file_as_string(ARENA_ROOM)
	var grid := text.substr(text.find("[grid]") + 7).split("\n[")[0].strip_edges().split("\n")
	var floor_row := -1
	for row: int in grid.size():
		if grid[row].count("#") == grid[row].length():
			floor_row = row
			break
	assert_int(floor_row).is_greater(0)
	var walls: Array[int] = []
	for col: int in grid[floor_row - 1].length():
		if grid[floor_row - 1][col] == "I":
			walls.append(col)
	assert_array(walls).has_size(2)
	var rows_needed := ceili((CLAW.attack_height + IVO_HEIGHT) / RoomMap.CELL_PX)
	for col: int in range(walls[0] + 1, walls[1]):
		for row: int in range(floor_row - rows_needed, floor_row):
			assert_str(grid[row][col]).override_failure_message("cell (%d,%d) caps a jump" % [col, row]).is_equal(".")

func test_a_move_that_strands_or_loops_never_follows_itself() -> void:
	for attack: GuardianAttack in [HOP, GUST, BLADES, DIVE, SCATTER]:
		assert_bool(attack.repeats).override_failure_message(attack.resource_path.get_file()).is_false()

func test_the_new_moves_join_at_their_stage() -> void:
	var zero := GuardianRepertoire.available(STATS.attacks, 0)
	assert_bool(zero.has(BLADES)).is_true()
	assert_bool(zero.has(DIVE)).is_false()
	assert_bool(GuardianRepertoire.available(STATS.attacks, 1).has(DIVE)).is_true()
	assert_bool(GuardianRepertoire.available(STATS.attacks, 1).has(SCATTER)).is_false()
	assert_bool(GuardianRepertoire.available(STATS.attacks, 2).has(SCATTER)).is_true()

func test_each_stage_is_harder() -> void:
	assert_int(STATS.stages.size()).is_equal(STATS.cycles_to_restore)
	for i: int in range(1, STATS.stages.size()):
		assert_float(STATS.stages[i].cooldown_scale).is_less(STATS.stages[i - 1].cooldown_scale)
		assert_float(STATS.stages[i].chain_scale).is_greater(STATS.stages[i - 1].chain_scale)

func test_every_move_has_a_wind_up_a_recovery_and_a_short_cooldown() -> void:
	for attack: GuardianAttack in GuardianMoveGraph.moves(STATS):
		var label := attack.resource_path.get_file()
		assert_int(attack.windup_index).override_failure_message("%s has no wind-up" % label).is_greater_equal(0)
		assert_float(attack.recovery).override_failure_message("%s has no recovery" % label).is_greater_equal(0.35)
		assert_float(attack.cooldown).override_failure_message(label).is_between(0.3, 0.9)
		assert_float(attack.telegraph).override_failure_message("%s winds up too fast" % label).is_greater_equal(0.3)

## Every move is thrown from where its wind-up is on screen with Ivo centred.
func test_every_move_is_thrown_from_on_screen() -> void:
	for attack: GuardianAttack in GuardianMoveGraph.moves(STATS):
		assert_float(attack.attack_range + BODY_HALF).override_failure_message(attack.resource_path.get_file()) \
				.is_less_equal(VIEW_HALF)

## Each blade's hit samples by s since the strike's spawn time, at an Ivo `distance` px ahead: {at, xforms, shape}.
func _blade_samples(spawn: GuardianSpawn, distance: float, arena: Rect2) -> Array[Dictionary]:
	var ctx := SpawnContext.make(Vector2.ZERO, 1, Vector2(distance, 0.0), arena, 0.0)
	var blades: Array[Dictionary] = []
	var points := SpawnPlacement.points(spawn, ctx)
	for i: int in spawn.count:
		var kind := auto_free(spawn.scene.instantiate()) as SpawnedAttack
		kind.position = points[mini(i, points.size() - 1)]
		kind.facing = 1
		var shape := (kind.get_node(^"Hitbox/CollisionShape2D") as CollisionShape2D).shape
		var placed := Transform2D(0.0, kind.position)
		var xforms: Array[Transform2D] = []
		for xform: Transform2D in kind.hit_transforms(ctx):
			xforms.append(placed * xform)
		# hit_transforms refits the shape: read it after.
		shape = (kind.get_node(^"Hitbox/CollisionShape2D") as CollisionShape2D).shape
		blades.append({"at": spawn.interval * i + kind.warn, "xforms": xforms, "shape": shape})
	return blades

## The longest run, s, of take-off times from which the traced jump clears every blade.
func _widest_jump_window(blades: Array[Dictionary], hurt: Dictionary, distance: float) -> float:
	var window := 0.0
	var best := 0.0
	var take_off := 0.0
	while take_off <= 3.0:
		if _jump_clears(blades, hurt, distance, take_off):
			window += 0.01
			best = maxf(best, window)
		else:
			window = 0.0
		take_off += 0.01
	return best

## Whether Ivo standing `distance` px ahead, jumping at `take_off` s (the traced jump), is touched by no blade.
func _jump_clears(blades: Array[Dictionary], hurt: Dictionary, distance: float, take_off: float) -> bool:
	for blade: Dictionary in blades:
		var t: float = blade.at
		for xform: Transform2D in blade.xforms:
			var ivo := Transform2D(0.0, Vector2(distance, -_feet(t - take_off))) * (hurt.xform as Transform2D)
			if (blade.shape as Shape2D).collide(xform, hurt.shape, ivo):
				return false
			t += SpawnedAttack.SAMPLE
	return true

## Whether the dive's contact or landing box touches an Ivo standing at `x` along `path` from the dive's start.
func _dive_touches(leaf: Node, path: MotionPath, hurt: Dictionary, x: float, from: float) -> bool:
	var contact := _area_shape(leaf, ^"ContactHitbox")
	var box := _area_shape(leaf, ^"Hitbox")
	var clip := _state_clip(leaf, GuardianAnimationResolver.attack_clip_for(DIVE.clip_index))
	var window := _window(clip)
	var positions := clip.find_track(^"Hitbox/CollisionShape2D:position", Animation.TYPE_VALUE)
	var scales := clip.find_track(^"Hitbox/CollisionShape2D:scale", Animation.TYPE_VALUE)
	var ivo := Transform2D(0.0, Vector2(x, 0.0)) * (hurt.xform as Transform2D)
	var t := from
	while t <= DIVE.duration:
		var at := Transform2D(0.0, path.at(t))
		if (contact.shape as Shape2D).collide(at * (contact.xform as Transform2D), hurt.shape, ivo):
			return true
		if t >= window.x and t < window.y:
			var keyed := Transform2D(0.0, clip.value_track_interpolate(scales, t), 0.0, clip.value_track_interpolate(positions, t))
			if (box.shape as Shape2D).collide(at * keyed, hurt.shape, ivo):
				return true
		t += 1.0 / 60.0
	return false

## Feet height, px, `t` s after take-off on the traced jump.
func _feet(t: float) -> float:
	if t <= 0.0 or t >= JUMP[JUMP.size() - 1].x:
		return 0.0
	for i: int in range(1, JUMP.size()):
		if t <= JUMP[i].x:
			return lerpf(JUMP[i - 1].y, JUMP[i].y, (t - JUMP[i - 1].x) / (JUMP[i].x - JUMP[i - 1].x))
	return 0.0

## The texture and frame a clip opens on.
func _first_look(clip: Animation) -> String:
	var texture := clip.find_track(^"Sprite2D:texture", Animation.TYPE_VALUE)
	var frame := clip.find_track(^"Sprite2D:frame", Animation.TYPE_VALUE)
	return "%s/%d" % [(clip.track_get_key_value(texture, 0) as Texture2D).resource_path, clip.track_get_key_value(frame, 0)]

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

func _link(move: GuardianAttack, stage: int, links_done: int) -> GuardianAttack:
	return GuardianRepertoire.next_link(move, stage, 1.0, links_done, GuardianStage.DEFAULT_MAX_LINKS, _always, false,
			false, func() -> float: return 0.0)

func _always(_attack: GuardianAttack) -> bool:
	return true
