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
