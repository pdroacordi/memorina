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

func test_a_run_asks_the_context_to_run() -> void:
	var step := C.walk(&"girl", 58.0)
	step.run = true
	step.begin(_context)
	assert_array(_calls()).is_equal(["walk:girl:58:1.00:run"])

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

func test_a_fade_covers_in_its_colour() -> void:
	var fade := CutsceneFade.new()
	fade.colour = Color.WHITE
	fade.seconds = 0.8
	assert_bool(fade.begin(_context).tick(0.5)).is_false()
	fade.land(_context)
	assert_array(_calls()).is_equal(["fade:true:0.8:ffffff", "fade:true:0.0:ffffff"])

func test_a_bloom_centres_on_itself_or_on_an_id_and_lands_at_once() -> void:
	_context.points[&"well"] = Vector2(300, 100)
	var step := CutsceneBloom.new()
	step.bloom_id = &"well"
	step.offset = Vector2(0, 40)
	step.strength = -1.0
	step.seconds = 2.0
	var task := step.begin(_context)
	assert_bool(task.tick(1.0)).is_false()
	assert_bool(task.tick(1.0)).is_true()
	step.at = &"girl"
	step.land(_context)
	assert_array(_calls()).is_equal(["bloom:well:300,140:-1.0:2.0", "bloom:well:90,328:-1.0:0.0"])
	assert_array(step.names()).is_equal([&"well", &"girl"])

func test_a_music_mark_waits_for_the_position_or_for_no_music() -> void:
	var step := CutsceneMusicMark.new()
	step.seconds = 12.0
	_context.music_at = 3.0
	var task := step.begin(_context)
	assert_bool(task.tick(1.0)).is_false()
	_context.music_at = 12.0
	assert_bool(task.tick(0.0)).is_true()
	_context.music_at = -1.0
	assert_bool(step.begin(_context).tick(0.0)).is_true()

## With `every`, the wait ends on the next bar line after where the music was, or when a looping cue wraps.
func test_a_music_mark_every_bar_waits_for_the_next_one() -> void:
	var step := CutsceneMusicMark.new()
	step.seconds = 0.5
	step.every = 2.0
	assert_float(step.next_mark(0.2)).is_equal(0.5)
	assert_float(step.next_mark(3.1)).is_equal_approx(4.5, 0.0001)
	assert_float(step.next_mark(4.5)).is_equal_approx(4.5, 0.0001)
	_context.music_at = 3.1
	var task := step.begin(_context)
	_context.music_at = 4.4
	assert_bool(task.tick(0.0)).is_false()
	_context.music_at = 4.5
	assert_bool(task.tick(0.0)).is_true()
	_context.music_at = 7.0
	var wraps := step.begin(_context)
	_context.music_at = 8.4
	assert_bool(wraps.tick(0.0)).is_false()
	_context.music_at = 0.6
	assert_bool(wraps.tick(0.0)).is_true()
	_context.music_at = -1.0
	assert_bool(step.begin(_context).tick(0.0)).is_true()

func test_a_muffle_asks_for_its_amount_at_once() -> void:
	var step := CutsceneMuffle.new()
	step.amount = 0.8
	assert_bool(step.begin(_context).tick(0.0)).is_true()
	step.land(_context)
	assert_array(_calls()).is_equal(["muffle:0.8", "muffle:0.8"])

func test_a_music_mark_fits_before_the_end_of_its_cue() -> void:
	var step := CutsceneMusicMark.new()
	step.seconds = 1.0
	var cue := MusicCue.new()
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = 8000
	var data := PackedByteArray()
	data.resize(16000)
	wav.data = data
	cue.stream = wav
	assert_bool(step.fits(cue)).is_true()
	step.seconds = 4.0
	assert_bool(step.fits(cue)).is_false()

func test_a_fray_agitates_for_its_seconds_then_calms() -> void:
	var step := CutsceneFray.new()
	step.actor = &"girl"
	step.seconds = 0.5
	var task := step.begin(_context)
	assert_bool(task.tick(0.3)).is_false()
	assert_bool(task.tick(0.3)).is_true()
	assert_bool(task.tick(0.3)).is_true()
	var stopped := step.begin(_context)
	stopped.stop()
	step.land(_context)
	assert_array(_calls()).is_equal(["fray:girl:true", "fray:girl:false", "fray:girl:true", "fray:girl:false",
			"fray:girl:false"])

func _engraving(dissolve: bool) -> CutsceneEngraving:
	var step := CutsceneEngraving.new()
	step.frame = EngravingFrame.new()
	step.frame.seconds = 6.5
	step.ink = preload("res://resources/songs/palettes/winter_palette.tres")
	step.dissolve = dissolve
	return step

func test_an_engraving_shows_its_frame_for_its_seconds_and_lands_its_end() -> void:
	var step := _engraving(true)
	var task := step.begin(_context)
	assert_bool(task.tick(6.0)).is_false()
	assert_bool(task.tick(0.6)).is_true()
	step.land(_context)
	var tint := step.ink.tint.to_html(false)
	assert_array(_calls()).is_equal(["engrave:6.5:%s:true" % tint, "engrave:6.5:%s:false" % tint, "land_engraving"])
	assert_array(step.subjects()).is_equal([CutsceneEngraving.SUBJECT])
	assert_array(step.names()).is_empty()

func test_the_first_engraving_reveals_from_paper() -> void:
	_engraving(false).begin(_context)
	assert_array(_calls()).is_equal(["engrave:6.5:%s:false" % _engraving(false).ink.tint.to_html(false)])

func test_an_engraving_clear_dithers_out_and_lands_bare_paper() -> void:
	var step := CutsceneEngravingClear.new()
	step.seconds = 1.0
	var task := step.begin(_context)
	assert_bool(task.tick(0.9)).is_false()
	assert_bool(task.tick(0.2)).is_true()
	step.land(_context)
	assert_array(_calls()).is_equal(["clear_engraving:1.0", "clear_engraving:0.0"])
	assert_array(step.subjects()).is_equal([CutsceneEngraving.SUBJECT])

func test_an_exit_takes_the_actor_out_at_once() -> void:
	var step := CutsceneExit.new()
	step.actor = &"alba"
	assert_bool(step.begin(_context).tick(0.0)).is_true()
	step.land(_context)
	assert_array(_calls()).is_equal(["exit:alba", "exit:alba"])
	assert_array(step.subjects()).is_equal([&"alba"])

func test_the_credits_roll_until_the_roll_says_done_and_land_its_end() -> void:
	var step := CutsceneCredits.new()
	step.sheet = CreditsSheet.new()
	step.sheet.sections = [CreditsSection.new(), CreditsSection.new()]
	var task := step.begin(_context)
	assert_bool(task.tick(100.0)).is_false()
	_context.credits_over = true
	assert_bool(task.tick(0.0)).is_true()
	step.land(_context)
	assert_array(_calls()).is_equal(["credits:2", "land_credits"])
	assert_array(step.subjects()).is_equal([CutsceneCredits.SUBJECT])
	assert_array(step.names()).is_empty()

func test_a_year_runs_for_its_seconds_and_lands_settled() -> void:
	var step := CutsceneYear.new()
	step.seconds = 40.0
	var task := step.begin(_context)
	assert_bool(task.tick(39.0)).is_false()
	assert_bool(task.tick(1.5)).is_true()
	step.land(_context)
	assert_array(_calls()).is_equal(["year:40.0", "settle_year"])
	assert_array(step.subjects()).is_equal([CutsceneYear.SUBJECT])
	assert_array(step.names()).is_empty()

func test_a_second_ink_inks_the_second_key_and_none_keeps_the_first() -> void:
	var step := _engraving(true)
	step.second_ink = preload("res://resources/story/engraving/flower_ink.tres")
	step.begin(_context)
	step.land(_context)
	var tint := step.ink.tint.to_html(false)
	var pink := step.second_ink.colour.to_html(false)
	assert_array(_calls()).is_equal(["engrave:6.5:%s:true:%s" % [tint, pink], "engrave:6.5:%s:false:%s" % [tint, pink],
			"land_engraving"])

func test_an_engraving_clear_that_hides_takes_the_paper_away_at_once() -> void:
	var step := CutsceneEngravingClear.new()
	step.seconds = 0.0
	step.hide = true
	assert_bool(step.begin(_context).tick(0.0)).is_true()
	step.land(_context)
	assert_array(_calls()).is_equal(["hide_engraving", "hide_engraving"])
	assert_array(step.subjects()).is_equal([CutsceneEngraving.SUBJECT])
