class_name GuardianMoveGraphTest extends GdUnitTestSuite

## Every move a guardian can throw, and the invariants its data must keep (architecture/grd-12-guardian-fight-engine).

const SCENES: Array[String] = [
	"res://scenes/characters/guardians/autumn_guardian/autumn_guardian.tscn",
	"res://scenes/characters/guardians/bloom_guardian/bloom_guardian.tscn",
	"res://scenes/characters/guardians/frost_guardian/frost_guardian.tscn",
	"res://scenes/characters/guardians/summer_guardian/summer_guardian.tscn",
	"res://scenes/characters/guardians/mentor_guardian/mentor_guardian.tscn",
	"res://tests/fixtures/guardians/engine_guardian.tscn",
]


func test_moves_are_roots_links_and_revealed_moves_once_each() -> void:
	var thrust := GuardianAttack.new()
	var lash := GuardianAttack.new()
	lash.follow_ups = [_link(null), _link(thrust)]
	var spring := GuardianAttack.new()
	var stats := GuardianStats.new()
	stats.attacks = [lash, thrust]
	stats.finale = FinaleStats.new()
	stats.finale.revealed_attacks = [lash, spring]
	assert_array(GuardianMoveGraph.moves(stats)).is_equal([lash, thrust, spring])

func test_the_longest_string_counts_moves_and_ignores_a_repeat() -> void:
	var a := GuardianAttack.new()
	var b := GuardianAttack.new()
	var c := GuardianAttack.new()
	a.follow_ups = [_link(null), _link(b)]
	b.follow_ups = [_link(c)]
	assert_int(GuardianMoveGraph.longest_string(a)).is_equal(3)
	c.follow_ups = [_link(a)]
	assert_int(GuardianMoveGraph.longest_string(a)).is_greater(GuardianRepertoire.MAX_LINKS)

func test_every_guardian_keeps_the_engine_invariants() -> void:
	for path: String in SCENES:
		var guardian := auto_free((load(path) as PackedScene).instantiate()) as Guardian
		var tree := guardian.get_node(^"AnimationTree") as AnimationTree
		var machine := tree.tree_root as AnimationNodeStateMachine
		var label := guardian.name
		# GuardianAI._weighted_pick needs a move from the first stage, revealed moves included.
		assert_array(GuardianRepertoire.available(guardian.stats.attacks, 0)).override_failure_message(
				"%s has no move at stage 0" % label).is_not_empty()
		if guardian.stats.finale != null and not guardian.stats.finale.revealed_attacks.is_empty():
			assert_array(GuardianRepertoire.available(guardian.stats.finale.revealed_attacks, 0)).override_failure_message(
					"%s has no revealed move at stage 0" % label).is_not_empty()
		for attack: GuardianAttack in GuardianMoveGraph.moves(guardian.stats):
			var move := "%s %s" % [label, attack.resource_path.get_file() if attack.resource_path != "" else attack.resource_name]
			if attack.recall != null:
				# A recall move must be thrown from the first stage, or no window could ever open.
				assert_int(attack.from_stage).override_failure_message("%s: a recall move joins late" % move).is_equal(0)
				assert_array(attack.spawns).override_failure_message("%s: a recall move spawns" % move).is_empty()
				# Its end resets the recall cadence, so it ends its string.
				assert_array(attack.follow_ups).override_failure_message("%s: a recall move chains" % move).is_empty()
			for link: GuardianAttack in GuardianMoveGraph.links_of(attack):
				assert_object(link.recall).override_failure_message("%s links to a recall move" % move).is_null()
			assert_int(GuardianMoveGraph.longest_string(attack)).override_failure_message(
					"%s: a string longer than MAX_LINKS" % move).is_less_equal(GuardianRepertoire.MAX_LINKS)
			var slots: Array[StringName] = [GuardianAnimationResolver.attack_clip_for(attack.clip_index),
					GuardianAnimationResolver.windup_clip_for(attack.windup_index),
					GuardianAnimationResolver.recover_clip_for(attack.recovery_index)]
			for slot: StringName in slots:
				if slot == &"":
					continue
				assert_bool(machine.has_node(slot)).override_failure_message("%s names '%s', not in its tree" % [
						move, slot]).is_true()

func test_the_fixture_exercises_every_engine_feature() -> void:
	var stats := load("res://tests/fixtures/guardians/engine_guardian_stats.tres") as GuardianStats
	var moves := GuardianMoveGraph.moves(stats)
	var features := {}
	for attack: GuardianAttack in moves:
		if not attack.follow_ups.is_empty():
			features["links"] = true
		if attack.motion != null:
			features["motion"] = true
		if not attack.spawns.is_empty():
			features["spawns"] = true
		if not attack.strikes:
			features["no strike"] = true
		if attack.windup_index >= 0:
			features["wind-up"] = true
		if attack.recovery > 0.0:
			features["recovery"] = true
		if attack.from_stage > 0:
			features["stage"] = true
	assert_array(features.keys()).contains_exactly_in_any_order(
			["links", "motion", "spawns", "no strike", "wind-up", "recovery", "stage"])
	assert_array(stats.stages).is_not_empty()

func _link(attack: GuardianAttack) -> GuardianFollowUp:
	var link := GuardianFollowUp.new()
	link.attack = attack
	return link
