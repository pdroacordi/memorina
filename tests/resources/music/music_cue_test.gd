class_name MusicCueTest extends GdUnitTestSuite

## Every cue in resources/music/ names one stem per stream; a looping cue's stems loop and share one length.

const DIR := "res://resources/music"


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
			assert_bool((stream as AudioStreamOggVorbis).loop).override_failure_message("%s does not loop" % cue.id).is_true()
			lengths.append(stream.get_length())
		for length: float in lengths:
			assert_float(length).is_equal_approx(lengths[0], 0.01)
		# The loop is a whole number of bars.
		var bars := lengths[0] / BarClock.bar_seconds(cue.bpm, cue.beats_per_bar)
		assert_float(bars).override_failure_message("%s: %f bars" % [cue.id, bars]).is_equal_approx(roundf(bars), 0.01)
