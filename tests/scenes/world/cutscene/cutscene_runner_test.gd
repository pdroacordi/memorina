class_name CutsceneRunnerTest extends GdUnitTestSuite

## The runner walks a scene's tree: a sequence one step at a time, a together all at once until the last ends, a branch
## read when reached, and `to_land` stops before a talk.

const C := preload("res://tests/resources/cutscene/cutscene_fixture.gd")
const D := preload("res://tests/resources/dialogue/dialogue_fixture.gd")


func before_test() -> void:
	SaveSystem.begin("", true)

func after_test() -> void:
	SaveSystem.begin("", true)

func _steps(runner: CutsceneRunner, ids: PackedInt32Array) -> Array[CutsceneStep]:
	var found: Array[CutsceneStep] = []
	for id: int in ids:
		found.append(runner.step(id))
	return found

func test_a_sequence_begins_one_step_at_a_time() -> void:
	var a := C.wait(1.0)
	var b := C.wait(2.0)
	var runner := CutsceneRunner.new(C.scene(&"s", [a, b]), SaveSystem.player_data)
	var first := runner.next()
	assert_array(_steps(runner, first)).contains_exactly([a])
	assert_int(runner.next().size()).is_equal(0)
	runner.done(first[0])
	var second := runner.next()
	assert_array(_steps(runner, second)).contains_exactly([b])
	assert_bool(runner.is_finished()).is_false()
	runner.done(second[0])
	assert_int(runner.next().size()).is_equal(0)
	assert_bool(runner.is_finished()).is_true()

func test_a_together_begins_all_and_ends_with_the_last() -> void:
	var a := C.wait(1.0)
	var b := C.wait(2.0)
	var after := C.wait(3.0)
	var runner := CutsceneRunner.new(C.scene(&"s", [C.together([a, b]), after]), SaveSystem.player_data)
	var both := runner.next()
	assert_array(_steps(runner, both)).contains_exactly([a, b])
	runner.done(both[0])
	assert_int(runner.next().size()).is_equal(0)
	runner.done(both[1])
	assert_array(_steps(runner, runner.next())).contains_exactly([after])

func test_a_nested_sequence_runs_inside_a_together() -> void:
	var a := C.wait(1.0)
	var b := C.wait(1.0)
	var c := C.wait(1.0)
	var runner := CutsceneRunner.new(C.scene(&"s", [C.together([C.sequence([a, b]), c])]), SaveSystem.player_data)
	var first := runner.next()
	assert_array(_steps(runner, first)).contains_exactly([a, c])
	runner.done(first[0])
	assert_array(_steps(runner, runner.next())).contains_exactly([b])

## Read when reached: a fact written by an earlier step decides it.
func test_a_branch_is_read_when_reached() -> void:
	var first := C.wait(1.0)
	var heard := C.wait(2.0)
	var unheard := C.wait(3.0)
	var cases: Array[CutsceneCase] = [
		C.case_of([D.fact(SaveFact.Kind.DIALOGUE_HEARD, &"talk")], [heard]),
		C.case_of([], [unheard]),
	]
	var runner := CutsceneRunner.new(C.scene(&"s", [first, C.branch(cases)]), SaveSystem.player_data)
	var ids := runner.next()
	SaveSystem.mark_dialogue_heard(&"talk")
	runner.done(ids[0])
	assert_array(_steps(runner, runner.next())).contains_exactly([heard])

func test_a_branch_with_no_case_holding_plays_nothing() -> void:
	var cases: Array[CutsceneCase] = [C.case_of([D.fact(SaveFact.Kind.DIALOGUE_HEARD, &"never")], [C.wait(1.0)])]
	var runner := CutsceneRunner.new(C.scene(&"s", [C.branch(cases)]), SaveSystem.player_data)
	assert_int(runner.next().size()).is_equal(0)
	assert_bool(runner.is_finished()).is_true()

## A skip lands what runs and what is left, in order, and leaves the talk to begin: it never chooses for the player.
func test_to_land_stops_before_a_talk() -> void:
	var a := C.wait(1.0)
	var b := C.wait(1.0)
	var talk := C.talk()
	var after := C.wait(1.0)
	var runner := CutsceneRunner.new(C.scene(&"s", [a, C.together([b]), talk, after]), SaveSystem.player_data)
	runner.next()
	assert_array(runner.to_land()).contains_exactly([a, b])
	assert_array(_steps(runner, runner.next())).contains_exactly([talk])
	assert_bool(runner.is_finished()).is_false()

func test_to_land_with_no_talk_finishes_the_scene() -> void:
	var a := C.wait(1.0)
	var b := C.wait(1.0)
	var runner := CutsceneRunner.new(C.scene(&"s", [a, b]), SaveSystem.player_data)
	runner.next()
	assert_array(runner.to_land()).contains_exactly([a, b])
	assert_bool(runner.is_finished()).is_true()

func test_an_empty_scene_is_finished_at_once() -> void:
	var runner := CutsceneRunner.new(C.scene(&"s", []), SaveSystem.player_data)
	assert_int(runner.next().size()).is_equal(0)
	assert_bool(runner.is_finished()).is_true()
