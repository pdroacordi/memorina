class_name CombatReachTest extends GdUnitTestSuite

## Every attacker reaches what its data commits it to, measured on the boxes its clips key
## (docs/knowledge/systems/guardians.md, "A move's attack_range"; architecture/ivo-at-2x, CORE-09, CORE-11).

const IVO_SCENE := "res://scenes/characters/ivo/ivo.tscn"
## A walker's parking spot and its moves are measured against Ivo on one floor.
const WALKER_SCENES: Array[String] = [
	"res://scenes/characters/creatures/boar/boar.tscn",
	"res://scenes/characters/creatures/scorpion/scorpion.tscn",
	"res://scenes/characters/creatures/crab/crab.tscn",
]
## A flyer's moves reach above and below it: measured against Ivo at its reach's top and bottom.
const FLYER_SCENES: Array[String] = [
	"res://scenes/characters/creatures/hornet/hornet.tscn",
	"res://scenes/characters/creatures/bat/bat.tscn",
	"res://scenes/characters/creatures/spider/spider.tscn",
]
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
## Ivo's drawn height, px: art at or below it in front of a guardian can strike him.
const IVO_DRAWN_HEIGHT := 58.0
## How far past the drawn art, px, a box may still touch.
const DRAWN_SLACK := 4.0

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

## A move without body contact hurts only with its box, so the box is open for the whole lunge: from `lunge_delay` to the
## end of the clip (GRD-10, "Só a investida").
func test_a_guardian_move_without_body_contact_keeps_its_box_open_while_it_lunges() -> void:
	for path: String in GUARDIAN_SCENES:
		var guardian := auto_free(_instance(path)) as Guardian
		for attack: GuardianAttack in guardian.stats.attacks:
			if attack.body_contact or attack.lunge_speed <= 0.0:
				continue
			var clip := _clip_of(guardian, GuardianAnimationResolver.ATTACK_CLIPS[attack.clip_index])
			var window := _window(clip)
			var label := "%s %s" % [guardian.name, attack.resource_path.get_file()]
			assert_float(window.x).override_failure_message("%s lunges at %.2f s before its box opens at %.2f s" % [
				label, attack.lunge_delay, window.x]).is_less_equal(attack.lunge_delay + 0.001)
			assert_float(window.y).override_failure_message("%s shuts its box at %.2f s of a %.2f s lunge" % [
				label, window.y, attack.duration]).is_greater_equal(attack.duration - 0.001)

## On every sampled frame of a guardian's hit window, its box touches a grounded Ivo no farther out than the art that
## frame draws at his height reaches (bugs/the-frost-swipe-hit-ivo-far-from-its-fist).
func test_every_guardian_move_touches_a_grounded_ivo_only_where_its_art_is_drawn() -> void:
	var ivo_shape := _ivo_hurtbox.shape as CapsuleShape2D
	for path: String in GUARDIAN_SCENES:
		var guardian := auto_free(_instance(path)) as Guardian
		var sprite := guardian.get_node(^"Sprite2D") as Sprite2D
		var reset := (guardian.get_node(^"AnimationPlayer") as AnimationPlayer).get_animation(&"RESET")
		for attack: GuardianAttack in guardian.stats.attacks:
			var clip := _clip_of(guardian, GuardianAnimationResolver.ATTACK_CLIPS[attack.clip_index])
			var box := _hit_box(guardian, clip)
			var at: float = box.window_start + 0.01
			for xform: Transform2D in box.xforms:
				var front := _drawn_front(sprite, clip, reset, at)
				var touch := _reach({"shape": box.shape, "xform": xform}, _ivo_hurtbox)
				assert_float(touch).override_failure_message("%s %s at %.3f s touches Ivo %.1f px out; the art reaches %.0f" % [
					guardian.name, attack.resource_path.get_file(), at, touch, front]).is_less_equal(front + ivo_shape.radius + DRAWN_SLACK)
				at += FRAME

## A move tuned to start on a player higher than the default reaches an Ivo standing that high somewhere in its window.
func test_every_guardian_move_set_to_reach_higher_lands_that_high() -> void:
	var default_height := GuardianAttack.new().attack_height
	for path: String in GUARDIAN_SCENES:
		var guardian := auto_free(_instance(path)) as Guardian
		for attack: GuardianAttack in guardian.stats.attacks:
			if attack.attack_height <= default_height:
				continue
			var box := _hit_box(guardian, _clip_of(guardian, GuardianAnimationResolver.ATTACK_CLIPS[attack.clip_index]))
			var raised := {"shape": _ivo_hurtbox.shape, "xform": Transform2D(0.0, Vector2(0.0, -attack.attack_height)) * (_ivo_hurtbox.xform as Transform2D)}
			assert_float(_reach(box, raised)).override_failure_message("%s %s starts on an Ivo %.0f px up that its box cannot touch" % [
				guardian.name, attack.resource_path.get_file(), attack.attack_height]).is_greater(0.0)

## Ivo's slash and chop both land on a walker parked at its stop distance, the chop after swing 1's shove.
func test_the_standing_combo_lands_both_swings_on_a_parked_walker() -> void:
	var phases := _ivo.attack_stats_idle.phases
	var slash := _hit_box(_ivo, _clip_of(_ivo, phases[0].state_name))
	var chop := _hit_box(_ivo, _clip_of(_ivo, phases[1].state_name))
	var gap: float = phases[0].duration - slash.window_start + chop.window_start
	for path: String in WALKER_SCENES:
		var creature := auto_free(_instance(path)) as Enemy
		var stop := creature.stats.stop_distance
		var target := _area_box(creature, ^"Hurtbox")
		var slide := _slide(phases[0].knockback_strength, creature.knockback_damping, gap)
		assert_float(_reach(slash, target)).override_failure_message("%s: the slash misses at %.1f" % [creature.name, stop]).is_greater_equal(stop)
		assert_float(_reach(chop, target)).override_failure_message(
			"%s: the chop reaches %.1f px; it is at %.1f after swing 1's shove" % [creature.name, _reach(chop, target), stop + slide]).is_greater_equal(stop + slide)

## A guardian's comfort point is outside Ivo's longest swing; it gives ground before Ivo touches its contact box, but
## not from where its main move (its most likely move that neither lunges nor leaps) was just thrown, and inside its
## comfort point (systems/guardians, "Comfort distances follow Ivo's reach").
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
		# GuardianAI leaves GIVE_GROUND back at the comfort distance, so the band must be open.
		assert_float(give_ground).override_failure_message("%s gives ground at %.1f, beyond its comfort point %.0f" % [
			guardian.name, give_ground, comfort]).is_less(comfort)

## A walker starts a move anywhere inside its reach, and inside its contact box touching already hurts, so from there
## out to the reach's far edge the move's hitbox must touch a grounded Ivo; a lunge moves first, so it only has to touch him.
func test_every_walker_move_lands_over_the_whole_reach_it_is_thrown_from() -> void:
	for path: String in WALKER_SCENES:
		var creature := auto_free(_instance(path)) as Enemy
		var contact := _area_box(creature, ^"ContactHitbox")
		for move: EnemyMove in creature.stats.moves:
			var box := _area_box(creature, NodePath(String(move.hitbox)))
			var label := "%s %s" % [creature.name, move.resource_path.get_file()]
			assert_float(_reach(box, _ivo_hurtbox)).override_failure_message("%s never touches a grounded Ivo" % label).is_greater(0.0)
			assert_bool(move.reach.position.y <= 0.0 and move.reach.end.y >= 0.0).override_failure_message(
				"%s: its reach does not hold a target on its own floor" % label).is_true()
			var raised := {"shape": _ivo_hurtbox.shape, "xform": Transform2D(0.0, Vector2(0.0, move.reach.position.y)) * _ivo_hurtbox.xform}
			assert_float(_reach(box, raised)).override_failure_message(
				"%s: its reach starts the move on an Ivo %.0f px up that the hitbox cannot touch" % [label, -move.reach.position.y]).is_greater(0.0)
			if move.lunge_speed > 0.0:
				continue
			var near := maxf(_farthest(contact, _ivo_hurtbox),
					_farthest({"shape": contact.shape, "xform": Transform2D.FLIP_X * contact.xform}, _ivo_hurtbox))
			var miss := _first_miss(box, _ivo_hurtbox, near, move.reach.end.x)
			assert_float(miss).override_failure_message("%s is thrown from %.1f to %.0f px but misses a grounded Ivo at %.1f" % [
				label, near, move.reach.end.x, miss]).is_equal(-1.0)

## A flyer starts a move with its target anywhere in the reach, top and bottom included. A standing move (the bite)
## touches an Ivo at both heights from where its contact already hurts out to the reach's far edge; a dash or a swoop,
## flown through FlightComponent from the AI's own steer, touches an Ivo standing at each corner of the reach.
func test_every_flyer_move_lands_across_its_reach_top_and_bottom() -> void:
	for path: String in FLYER_SCENES:
		var creature := auto_free(_instance(path)) as Enemy
		var ai := creature.get_node(^"AI") as EnemyAI
		var contact := _area_box(creature, ^"ContactHitbox")
		for move: EnemyMove in creature.stats.moves:
			var box := _area_box(creature, NodePath(String(move.hitbox)))
			var label := "%s %s" % [creature.name, move.resource_path.get_file()]
			if ai is CeilingAI or move.lunge_speed > 0.0:
				for corner: Vector2 in _corners(move.reach):
					var xforms: Array[Transform2D] = []
					for point: Vector2 in _flown(creature, ai, move, corner):
						xforms.append(Transform2D(0.0, point) * (box.xform as Transform2D))
					var ivo := {"shape": _ivo_hurtbox.shape, "xform": Transform2D(0.0, corner) * (_ivo_hurtbox.xform as Transform2D)}
					assert_bool(_touches({"shape": box.shape, "xforms": xforms}, ivo, 0.0)).override_failure_message(
						"%s misses an Ivo standing at %s of its reach" % [label, corner]).is_true()
				continue
			for height: float in [move.reach.position.y, move.reach.end.y]:
				var ivo := {"shape": _ivo_hurtbox.shape, "xform": Transform2D(0.0, Vector2(0.0, height)) * (_ivo_hurtbox.xform as Transform2D)}
				var near := maxf(_farthest(contact, ivo),
						_farthest({"shape": contact.shape, "xform": Transform2D.FLIP_X * contact.xform}, ivo))
				var miss := _first_miss(box, ivo, near, move.reach.end.x)
				assert_float(miss).override_failure_message("%s is thrown at an Ivo %.0f px down from %.1f to %.0f px but misses at %.1f" % [
					label, height, near, move.reach.end.x, miss]).is_equal(-1.0)

## A walker parks where touching it does not hurt.
func test_every_walker_parks_clear_of_its_body() -> void:
	for path: String in WALKER_SCENES:
		var creature := auto_free(_instance(path)) as Enemy
		var contact := _area_box(creature, ^"ContactHitbox")
		var touch := maxf(_farthest(contact, _ivo_hurtbox),
				_farthest({"shape": contact.shape, "xform": Transform2D.FLIP_X * contact.xform}, _ivo_hurtbox))
		assert_float(creature.stats.stop_distance).override_failure_message("%s parks at %.1f, inside its %.1f px contact" % [
			creature.name, creature.stats.stop_distance, touch]).is_greater(touch)

func test_slide_is_the_integral_of_the_decayed_push() -> void:
	assert_float(_slide(60.0, 6.0, 1000.0)).is_equal_approx(10.0, 0.001)
	assert_float(_slide(60.0, 6.0, 0.0)).is_equal(0.0)

## The four corners of a reach box, facing east.
func _corners(reach: Rect2) -> Array[Vector2]:
	return [reach.position, Vector2(reach.end.x, reach.position.y), Vector2(reach.position.x, reach.end.y), reach.end]

## The positions a flyer takes through `move`'s hit window, from the origin at an Ivo whose feet are at `feet`: the
## AI's steer (a locked dash aim, or a swoop path) flown through FlightComponent each physics frame, with no wind.
func _flown(creature: Enemy, ai: EnemyAI, move: EnemyMove, feet: Vector2) -> Array[Vector2]:
	var tuning := creature.stats.locomotion
	var position := Vector2.ZERO
	var velocity := Vector2.ZERO
	var points: Array[Vector2] = [position]
	var swoop := SwoopPath.new(position, feet + EnemyAI.CHEST, move.lunge_speed) if ai is CeilingAI else null
	var aim := FlyerAI.aim_at(position, feet)
	var length := minf(swoop.duration, move.active) if swoop != null else move.active
	var t := 0.0
	while t < length:
		t += FRAME
		var steer := CeilingAI.swoop_steer(swoop, t, position) if swoop != null else aim * move.lunge_speed
		velocity = FlightComponent.steered(velocity, steer, Vector2.ZERO, tuning, FRAME)
		position += velocity * FRAME
		points.append(position)
	return points

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

## The frontmost x, in px facing +x, of the opaque art the clip shows at `at` from Ivo's drawn height to the floor.
func _drawn_front(sprite: Sprite2D, clip: Animation, reset: Animation, at: float) -> float:
	var texture := _keyed(clip, reset, "Sprite2D:texture", at, sprite.texture) as Texture2D
	var hframes: int = _keyed(clip, reset, "Sprite2D:hframes", at, sprite.hframes)
	var frame: int = _keyed(clip, reset, "Sprite2D:frame", at, sprite.frame)
	var image := texture.get_image()
	var size := Vector2i(image.get_width() / hframes, image.get_height())
	var xform := sprite.transform
	var front := -INF
	for row: int in size.y:
		var top := (xform * Vector2(0.0, row - size.y / 2.0)).y
		var bottom := (xform * Vector2(0.0, row + 1 - size.y / 2.0)).y
		if maxf(top, bottom) <= -IVO_DRAWN_HEIGHT or minf(top, bottom) >= 0.0:
			continue
		for column: int in size.x:
			if image.get_pixel(frame * size.x + column, row).a <= 0.0:
				continue
			for edge: int in [column, column + 1]:
				front = maxf(front, (xform * Vector2(edge - size.x / 2.0, 0.0)).x)
	return front

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
