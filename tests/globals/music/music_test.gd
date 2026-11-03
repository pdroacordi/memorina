class_name MusicTest extends GdUnitTestSuite

## The Music autoload plays the top request, keeps the same cue playing across owners, drops an orphaned request and
## sets stem volumes on its own copy of the stream.


func _tone(seconds: float) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = 8000
	var data := PackedByteArray()
	data.resize(int(8000 * seconds))
	wav.data = data
	return wav

func _cue(id: StringName) -> MusicCue:
	var sync := AudioStreamSynchronized.new()
	sync.stream_count = 2
	sync.set_sync_stream(0, _tone(2.0))
	sync.set_sync_stream(1, _tone(2.0))
	sync.set_sync_stream_volume(1, -30.0)
	var cue := MusicCue.new()
	cue.id = id
	cue.stream = sync
	cue.stems = [&"bed", &"spring"]
	cue.levels = {&"spring": 0.0}
	cue.fade_in = 0.0
	cue.fade_out = 0.0
	return cue

func _holder() -> Node:
	var node: Node = auto_free(Node.new())
	add_child(node)
	return node

func _live_stream() -> AudioStreamSynchronized:
	for player: Node in Music.get_children():
		if (player as AudioStreamPlayer).playing:
			return (player as AudioStreamPlayer).stream as AudioStreamSynchronized
	return null

func after_test() -> void:
	var left := Music.playing()
	while left != null:
		Music.release(left, 0.0)
		left = Music.playing()

func test_the_top_request_plays_and_a_higher_layer_takes_over() -> void:
	var region := Music.request(_cue(&"region"), MusicRequest.Layer.REGION, _holder())
	assert_object(Music.playing()).is_same(region)
	var fight := Music.request(_cue(&"fight"), MusicRequest.Layer.FIGHT, _holder())
	assert_object(Music.playing()).is_same(fight)
	Music.release(fight, 0.0)
	assert_object(Music.playing()).is_same(region)
	Music.release(region, 0.0)
	assert_object(Music.playing()).is_null()

func test_the_same_cue_keeps_playing_for_a_new_owner() -> void:
	var cue := _cue(&"fight")
	var first := Music.request(cue, MusicRequest.Layer.FIGHT, _holder())
	await get_tree().process_frame
	var second := Music.request(cue, MusicRequest.Layer.FIGHT, _holder())
	assert_object(Music.playing()).is_same(second)
	Music.release(first, 0.0)
	assert_object(Music.playing()).is_same(second)

func test_a_request_whose_owner_left_drops_on_the_next_frame() -> void:
	var holder := _holder()
	Music.request(_cue(&"fight"), MusicRequest.Layer.FIGHT, holder)
	remove_child(holder)
	await get_tree().process_frame
	await get_tree().process_frame
	assert_object(Music.playing()).is_null()

func test_a_stem_level_reaches_the_playing_copy_not_the_cue() -> void:
	var cue := _cue(&"fight")
	var request := Music.request(cue, MusicRequest.Layer.FIGHT, _holder())
	await get_tree().process_frame
	await get_tree().process_frame
	var copy := _live_stream()
	assert_object(copy).is_not_null()
	assert_object(copy).is_not_same(cue.stream)
	assert_float(copy.get_sync_stream_volume(1)).is_equal(MusicMix.SILENT_DB)
	Music.set_stem(request, &"spring", 1.0, 0.0)
	await get_tree().process_frame
	await get_tree().process_frame
	assert_float(copy.get_sync_stream_volume(1)).is_equal_approx(0.0, 0.01)
	assert_float((cue.stream as AudioStreamSynchronized).get_sync_stream_volume(1)).is_equal(-30.0)

func _playing_lengths() -> Array[float]:
	var lengths: Array[float] = []
	for player: Node in Music.get_children():
		var deck := player as AudioStreamPlayer
		if deck.playing:
			lengths.append(deck.stream.get_length())
	return lengths

func test_a_displaced_request_still_fades_over_the_release_it_was_given() -> void:
	var fight := _cue(&"fight")
	fight.fade_out = 1.0
	var first := Music.request(fight, MusicRequest.Layer.FIGHT, _holder())
	await get_tree().process_frame
	Music.request(_cue(&"call"), MusicRequest.Layer.FIGHT, _holder())
	Music.release(first, 3.0)
	await get_tree().create_timer(1.5, true, false, true).timeout
	# The cue's own 1 s fade would have stopped it; the 3 s release keeps it sounding.
	assert_int(_playing_lengths().size()).is_equal(2)

func test_a_ringing_one_shot_survives_two_cue_changes() -> void:
	# The previous test's decks stop on the next processed frame.
	await get_tree().process_frame
	await get_tree().process_frame
	var shot := MusicCue.new()
	shot.id = &"restoration"
	shot.stream = _tone(3.0)
	shot.stems = [&"all"]
	shot.loops = false
	shot.fade_in = 0.0
	var ring := Music.request(shot, MusicRequest.Layer.SCENE, _holder())
	await get_tree().process_frame
	Music.release(ring)
	assert_array(_playing_lengths()).contains([3.0])
	Music.request(_cue(&"region_a"), MusicRequest.Layer.REGION, _holder())
	await get_tree().process_frame
	Music.request(_cue(&"region_b"), MusicRequest.Layer.REGION, _holder())
	await get_tree().process_frame
	assert_array(_playing_lengths()).contains([3.0])
