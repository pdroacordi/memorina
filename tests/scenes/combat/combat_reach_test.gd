class_name CombatReachTest extends GdUnitTestSuite

## Every attacker reaches what its data commits it to, measured on the boxes its clips key
## (docs/knowledge/systems/guardians.md, "A move's attack_range"; architecture/ivo-at-2x, CORE-09, CORE-11).

const IVO_SCENE := "res://scenes/characters/ivo/ivo.tscn"
const BRUTE_SCENE := "res://scenes/characters/enemies/brute_shadow/brute_shadow.tscn"
const GUARDIAN_SCENES: Array[String] = [
	"res://scenes/characters/guardians/bloom_guardian/bloom_guardian.tscn",
	"res://scenes/characters/guardians/frost_guardian/frost_guardian.tscn",
]
## Scan limits and step of a reach measurement, in px.
const SCAN_FROM := -300.0
const SCAN_TO := 300.0
const SCAN_STEP := 0.5
## Sampling step through a hit window, in s.
const FRAME := 1.0 / 60.0

var _ivo: Player
var _ivo_hurtbox: Dictionary


func before_test() -> void:
	_ivo = auto_free(_instance(IVO_SCENE)) as Player
	_ivo_hurtbox = _area_box(_ivo, ^"Hurtbox")

## GuardianAI throws a move at any distance up to its attack_range, and inside the contact box's reach touching already
## hurts, so from there out the move must touch a grounded Ivo; a lunge or leap moves first, so it only has to touch him.
func test_every_guardian_move_lands_over_the_whole_distance_it_is_thrown_from() -> void:
	for path: String in GUARDIAN_SCENES:
		var guardian := auto_free(_instance(path)) as Guardian
		var contact := _area_box(guardian, ^"ContactHitbox")
		for attack: GuardianAttack in guardian.stats.attacks:
			var clip := _clip_of(guardian, GuardianAnimationResolver.ATTACK_CLIPS[attack.clip_index])
			var box := _hit_box(guardian, clip)
			var label := "%s %s" % [guardian.name, attack.resource_path.get_file()]
			assert_float(_reach(box, _ivo_hurtbox)).override_failure_message("%s never touches a grounded Ivo" % label).is_greater(0.0)
			if attack.lunge_speed > 0.0 or attack.leap_impulse > 0.0:
				continue
			# The contact box does not turn with the guardian; the hit box does.
			for contact_xform: Transform2D in [contact.xform, Transform2D.FLIP_X * contact.xform]:
				var near := _farthest({"shape": contact.shape, "xform": contact_xform}, _ivo_hurtbox)
				var miss := _first_miss(box, _ivo_hurtbox, near, attack.attack_range)
				assert_float(miss).override_failure_message("%s is thrown from %.1f to %.0f px but misses a grounded Ivo at %.1f" % [
					label, near, attack.attack_range, miss]).is_equal(-1.0)

## Ivo's slash and chop both land on a brute parked at its stop distance, the chop after swing 1's shove.
func test_the_standing_combo_lands_both_swings_on_a_parked_brute() -> void:
	var brute := auto_free(_instance(BRUTE_SCENE)) as BruteShadow
	var stop := _brute_stats(brute).stop_distance
	var target := _area_box(brute, ^"Hurtbox")
	var phases := _ivo.attack_stats_idle.phases
	var slash := _hit_box(_ivo, _clip_of(_ivo, phases[0].state_name))
	var chop := _hit_box(_ivo, _clip_of(_ivo, phases[1].state_name))
	var gap: float = phases[0].duration - slash.window_start + chop.window_start
	var slide := _slide(phases[0].knockback_strength, brute.knockback_damping, gap)
	assert_float(_reach(slash, target)).is_greater_equal(stop)
	assert_float(_reach(chop, target)).override_failure_message(
		"the chop reaches %.1f px; the brute is at %.1f after swing 1's shove" % [_reach(chop, target), stop + slide]).is_greater_equal(stop + slide)

## A guardian's comfort point is outside Ivo's longest swing; it gives ground before Ivo touches its contact box, but
## not from where its main move (its most likely move that neither lunges nor leaps) was just thrown
## (systems/guardians, "Comfort distances follow Ivo's reach").
func test_every_guardian_keeps_its_comfort_point_outside_ivos_reach_and_gives_ground_only_close_in() -> void:
	var swings: Array[Dictionary] = []
	for clip: StringName in [&"idle_attack_swing_in", &"idle_attack_swing_out", &"run_attack_swing_in",
			&"run_attack_swing_out", &"jump_attack"]:
		swings.append(_hit_box(_ivo, (_ivo.get_node(^"AnimationPlayer") as AnimationPlayer).get_animation(clip)))
	for path: String in GUARDIAN_SCENES:
		var guardian := auto_free(_instance(path)) as Guardian
		var hurtbox := _area_box(guardian, ^"Hurtbox")
		var contact := _area_box(guardian, ^"ContactHitbox")
		var reach := 0.0
		for swing: Dictionary in swings:
			# Its hurtbox may sit off centre and does not turn, so the far side counts.
			for xform: Transform2D in [hurtbox.xform, Transform2D.FLIP_X * hurtbox.xform]:
				reach = maxf(reach, _farthest(swing, {"shape": hurtbox.shape, "xform": xform}))
		var touch := maxf(_farthest(contact, _ivo_hurtbox),
				_farthest({"shape": contact.shape, "xform": Transform2D.FLIP_X * contact.xform}, _ivo_hurtbox))
		var comfort := guardian.stats.comfort_distance
		var give_ground := guardian.stats.give_ground_distance
		var main := _main_move(guardian.stats.attacks)
		assert_float(comfort).override_failure_message("%s's comfort point %.0f is inside Ivo's %.1f px reach" % [
			guardian.name, comfort, reach]).is_greater_equal(reach)
		assert_float(give_ground).override_failure_message("%s gives ground at %.1f, inside its %.1f px contact" % [
			guardian.name, give_ground, touch]).is_greater(touch)
		assert_float(give_ground).override_failure_message("%s gives ground at %.1f, so it backs off after its %s from %.0f" % [
			guardian.name, give_ground, main.resource_path.get_file(), main.attack_range]).is_less(main.attack_range)

## The brute swings only where its swing lands, and parks where touching it does not hurt.
func test_the_brute_swings_from_inside_its_reach_and_parks_clear_of_its_body() -> void:
	var brute := auto_free(_instance(BRUTE_SCENE)) as BruteShadow
	var stats := _brute_stats(brute)
	var swing := _hit_box(brute, _clip_of(brute, BruteShadowAnimationResolver.ATTACK))
	assert_float(_reach(swing, _ivo_hurtbox)).is_greater_equal(stats.attack_range)
	assert_float(stats.stop_distance).is_less_equal(stats.attack_range)
	assert_float(stats.stop_distance).is_greater(_reach(_area_box(brute, ^"CollisionHitbox"), _ivo_hurtbox))

func test_slide_is_the_integral_of_the_decayed_push() -> void:
	assert_float(_slide(60.0, 6.0, 1000.0)).is_equal_approx(10.0, 0.001)
	assert_float(_slide(60.0, 6.0, 0.0)).is_equal(0.0)

## A scene's root, never added to the tree, so no _ready runs.
func _instance(path: String) -> Node:
	return (load(path) as PackedScene).instantiate()

## The highest-weight move that neither lunges nor leaps.
func _main_move(attacks: Array[GuardianAttack]) -> GuardianAttack:
	var main: GuardianAttack = null
	for attack: GuardianAttack in attacks:
		if attack.lunge_speed > 0.0 or attack.leap_impulse > 0.0:
			continue
		if main == null or attack.weight > main.weight:
			main = attack
	return main

func _brute_stats(brute: BruteShadow) -> BruteShadowAttackStats:
	return (brute.get_node(^"AI") as BruteShadowAI).attack_stats

## The animation an AnimationTree state plays.
func _clip_of(root: Node, state: StringName) -> Animation:
	var tree := root.get_node(^"AnimationTree") as AnimationTree
	var node := (tree.tree_root as AnimationNodeStateMachine).get_node(state) as AnimationNodeAnimation
	return (root.get_node(^"AnimationPlayer") as AnimationPlayer).get_animation(node.animation)

## The Hitbox shape and its transforms in the root's space, facing +x, sampled each physics frame while its clip keeps it on.
func _hit_box(root: Node, clip: Animation) -> Dictionary:
	var player := root.get_node(^"AnimationPlayer") as AnimationPlayer
	var reset := player.get_animation(&"RESET")
	var node := root.get_node(^"Hitbox/CollisionShape2D") as CollisionShape2D
	var window := _window(clip)
	var shape := node.shape.duplicate() as Shape2D
	var radius: Variant = _keyed(clip, reset, "Hitbox/CollisionShape2D:shape:radius", window.x + 0.01, null)
	if radius != null:
		shape.set(&"radius", radius)
	var xforms: Array[Transform2D] = []
	var at := window.x + 0.01
	while at < window.y:
		xforms.append(Transform2D(
			_keyed(clip, reset, "Hitbox/CollisionShape2D:rotation", at, node.rotation),
			_keyed(clip, reset, "Hitbox/CollisionShape2D:scale", at, node.scale),
			0.0,
			_keyed(clip, reset, "Hitbox/CollisionShape2D:position", at, node.position)))
		at += FRAME
	return {"shape": shape, "xforms": xforms, "window_start": window.x}

func _area_box(root: Node, area_path: NodePath) -> Dictionary:
	var area := root.get_node(area_path) as Node2D
	var node := area.get_node(^"CollisionShape2D") as CollisionShape2D
	return {"shape": node.shape, "xform": area.transform * node.transform}

## When the clip turns the Hitbox on and off, in s.
func _window(clip: Animation) -> Vector2:
	var track := clip.find_track(^"Hitbox:monitoring", Animation.TYPE_VALUE)
	assert_int(track).override_failure_message("%s keys no Hitbox:monitoring" % clip.resource_name).is_not_equal(-1)
	var count := clip.track_get_key_count(track)
	for key: int in count:
		if clip.track_get_key_value(track, key) == true:
			var end := clip.track_get_key_time(track, key + 1) if key + 1 < count else clip.length
			return Vector2(clip.track_get_key_time(track, key), end)
	return Vector2(0.0, clip.length)

func _keyed(clip: Animation, reset: Animation, path: String, at: float, fallback: Variant) -> Variant:
	for animation: Animation in [clip, reset]:
		if animation == null:
			continue
		var track := animation.find_track(NodePath(path), Animation.TYPE_VALUE)
		if track != -1:
			return animation.value_track_interpolate(track, at if animation == clip else 0.0)
	return fallback

## The farthest centre-to-centre distance, in px, at which the box touches a target standing on the same floor in
## front of it; the target's own box may be off-centre and does not turn, so the nearer of its two sides counts.
func _reach(box: Dictionary, target: Dictionary) -> float:
	var reach := INF
	for target_xform: Transform2D in [target.xform, Transform2D.FLIP_X * target.xform]:
		reach = minf(reach, _farthest(box, {"shape": target.shape, "xform": target_xform}))
	return reach

## The farthest distance, in px, at which the box touches the target as authored; 0 if it never does.
func _farthest(box: Dictionary, target: Dictionary) -> float:
	var farthest := 0.0
	var distance := SCAN_FROM
	while distance <= SCAN_TO:
		if _touches(box, target, distance):
			farthest = maxf(farthest, distance)
		distance += SCAN_STEP
	return farthest

## The nearest distance in `from..to`, in px, at which the box misses the target; -1 if it touches all the way.
func _first_miss(box: Dictionary, target: Dictionary, from: float, to: float) -> float:
	var distance := from
	while distance <= to:
		if not _touches(box, target, distance):
			return distance
		distance += SCAN_STEP
	return -1.0

## Whether the box, at any of its sampled transforms, touches the target standing `distance` px in front.
func _touches(box: Dictionary, target: Dictionary, distance: float) -> bool:
	var placed := Transform2D(0.0, Vector2(distance, 0.0)) * (target.xform as Transform2D)
	for xform: Transform2D in box.get("xforms", [box.get("xform")]):
		if (box.shape as Shape2D).collide(xform, target.shape, placed):
			return true
	return false

## How far a body pushed at `speed` px/s slides in `seconds` under Character.apply_knockback_decay's damping.
func _slide(speed: float, damping: float, seconds: float) -> float:
	return speed / damping * (1.0 - exp(-damping * seconds))
