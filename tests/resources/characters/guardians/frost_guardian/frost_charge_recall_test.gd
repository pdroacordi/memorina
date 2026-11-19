class_name FrostChargeRecallTest extends GdUnitTestSuite

## The charge that teaches the roll gives Ivo time to press, and never lands on a roll pressed while its recall is
## open, from any distance it is thrown
## (bugs/a-prompt-roll-on-a-frost-charge-thrown-from-170-220-px-runs-out-of-grace-before-the-fists-arrive).

const CHARGE := preload("res://resources/characters/guardians/frost_guardian/frost_charge.tres")
const ROLL := preload("res://resources/characters/ivo/ivo_roll_stats.tres")
const FROST := "res://scenes/characters/guardians/frost_guardian/frost_guardian.tscn"
const STEP := 1.0 / 60.0
## Px of Ivo's hurtbox to either side of his feet (capsule radius 8).
const IVO_HALF := 8.0
## Strike s the recall's 2.0 s real window lasts: the 0.12 s sine ease-out ramp to scale 0.2 (mean scale 0.49), then
## the rest at 0.2 (WorldFreeze.slow_ramp).
const WINDOW_STRIKE := 0.12 * 0.49 + (2.0 - 0.12) * 0.2
## Strike s a player needs to see the recall and press: about 0.33 s real in the slow-down.
const REACTION := 0.1
## Strike s between the presses tried.
const PRESS_STEP := 0.025
## Px from Ivo of the closest throw: the golem's contact reach.
const NEAREST := 42.0

var _clip: Animation


func before_test() -> void:
	var golem := auto_free(load(FROST).instantiate()) as Node
	var player := golem.get_node(^"AnimationPlayer") as AnimationPlayer
	var tree := golem.get_node(^"AnimationTree") as AnimationTree
	var node := (tree.tree_root as AnimationNodeStateMachine).get_node(
			GuardianAnimationResolver.ATTACK_CLIPS[CHARGE.clip_index]) as AnimationNodeAnimation
	_clip = player.get_animation(node.animation)

func test_the_recall_opens_with_time_to_press_before_the_fists() -> void:
	var distance := NEAREST
	while distance <= CHARGE.attack_range:
		var armed := _armed_at(distance)
		assert_float(armed).override_failure_message("never armed from %.0f" % distance).is_less(CHARGE.duration)
		var contact := _first_entry(distance, INF, 0.0)
		assert_float(contact - armed).override_failure_message("from %.0f the fists arrive %.3f s after it opens" % [
				distance, contact - armed]).is_greater_equal(REACTION)
		distance += 8.0

## `recall_reach` is where the charge's keyed box first touches Ivo: its front over the lunge, plus his half width.
func test_the_recall_reach_is_the_keyed_box_front() -> void:
	var positions := _clip.find_track(^"Hitbox/CollisionShape2D:position", Animation.TYPE_VALUE)
	var scales := _clip.find_track(^"Hitbox/CollisionShape2D:scale", Animation.TYPE_VALUE)
	var front := 0.0
	var t := CHARGE.lunge_delay
	while t < CHARGE.duration:
		front = maxf(front, (_clip.value_track_interpolate(positions, t) as Vector2).x
				+ 10.0 * (_clip.value_track_interpolate(scales, t) as Vector2).x)
		t += STEP
	assert_float(CHARGE.recall_reach).is_equal_approx(front + IVO_HALF, 0.5)

func test_a_pressed_roll_is_never_hit_by_the_charge_that_taught_it() -> void:
	var distance := NEAREST
	while distance <= CHARGE.attack_range:
		var armed := _armed_at(distance)
		var press := armed
		while press <= minf(armed + WINDOW_STRIKE, CHARGE.duration):
			# Only entries from the press on: one before it is a late press, not a pressed roll hit.
			var hit := _first_entry(distance, press, press)
			assert_float(hit).override_failure_message("thrown from %.0f, rolled at %.3f: hit at %.3f" % [
					distance, press, hit]).is_equal(INF)
			press += PRESS_STEP
		distance += 8.0

## Strike s the guardian opens the recall for an Ivo standing `distance` px away.
func _armed_at(distance: float) -> float:
	var t := 0.0
	while t < CHARGE.duration:
		if CHARGE.seconds_to_blow(t, distance - _golem_x(t)) <= CHARGE.recall_lead:
			return t
		t += STEP
	return INF

## Strike s of the first box entry on Ivo at or after `from` and outside his grace, Ivo rolling away at `press`;
## INF when none.
func _first_entry(distance: float, press: float, from: float) -> float:
	var monitoring := _clip.find_track(^"Hitbox:monitoring", Animation.TYPE_VALUE)
	var positions := _clip.find_track(^"Hitbox/CollisionShape2D:position", Animation.TYPE_VALUE)
	var scales := _clip.find_track(^"Hitbox/CollisionShape2D:scale", Animation.TYPE_VALUE)
	var inside := false
	var t := 0.0
	while t < CHARGE.duration:
		var ivo := distance + ROLL.roll_distance * clampf((t - press) / ROLL.roll_time, 0.0, 1.0)
		var centre := _golem_x(t) + (_clip.value_track_interpolate(positions, t) as Vector2).x
		var half := 10.0 * (_clip.value_track_interpolate(scales, t) as Vector2).x
		var now := bool(_clip.value_track_interpolate(monitoring, t)) and absf(ivo - centre) < half + IVO_HALF
		var graced := t >= press and t <= press + CHARGE.recall.grace_time
		if now and not inside and t >= from and not graced:
			return t
		inside = now
		t += STEP
	return INF

func _golem_x(t: float) -> float:
	return CHARGE.lunge_speed * maxf(t - CHARGE.lunge_delay, 0.0)
