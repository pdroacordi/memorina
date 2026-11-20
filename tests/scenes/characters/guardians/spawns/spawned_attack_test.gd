class_name SpawnedAttackTest extends GdUnitTestSuite

## Every spawn kind: its hitbox is off in the warning, on while live (never for a lob in flight), and it expires after
## its fade; it runs only on the physics delta (architecture/grd-12-guardian-fight-engine).

const KINDS: Array[String] = [
	"res://scenes/characters/guardians/spawns/floor_runner/floor_runner.tscn",
	"res://scenes/characters/guardians/spawns/falling_shard/falling_shard.tscn",
	"res://scenes/characters/guardians/spawns/boomerang/boomerang.tscn",
	"res://scenes/characters/guardians/spawns/lob/lob.tscn",
	"res://scenes/characters/guardians/spawns/floor_patch/floor_patch.tscn",
	"res://scenes/characters/guardians/spawns/light_column/light_column.tscn",
]
const BLOOM := "res://scenes/characters/guardians/bloom_guardian/spawns/"
const FROST := "res://scenes/characters/guardians/frost_guardian/spawns/"
## Kinds with no common timing case above, still drawn by every guardian that throws them.
const EXTRA_KINDS: Array[String] = [
	"res://scenes/characters/guardians/spawns/floor_shadow/floor_shadow.tscn",
	"res://scenes/characters/guardians/spawns/leaf_swirl/leaf_swirl.tscn",
]
const STEP := 1.0 / 60.0
## A grounded arena; the runner runs on the floor `_floor` builds.
const ARENA := Rect2(-2000.0, -1000.0, 4000.0, 1000.0)


func test_every_kind_warns_then_hurts_then_expires() -> void:
	auto_free(_floor([Rect2(-2000.0, 0.0, 4000.0, 20.0)]))
	await get_tree().physics_frame
	for path: String in KINDS:
		var spawned := (load(path) as PackedScene).instantiate() as SpawnedAttack
		spawned.context = SpawnContext.make(Vector2.ZERO, 1, Vector2(160.0, 0.0), ARENA, 0.0)
		var expired: Array[bool] = []
		spawned.expired.connect(func() -> void: expired.append(true))
		add_child(spawned)
		spawned.set_physics_process(false)
		var box := spawned.hitbox()
		var t := 0.0
		var was_live := false
		while t < spawned.lifetime() + STEP * 2.0:
			spawned._physics_process(STEP)
			t += STEP
			var expected := spawned.is_live(t)
			assert_bool(box.monitoring).override_failure_message("%s at %.2f s" % [path.get_file(), t]).is_equal(expected)
			was_live = was_live or box.monitoring
		# A lob is harmless in flight and hurts through the patch it leaves (test_a_lob_leaves_a_patch_where_it_lands).
		assert_bool(was_live).override_failure_message("%s: hurt %s" % [path.get_file(), was_live]).is_equal(not spawned is Lob)
		assert_array(expired).override_failure_message("%s did not expire" % path.get_file()).has_size(1)
		spawned.free()

func test_a_kind_does_not_run_without_delta() -> void:
	var spawned := (load(KINDS[1]) as PackedScene).instantiate() as SpawnedAttack
	add_child(spawned)
	spawned.set_physics_process(false)
	for i: int in 120:
		spawned._physics_process(0.0)
	assert_bool(spawned.hitbox().monitoring).is_false()
	spawned.free()

func test_every_kind_hits_only_inside_what_it_draws() -> void:
	for path: String in KINDS:
		var spawned := (load(path) as PackedScene).instantiate() as SpawnedAttack
		var ctx := SpawnContext.make(Vector2.ZERO, 1, Vector2(160.0, 0.0), ARENA, 0.0)
		var drawn := spawned.drawn_rect(ctx).grow(4.0)
		var shape := (spawned.get_node(^"Hitbox/CollisionShape2D") as CollisionShape2D).shape as RectangleShape2D
		for xform: Transform2D in spawned.hit_transforms(ctx):
			var box := Rect2(xform.origin - shape.size * 0.5, shape.size)
			assert_bool(drawn.encloses(box)).override_failure_message("%s hits %s outside its art %s" % [
					path.get_file(), box, drawn]).is_true()
		spawned.free()

func test_a_runner_stops_at_the_arena_edge() -> void:
	var runner := (load(KINDS[0]) as PackedScene).instantiate() as FloorRunner
	runner.context = SpawnContext.make(Vector2.ZERO, 1, Vector2.ZERO, Rect2(-100.0, -400.0, 300.0, 400.0), 0.0)
	assert_float(runner.run_at(10.0)).is_equal(200.0 - FloorRunner.EDGE_MARGIN - runner.width * 0.5)
	runner.free()

## A runner whose floor ends, or that meets a step (its probe starts inside the step and reads a gap), ends there: its
## box goes off and it expires early, so it never waits on the spot
## (bugs/the-mentors-ice-wave-parks-at-the-lanterns-west-step-on-a-pinned-ivo).
func test_a_runner_ends_where_it_stops() -> void:
	for blocks: Array in [[Rect2(-200.0, 0.0, 300.0, 20.0)],
			[Rect2(-200.0, 0.0, 300.0, 20.0), Rect2(100.0, -30.0, 300.0, 50.0)]]:
		var holder := _floor(blocks)
		await get_tree().physics_frame
		var runner := (load(KINDS[0]) as PackedScene).instantiate() as FloorRunner
		runner.context = SpawnContext.make(Vector2.ZERO, 1, Vector2(160.0, 0.0), ARENA, 0.0)
		add_child(runner)
		runner.set_physics_process(false)
		var t := 0.0
		var off_at := INF
		while t < runner.warn + runner.live:
			runner._physics_process(STEP)
			t += STEP
			if t > runner.warn and not runner.hitbox().monitoring and off_at == INF:
				off_at = t
		var stop := runner.run_at(t)
		assert_float(stop).override_failure_message("ran past the stop").is_less(100.0)
		assert_float(off_at).override_failure_message("still live at %.0f px" % stop).is_less(
				runner.warn + stop / runner.speed + STEP * 2.0)
		assert_float(runner.lifetime()).is_less(runner.warn + runner.live + runner.fade)
		runner.free()
		holder.free()

func test_a_lob_leaves_a_patch_where_it_lands() -> void:
	var holder: GuardianSpawner = auto_free(GuardianSpawner.new())
	add_child(holder)
	var lob := (load(KINDS[3]) as PackedScene).instantiate() as Lob
	lob.context = SpawnContext.make(Vector2.ZERO, 1, Vector2(200.0, 0.0), ARENA, 0.0)
	lob.position = Vector2(200.0, 0.0)
	holder.add_child(lob)
	lob.set_physics_process(false)
	var t := 0.0
	while t < lob.warn + lob.live + STEP:
		lob._physics_process(STEP)
		t += STEP
	var patch := holder.get_child(holder.get_child_count() - 1) as FloorPatch
	assert_object(patch).is_not_null()
	assert_float(patch.position.x).is_equal_approx(200.0, 0.01)

## A blade with `past` turns that far beyond Ivo as he stood, held inside its reach and the arena's wall; without it
## it always flies its reach (GRD-15).
func test_a_blade_turns_past_ivo_and_comes_back_at_its_return_height() -> void:
	var blade := (load(KINDS[2]) as PackedScene).instantiate() as Boomerang
	blade.context = SpawnContext.make(Vector2.ZERO, 1, Vector2(100.0, 0.0), Rect2(), 0.0)
	assert_float(blade.turn_reach()).is_equal(blade.reach)
	blade.past = 64.0
	blade.reach = 320.0
	assert_float(blade.turn_reach()).is_equal(164.0)
	blade.context = SpawnContext.make(Vector2.ZERO, 1, Vector2(100.0, 0.0), Rect2(-500.0, -400.0, 640.0, 400.0), 0.0)
	assert_float(blade.turn_reach()).is_equal(140.0 - blade.wall_margin)
	# A wall right behind Ivo: it turns half its past beyond him, into the wall, not on top of him.
	blade.context = SpawnContext.make(Vector2.ZERO, 1, Vector2(100.0, 0.0), Rect2(-500.0, -400.0, 608.0, 400.0), 0.0)
	assert_float(blade.turn_reach()).is_equal(132.0)
	blade.height = 72.0
	blade.return_height = 14.0
	assert_float(blade.height_at(0.2)).is_equal(72.0)
	assert_float(blade.height_at(0.8)).is_equal(14.0)
	blade.free()

## Every kind draws self-lit, so the field never greys a guardian's attack: "Keep the guardian's colour" (user,
## 2026-11-19; systems/greyhush, "Self-lit pixels"). The mark is written unblended, so a spawn drawing over its own
## pixels keeps it (bugs/a-spawns-overdrawn-pixels-lose-the-self-lit-mark-and-grey).
func test_every_kind_draws_self_lit_in_the_creature_pass() -> void:
	for path: String in KINDS + EXTRA_KINDS:
		var spawned := (load(path) as PackedScene).instantiate() as SpawnedAttack
		add_child(spawned)
		spawned.set_physics_process(false)
		var message := "%s is not self-lit" % path.get_file()
		assert_object(spawned.material).override_failure_message(message).is_same(SpawnedAttack.SELF_LIT)
		assert_int(spawned.visibility_layer).is_equal(CanvasPass.CREATURES)
		spawned.free()
	var code := (SpawnedAttack.SELF_LIT as ShaderMaterial).shader.code
	assert_str(code).contains("GH_SELF_LIT_ALPHA")
	assert_str(code).contains("blend_disabled")

## Bloom's drawn spawns: a spike as tall as the runner's hit, three tufts as tall as the patch across it, a pod at
## least its hit; a kind with no art keeps its placeholder (GRD-18).
func test_the_bloom_spawns_draw_their_art_at_their_hit_size() -> void:
	var runner := (load(BLOOM + "thorn_row.tscn") as PackedScene).instantiate() as FloorRunner
	assert_float(runner.art.frame_size().y).is_equal(runner.height)
	assert_int(runner.art.frames).is_equal(4)
	var pod := (load(BLOOM + "seed_pod.tscn") as PackedScene).instantiate() as Lob
	assert_bool(pod.art.frame_size().x >= pod.size.x and pod.art.frame_size().y >= pod.size.y).is_true()
	var patch := (load(BLOOM + "thorn_patch.tscn") as PackedScene).instantiate() as FloorPatch
	assert_float(patch.art.frame_size().y).is_equal(patch.height)
	assert_float(patch.width / patch.art.frame_size().x).is_equal(3.0)
	for spawned: SpawnedAttack in [runner, pod, patch]:
		spawned.free()
	for path: String in [KINDS[0], KINDS[3], KINDS[4]]:
		var bare := (load(path) as PackedScene).instantiate()
		assert_object(bare.get(&"art")).override_failure_message("%s has art" % path.get_file()).is_null()
		bare.free()

## Frost's drawn spawns: each runner's shard as tall as its hit, the icicle's body its hit under two art rows of glint,
## its burst within the shard's drawn rect (GRD-18).
func test_the_frost_spawns_draw_their_art_at_their_hit_size() -> void:
	for scene: String in ["ice_wave.tscn", "ice_shock.tscn"]:
		var runner := (load(FROST + scene) as PackedScene).instantiate() as FloorRunner
		assert_float(runner.art.frame_size().y).override_failure_message(scene).is_equal(runner.height)
		runner.free()
	var icicle := (load(FROST + "icicle.tscn") as PackedScene).instantiate() as FallingShard
	assert_vector(icicle.art.frame_size()).is_equal(icicle.size + Vector2(4.0, 4.0))
	assert_float(icicle.shatter.frame_size().x * 0.5).is_less_equal(icicle.size.x + 6.0)
	icicle.free()

## Forming stages up to whole, then the glint frame on a glint beat only once whole.
func test_an_icicle_forms_then_glints_once_whole() -> void:
	assert_int(FallingShard.icicle_frame(0.0, true, 4)).is_equal(-1)
	assert_int(FallingShard.icicle_frame(0.2, true, 4)).is_equal(0)
	assert_int(FallingShard.icicle_frame(0.5, true, 4)).is_equal(1)
	assert_int(FallingShard.icicle_frame(0.9, false, 4)).is_equal(2)
	assert_int(FallingShard.icicle_frame(0.9, true, 4)).is_equal(3)

## Every rise stage a runner draws stands above the front grass, which draws over the creature pass: a lower stage is
## hidden (the first Bloom spikes, GRD-18).
func test_every_runner_stage_stands_above_the_grass() -> void:
	var grass := float(GrassLook.MAX_BLADE_ART * 2)
	for path: String in [BLOOM + "thorn_row.tscn", FROST + "ice_wave.tscn", FROST + "ice_shock.tscn"]:
		var runner := (load(path) as PackedScene).instantiate() as FloorRunner
		var image := runner.art.texture.get_image()
		var size := runner.art.frame_size()
		for frame: int in runner.art.frames:
			var top := size.y
			for y: int in int(size.y):
				for x: int in int(size.x):
					if image.get_pixel(int(frame * size.x) + x, y).a > 0.0:
						top = minf(top, y)
			var label := "%s frame %d" % [path.get_file(), frame]
			assert_float(size.y - top).override_failure_message(label).is_greater_equal(grass)
		runner.free()

## Static floor blocks on layer 1, the runner's floor mask.
func _floor(blocks: Array) -> Node2D:
	var holder := Node2D.new()
	add_child(holder)
	for block: Rect2 in blocks:
		var body := StaticBody2D.new()
		body.collision_layer = 1
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = block.size
		shape.shape = rect
		shape.position = block.get_center()
		body.add_child(shape)
		holder.add_child(body)
	return holder
