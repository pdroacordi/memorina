class_name LineGestureTest extends GdUnitTestSuite

## A LineGesture stands its strip in on play, gives the staging back when the clip ends, keeps it when it holds, and
## never undoes a later stand-in or a stage change (systems/story, STORY-37).

const G := preload("res://tests/scenes/world/story/gesture_fixture.gd")

var _staging: FactStaging
var _gesture: LineGesture


func before_test() -> void:
	SaveSystem.begin("", true)

func after_test() -> void:
	SaveSystem.begin("", true)

func _build(holds: bool = false) -> void:
	var holder := auto_free(Node.new()) as Node
	add_child(holder)
	var built := G.build(holder, holds)
	_staging = built[0]
	_gesture = built[1]

func _shown() -> String:
	return String(_staging.shown().name) if _staging.shown() != null else ""

func _clip_out() -> void:
	await get_tree().create_timer(G.FRAME_SECONDS * 3 + 0.2).timeout

func test_play_stands_the_strip_in_and_its_end_gives_the_rest_back() -> void:
	_build()
	assert_str(_shown()).is_equal("Rest")
	_gesture.play()
	assert_str(_shown()).is_equal("Gesture")
	assert_bool((_staging.get_node(^"Gesture") as StagedStrip).is_playing()).is_true()
	await _clip_out()
	assert_str(_shown()).is_equal("Rest")

func test_a_holding_gesture_stays_on_its_last_frame() -> void:
	_build(true)
	_gesture.play()
	await _clip_out()
	assert_str(_shown()).is_equal("Gesture")
	var strip := _staging.get_node(^"Gesture") as StagedStrip
	assert_bool(strip.is_playing()).is_false()
	assert_int(strip.frame).is_equal(2)
	_staging.stand_in(&"Other")
	assert_str(_shown()).is_equal("Other")

func test_a_later_stand_in_is_not_undone_by_the_clip_end() -> void:
	_build()
	_gesture.play()
	_staging.stand_in(&"Other")
	await _clip_out()
	assert_str(_shown()).is_equal("Other")

func test_a_stage_change_mid_clip_drops_it_for_good() -> void:
	_build()
	_gesture.play()
	var none: Array[FactStage] = []
	_staging.stages = none
	SaveSystem.progress_changed.emit()
	assert_str(_shown()).is_equal("")
	await _clip_out()
	assert_str(_shown()).is_equal("")

func test_find_by_id() -> void:
	_build()
	assert_object(LineGesture.find(get_tree(), &"wave")).is_same(_gesture)
	assert_object(LineGesture.find(get_tree(), &"none")).is_null()
