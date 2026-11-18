class_name SpawnedAttackTest extends GdUnitTestSuite

## Every spawn kind: its hitbox is off in the warning, on while live, and it expires after its fade; it runs only on
## the physics delta (architecture/grd-12-guardian-fight-engine).

const KINDS: Array[String] = [
	"res://scenes/characters/guardians/spawns/floor_runner/floor_runner.tscn",
	"res://scenes/characters/guardians/spawns/falling_shard/falling_shard.tscn",
	"res://scenes/characters/guardians/spawns/boomerang/boomerang.tscn",
	"res://scenes/characters/guardians/spawns/lob/lob.tscn",
	"res://scenes/characters/guardians/spawns/floor_patch/floor_patch.tscn",
	"res://scenes/characters/guardians/spawns/light_column/light_column.tscn",
]
const STEP := 1.0 / 60.0
## A grounded arena with no floor under it: the runner's probe is tested on its own.
const ARENA := Rect2(-2000.0, -1000.0, 4000.0, 1000.0)


func test_every_kind_warns_then_hurts_then_expires() -> void:
	for path: String in KINDS:
		var spawned := (load(path) as PackedScene).instantiate() as SpawnedAttack
		spawned.context = SpawnContext.make(Vector2.ZERO, 1, Vector2(160.0, 0.0), ARENA, 0.0)
		spawned.set(&"floor_mask", 0)
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
		assert_bool(was_live).override_failure_message("%s never hurt" % path.get_file()).is_true()
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
