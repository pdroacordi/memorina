class_name MusicLogicTest extends GdUnitTestSuite

## MusicRequests picks the top request and drops orphans; MusicMix fades stems and ducks; BarClock finds bar lines.


func _cue(stems: Array[StringName], levels: Dictionary[StringName, float] = {}) -> MusicCue:
	var cue := MusicCue.new()
	cue.stems = stems
	cue.levels = levels
	return cue

func _owner() -> Node:
	return auto_free(Node.new())

func test_the_highest_layer_plays_and_the_newest_wins_a_tie() -> void:
	var requests := MusicRequests.new()
	var holder := _owner()
	add_child(holder)
	var region := requests.add(MusicRequest.new(_cue([]), MusicRequest.Layer.REGION, holder))
	var fight := requests.add(MusicRequest.new(_cue([]), MusicRequest.Layer.FIGHT, holder))
	assert_object(requests.top()).is_same(fight)
	var fight2 := requests.add(MusicRequest.new(_cue([]), MusicRequest.Layer.FIGHT, holder))
	assert_object(requests.top()).is_same(fight2)
	requests.remove(fight2)
	requests.remove(fight)
	assert_object(requests.top()).is_same(region)
	requests.remove(region)
	assert_object(requests.top()).is_null()

func test_a_request_drops_when_its_owner_leaves_the_tree() -> void:
	var requests := MusicRequests.new()
	var holder := _owner()
	add_child(holder)
	requests.add(MusicRequest.new(_cue([]), MusicRequest.Layer.FIGHT, holder))
	assert_bool(requests.prune()).is_false()
	remove_child(holder)
	assert_bool(requests.prune()).is_true()
	assert_int(requests.size()).is_equal(0)

func test_a_stem_fades_to_its_target_on_real_time() -> void:
	var mix := MusicMix.new()
	mix.reset(_cue([&"bed", &"spring"], {&"spring": 0.0}))
	assert_float(mix.level(&"bed")).is_equal(1.0)
	assert_float(mix.stem_db(&"spring")).is_equal(MusicMix.SILENT_DB)
	mix.set_stem(&"spring", 1.0, 4.0)
	mix.step(2.0)
	assert_float(mix.level(&"spring")).is_equal_approx(0.5, 0.001)
	mix.step(3.0)
	assert_float(mix.level(&"spring")).is_equal(1.0)
	mix.set_stem(&"bed", 0.0, 0.0)
	assert_float(mix.level(&"bed")).is_equal(0.0)

func test_the_deepest_duck_wins_and_ducks_do_not_add() -> void:
	var mix := MusicMix.new()
	mix.reset(_cue([&"bed"]))
	mix.duck(&"call", -6.0)
	mix.duck(&"talk", -3.0)
	assert_float(mix.duck_target()).is_equal(-6.0)
	mix.step(1.0)
	assert_float(mix.duck_db()).is_equal(-6.0)
	mix.unduck(&"call")
	mix.step(1.0)
	assert_float(mix.duck_db()).is_equal(-3.0)
	mix.unduck(&"talk")
	mix.step(1.0)
	assert_float(mix.duck_db()).is_equal(0.0)

func test_the_next_bar_line() -> void:
	# 80 BPM, 4/4: a bar is 3 s.
	assert_float(BarClock.bar_seconds(80.0, 4)).is_equal_approx(3.0, 0.0001)
	assert_float(BarClock.next_bar(0.0, 80.0, 4)).is_equal(0.0)
	assert_float(BarClock.next_bar(3.0, 80.0, 4)).is_equal(0.0)
	assert_float(BarClock.next_bar(3.5, 80.0, 4)).is_equal_approx(2.5, 0.0001)
	assert_float(BarClock.next_bar(5.9995, 80.0, 4)).is_equal(0.0)
	# 60 BPM, 4/4: a bar is 4 s.
	assert_float(BarClock.next_bar(1.0, 60.0, 4)).is_equal_approx(3.0, 0.0001)

func test_a_cue_names_one_stem_per_stream() -> void:
	var sync := AudioStreamSynchronized.new()
	sync.stream_count = 2
	var cue := _cue([&"bed", &"lead"])
	cue.stream = sync
	assert_array(Array(cue.validate())).is_empty()
	cue.stems = [&"bed"]
	assert_array(Array(cue.validate())).is_not_empty()
	cue.stems = [&"bed", &"lead"]
	cue.levels = {&"spring": 0.0}
	assert_array(Array(cue.validate())).is_not_empty()
