class_name MusicCueTest extends GdUnitTestSuite

## Every cue in resources/music/ names one stem per stream; a looping cue's stems loop and share one length.

const DIR := "res://resources/music"
## Onsets measured in the render of wife_song_epilogue.ogg (s; docs/knowledge/music/wifes-song.md, "The epilogue's
## render"); the epilogue's marks read them.
const EPILOGUE_FLUTE_FIRST := 0.56
const EPILOGUE_WRONG_D := 2.25
const EPILOGUE_HER_ENTRY := 2.23
const EPILOGUE_HER_A := 9.05
const EPILOGUE_HER_LAST := 11.56
const EPILOGUE_HER_RELEASE := 12.45
const EPILOGUE_FLUTE_LAST := 11.62
const EPILOGUE_FLUTE_RELEASE := 14.12
const EPILOGUE_END := 15.9


func _cues() -> Array[MusicCue]:
	var found: Array[MusicCue] = []
	for file: String in DirAccess.get_files_at(DIR):
		if file.ends_with(".tres"):
			found.append(load(DIR.path_join(file)) as MusicCue)
	return found

func _streams(cue: MusicCue) -> Array[AudioStream]:
	var found: Array[AudioStream] = []
	if cue.stream is AudioStreamSynchronized:
		var sync := cue.stream as AudioStreamSynchronized
		for i: int in sync.stream_count:
			found.append(sync.get_sync_stream(i))
	else:
		found.append(cue.stream)
	return found

## Seconds one loop lasts: from `loop_offset` to the stream's end, or to its `beat_count` beats when it loops on beats
## (wife_song_full loops before her lost ending).
func _loop_length(ogg: AudioStreamOggVorbis) -> float:
	var end := ogg.beat_count * 60.0 / ogg.bpm if ogg.beat_count > 0 and ogg.bpm > 0.0 else ogg.get_length()
	return end - ogg.loop_offset

func test_every_cue_validates() -> void:
	var cues := _cues()
	assert_int(cues.size()).is_greater_equal(3)
	for cue: MusicCue in cues:
		assert_array(Array(cue.validate())).is_empty()

func test_a_looping_cue_loops_every_stem_at_one_length() -> void:
	for cue: MusicCue in _cues():
		if not cue.loops:
			continue
		var lengths: Array[float] = []
		for stream: AudioStream in _streams(cue):
			var ogg := stream as AudioStreamOggVorbis
			assert_bool(ogg.loop).override_failure_message("%s does not loop" % cue.id).is_true()
			lengths.append(_loop_length(ogg))
		for length: float in lengths:
			assert_float(length).is_equal_approx(lengths[0], 0.01)
		# The loop is a whole number of bars.
		var bars := lengths[0] / BarClock.bar_seconds(cue.bpm, cue.beats_per_bar)
		assert_float(bars).override_failure_message("%s: %f bars" % [cue.id, bars]).is_equal_approx(roundf(bars), 0.01)

## Flashback 1 never reaches her lost ending: the loop closes at its first note, measured at 20.725 s in the render
## (her A after beat 48), and opens at her first note (0.565 s).
func test_her_full_song_loops_before_the_lost_ending() -> void:
	var cue := load("res://resources/music/wife_song_full.tres") as MusicCue
	var ogg := cue.stream as AudioStreamOggVorbis
	assert_bool(ogg.loop).is_true()
	var end := ogg.beat_count * 60.0 / ogg.bpm
	assert_float(end).is_less(20.725)
	assert_float(end).is_greater(20.6)
	assert_float(ogg.loop_offset).is_less(0.565)
	assert_float(end - ogg.loop_offset).is_equal_approx(12.0 * BarClock.bar_seconds(cue.bpm, cue.beats_per_bar), 0.01)

## Flashback 5 never reaches her lost ending either: the loop closes inside her G before the A, measured rising at
## 41.12 s in the render, and opens at her first note (0.53 s); the leaving's cut at 40.7 s lies inside the loop.
func test_her_lullaby_loops_before_the_lost_ending() -> void:
	for path: String in ["res://resources/music/wife_song_lullaby.tres", "res://resources/music/wife_song_lullaby_far.tres"]:
		var cue := load(path) as MusicCue
		var ogg := cue.stream as AudioStreamOggVorbis
		assert_bool(ogg.loop).is_true()
		var end := ogg.beat_count * 60.0 / ogg.bpm
		assert_float(end).is_less(41.12)
		assert_float(end).is_greater(40.7)
		assert_float(ogg.loop_offset).is_less_equal(0.53)
		assert_float(end - ogg.loop_offset).is_equal_approx(12.0 * BarClock.bar_seconds(cue.bpm, cue.beats_per_bar), 0.01)

## The epilogue's piece plays once and rings out (no fade at the scene's end); her voice enters on his wrong D and
## leaves while the flute's last C still sounds, so the last note is his alone.
func test_the_epilogue_plays_once_and_ends_on_the_flute_alone() -> void:
	var cue := load("res://resources/music/wife_song_epilogue.tres") as MusicCue
	assert_bool(cue.loops).is_false()
	assert_float(cue.fade_out).is_equal(0.0)
	var ogg := cue.stream as AudioStreamOggVorbis
	assert_bool(ogg.loop).is_false()
	assert_float(ogg.get_length()).is_equal_approx(EPILOGUE_END, 0.05)
	var order: Array[float] = [EPILOGUE_FLUTE_FIRST, EPILOGUE_HER_ENTRY, EPILOGUE_HER_A, EPILOGUE_HER_LAST,
			EPILOGUE_HER_RELEASE, EPILOGUE_FLUTE_RELEASE, EPILOGUE_END]
	for i: int in range(1, order.size()):
		assert_float(order[i]).is_greater(order[i - 1])
	assert_float(absf(EPILOGUE_WRONG_D - EPILOGUE_HER_ENTRY)).is_less(0.05)
	assert_float(EPILOGUE_FLUTE_LAST).is_less(EPILOGUE_HER_RELEASE)
	# His wrong D is the sketch's beat 4 after the first onset (morning_song beat 0.42 s), within AIVA's humanizing.
	assert_float(EPILOGUE_WRONG_D - EPILOGUE_FLUTE_FIRST).is_equal_approx(4 * 60.0 / cue.bpm, 0.05)

