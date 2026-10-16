class_name CutsceneStepsTest extends GdUnitTestSuite

## Each step asks the context for what it starts, and lands its end state at once for a skip.

const C := preload("res://tests/resources/cutscene/cutscene_fixture.gd")

var _context: C.Recorder


func before_test() -> void:
	_context = C.Recorder.new()
	_context.points = {&"girl": Vector2(90, 288), &"ivo": Vector2(110, 288), &"bed": Vector2(58, 288)}

func _calls() -> Array:
	return Array(_context.calls)

func test_a_walk_to_a_mark_walks_and_lands_facing_the_way_it_went() -> void:
	var step := C.walk(&"girl", 0.0, 0.5)
	step.mark = &"bed"
	step.x = 2.0
	assert_bool(step.begin(_context).tick(0.0)).is_false()
	step.land(_context)
	assert_array(_calls()).is_equal(["walk:girl:60:0.50", "face:girl:-1", "place:girl:60,288"])

func test_face_away_turns_its_back() -> void:
	var step := CutsceneFace.new()
	step.actor = &"girl"
	step.toward = &"ivo"
	step.away = true
	assert_bool(step.begin(_context).tick(0.0)).is_true()
	step.away = false
	step.land(_context)
	assert_array(_calls()).is_equal(["face:girl:-1", "face:girl:1"])

func test_a_gesture_waits_unless_told_not_to_and_lands_its_settle() -> void:
	var step := C.gesture(&"girl", &"sit")
	assert_bool(step.begin(_context).tick(0.0)).is_false()
	step.wait = false
	assert_bool(step.begin(_context).tick(0.0)).is_true()
	step.land(_context)
	assert_array(_calls()).is_equal(["gesture:girl:sit", "gesture:girl:sit", "land_gesture:girl:sit"])

func test_a_camera_frames_the_mean_of_its_targets() -> void:
	var step := C.camera([&"girl", &"ivo"], 2.0, 1.2)
	var task := step.begin(_context)
	assert_bool(task.tick(1.0)).is_false()
	assert_bool(task.tick(0.3)).is_true()
	step.land(_context)
	assert_array(_calls()).is_equal(["frame:100,248:2.0:1.2", "frame:100,248:2.0:0.0"])

func test_bars_fade_and_show_land_at_once() -> void:
	var bars := CutsceneBars.new()
	var fade := CutsceneFade.new()
	var shown := CutsceneShow.new()
	shown.visual = &"light"
	shown.alpha = 0.5
	for step: CutsceneStep in [bars, fade, shown]:
		step.begin(_context)
		step.land(_context)
	assert_array(_calls()).is_equal(["bars:true:0.6", "bars:true:0.0", "fade:true:0.5", "fade:true:0.0",
			"show:light:0.5:0.5", "show:light:0.5:0.0"])

func test_a_wait_counts_scaled_seconds() -> void:
	var task := C.wait(0.5).begin(_context)
	assert_bool(task.tick(0.3)).is_false()
	assert_bool(task.tick(0.3)).is_true()

func test_a_talk_waits_for_its_end_unless_it_is_the_hand_off() -> void:
	assert_bool(C.talk(true).begin(_context).tick(0.0)).is_false()
	assert_bool(C.talk(false).begin(_context).tick(0.0)).is_true()
	assert_array(_calls()).is_equal(["talk:110", "talk:110"])

func test_pose_emote_silence_and_place() -> void:
	var pose := CutscenePose.new()
	pose.pose = DialogueBeat.Pose.GUITAR
	var emote := CutsceneEmote.new()
	emote.actor = &"girl"
	var place := CutscenePlace.new()
	place.actor = &"ivo"
	place.mark = &"bed"
	var silence := CutsceneSilence.new()
	pose.begin(_context)
	assert_bool(emote.begin(_context).tick(1.0)).is_false()
	place.begin(_context)
	silence.begin(_context)
	assert_array(_calls()).is_equal(["pose:1", "emote:girl:0:1.2", "place:ivo:58,288", "silence"])

func test_a_stage_stands_a_staging_in_and_lands_at_once() -> void:
	var step := CutsceneStage.new()
	step.staging = &"guitar_staging"
	step.child = &""
	step.seconds = 0.5
	assert_bool(step.begin(_context).tick(0.0)).is_false()
	step.land(_context)
	assert_array(_calls()).is_equal(["stage:guitar_staging::0.5", "stage:guitar_staging::0.0"])
