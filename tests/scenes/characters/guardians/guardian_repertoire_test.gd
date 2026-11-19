class_name GuardianRepertoireTest extends GdUnitTestSuite

## The stage filter and the link choice of a string (architecture/grd-12-guardian-fight-engine).

var _rolls: int = 0
var _next_roll: float = 0.0
var _in_range: bool = true


func before_test() -> void:
	_rolls = 0
	_next_roll = 0.0
	_in_range = true

func test_available_keeps_the_moves_joined_by_the_stage_in_order() -> void:
	var a := _move()
	var b := _move()
	b.from_stage = 1
	var c := _move()
	assert_array(GuardianRepertoire.available([a, b, c], 0)).is_equal([a, c])
	assert_array(GuardianRepertoire.available([a, b, c], 1)).is_equal([a, b, c])

func test_a_move_without_links_ends_the_string_without_rolling() -> void:
	assert_object(_next(_move())).is_null()
	assert_int(_rolls).is_equal(0)

func test_a_null_link_repeats_the_move() -> void:
	var move := _move()
	move.follow_ups = [_link(null, 1.0)]
	assert_object(_next(move)).is_same(move)
	assert_int(_rolls).override_failure_message("a certain link rolled").is_equal(0)

func test_the_chance_is_scaled_and_clamped() -> void:
	var move := _move()
	var thrust := _move()
	move.follow_ups = [_link(thrust, 0.4)]
	_next_roll = 0.5
	assert_object(_next(move)).is_null()
	assert_int(_rolls).is_equal(1)
	assert_object(_next(move, 0, 1.5)).is_same(thrust)
	_rolls = 0
	assert_object(_next(move, 0, 3.0)).override_failure_message("a clamped chance is certain").is_same(thrust)
	assert_int(_rolls).is_equal(0)

func test_links_are_tried_in_order() -> void:
	var move := _move()
	var first := _move()
	var second := _move()
	move.follow_ups = [_link(first, 0.3), _link(second, 1.0)]
	_next_roll = 0.9
	assert_object(_next(move)).is_same(second)

func test_a_link_waits_for_its_stage() -> void:
	var move := _move()
	var link := _link(null, 1.0)
	link.from_stage = 1
	move.follow_ups = [link]
	assert_object(_next(move, 0)).is_null()
	assert_object(_next(move, 1)).is_same(move)
	var late := _move()
	late.from_stage = 2
	move.follow_ups = [_link(late, 1.0)]
	assert_object(_next(move, 1)).override_failure_message("a link to a move not yet joined").is_null()

func test_a_wall_link_needs_the_wall() -> void:
	var move := _move()
	var link := _link(null, 1.0)
	link.needs_wall = true
	move.follow_ups = [link]
	assert_object(_next(move)).is_null()
	assert_object(GuardianRepertoire.next_link(move, 0, 1.0, 1, 3, _reach, true, false, _roll)).is_same(move)

func test_max_links_ends_the_string() -> void:
	var move := _move()
	move.follow_ups = [_link(null, 1.0)]
	assert_object(GuardianRepertoire.next_link(move, 0, 1.0, 2, 3, _reach, false, false, _roll)).is_same(move)
	assert_object(GuardianRepertoire.next_link(move, 0, 1.0, 3, 3, _reach, false, false, _roll)).is_null()
	assert_object(GuardianRepertoire.next_link(move, 0, 1.0, GuardianRepertoire.MAX_LINKS, 9, _reach, false, false,
			_roll)).override_failure_message("past the hard cap").is_null()

func test_a_requested_recall_drops_the_links() -> void:
	var move := _move()
	move.follow_ups = [_link(null, 1.0)]
	assert_object(GuardianRepertoire.next_link(move, 0, 1.0, 1, 3, _reach, false, true, _roll)).is_null()

func test_a_link_out_of_range_is_skipped() -> void:
	var move := _move()
	move.follow_ups = [_link(null, 1.0)]
	_in_range = false
	assert_object(_next(move)).is_null()

func test_a_recall_move_never_chains() -> void:
	var recall := _move()
	recall.recall = AbilityRecallStats.new()
	recall.follow_ups = [_link(null, 1.0)]
	assert_object(_next(recall)).is_null()
	assert_int(_rolls).is_equal(0)

## A recall move that left the cadence once its skill is owned no longer teaches, so it may chain (the Frost charge-back).
func test_an_owned_recall_move_with_owned_numbers_chains() -> void:
	var recall := _move()
	recall.recall = AbilityRecallStats.new()
	var back := _move()
	recall.follow_ups = [_link(back, 1.0)]
	var owned := func(move: GuardianAttack) -> GuardianAttack:
		return GuardianRepertoire.next_link(move, 0, 1.0, 1, 3, _reach, false, false, _roll, true)
	assert_object(owned.call(recall)).override_failure_message("chained with no owned numbers").is_null()
	recall.owned_weight = 0.5
	assert_object(_next(recall)).override_failure_message("chained while it still teaches").is_null()
	assert_object(owned.call(recall)).is_same(back)
	assert_int(_rolls).is_equal(0)

func test_a_recall_move_is_never_a_link() -> void:
	var move := _move()
	var recall := _move()
	recall.recall = AbilityRecallStats.new()
	move.follow_ups = [_link(recall, 1.0)]
	assert_object(_next(move)).is_null()

func _next(move: GuardianAttack, stage: int = 0, chain_scale: float = 1.0) -> GuardianAttack:
	return GuardianRepertoire.next_link(move, stage, chain_scale, 1, 3, _reach, false, false, _roll)

func _reach(_attack: GuardianAttack) -> bool:
	return _in_range

func _roll() -> float:
	_rolls += 1
	return _next_roll

func _move() -> GuardianAttack:
	return GuardianAttack.new()

func _link(attack: GuardianAttack, chance: float) -> GuardianFollowUp:
	var link := GuardianFollowUp.new()
	link.attack = attack
	link.chance = chance
	return link
